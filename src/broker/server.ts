import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { join } from "node:path";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";

function env(name: string, fallback?: string): string {
	const value = process.env[name] || fallback;
	if (!value) throw new Error(`${name} is required`);
	return value;
}

function list(name: string): Set<string> {
	return new Set(
		env(name)
			.split(",")
			.map((entry) => entry.trim())
			.filter(Boolean),
	);
}

const config = {
	host: env("BROKER_HOST", "127.0.0.1"),
	inferencePort: Number(env("INFERENCE_PORT", "3460")),
	adminPort: Number(env("ADMIN_PORT", "3461")),
	adminToken: env("ADMIN_TOKEN"),
	dataDir: env("DATA_DIR", "/data"),
	meridianUrl: env("MERIDIAN_URL", "http://meridian:3456"),
	meridianKey: env("MERIDIAN_API_KEY"),
	vercelUrl: env("VERCEL_URL", "https://ai-gateway.vercel.sh"),
	vercelKey: env("VERCEL_API_KEY"),
	claudeModels: list("CLAUDE_MODELS"),
	chatgptModels: list("CHATGPT_MODELS"),
	vercelModels: list("VERCEL_MODELS"),
	maxConcurrency: Number(env("MAX_CONCURRENCY", "6")),
	maxBodyBytes: Number(env("MAX_BODY_BYTES", String(32 * 1024 * 1024))),
	maxTtlSeconds: Number(env("MAX_TTL_SECONDS", String(12 * 60 * 60))),
};

class HttpError extends Error {
	status: number;

	constructor(status: number, message: string) {
		super(message);
		this.status = status;
	}
}

interface Grant {
	hash: string;
	report: string;
	expiresAt: number;
}

interface Route {
	upstream: "meridian" | "vercel";
	method: "GET" | "POST";
	path: string;
	models?: Set<string>;
}

const routes = new Map<string, Route>([
	["POST /claude/v1/messages", { upstream: "meridian", method: "POST", path: "/v1/messages", models: config.claudeModels }],
	["GET /claude/v1/models", { upstream: "meridian", method: "GET", path: "/v1/models" }],
	["POST /chatgpt/v1/responses", { upstream: "meridian", method: "POST", path: "/v1/responses", models: config.chatgptModels }],
	["POST /vercel/v1/messages", { upstream: "vercel", method: "POST", path: "/v1/messages", models: config.vercelModels }],
]);

const forwardedHeaders = ["content-type", "accept", "anthropic-version", "anthropic-beta"];
const sessionHeaders = ["x-session-affinity", "x-opencode-session", "x-session-id", "x-parent-session-id", "session_id", "x-client-request-id"];
const returnedHeaders = ["content-type", "cache-control", "request-id", "x-request-id", "retry-after"];
const meridianSource = /^(fork-side-call|subagent-[A-Za-z0-9._:-]{1,64})$/;
const reportId = /^[A-Za-z0-9-]{1,64}$/;

const grantsPath = join(config.dataDir, "grants.json");
let grants: Grant[] = loadGrants();
const active = new Map<string, number>();

function loadGrants(): Grant[] {
	try {
		return JSON.parse(readFileSync(grantsPath, "utf8")).grants;
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return [];
		throw error;
	}
}

function saveGrants() {
	mkdirSync(config.dataDir, { recursive: true });
	const temporary = `${grantsPath}.tmp`;
	writeFileSync(temporary, JSON.stringify({ grants }), { mode: 0o600 });
	renameSync(temporary, grantsPath);
}

function digest(value: string): Buffer {
	return createHash("sha256").update(value).digest();
}

function liveGrants(): Grant[] {
	const now = Date.now();
	return grants.filter((grant) => grant.expiresAt > now);
}

function grantFor(token: string): Grant | undefined {
	const hash = digest(token).toString("hex");
	return liveGrants().find((grant) => grant.hash === hash);
}

function mint(report: string, ttlSeconds: number) {
	const key = `drh_${randomBytes(32).toString("base64url")}`;
	const expiresAt = Date.now() + ttlSeconds * 1000;
	grants = [...liveGrants().filter((grant) => grant.report !== report), { hash: digest(key).toString("hex"), report, expiresAt }];
	saveGrants();
	return { key, expiresAt };
}

function revoke(report: string) {
	grants = liveGrants().filter((grant) => grant.report !== report);
	saveGrants();
}

function presentedKey(request: IncomingMessage): string | undefined {
	const apiKey = request.headers["x-api-key"];
	if (typeof apiKey === "string" && apiKey) return apiKey;
	const authorization = request.headers.authorization;
	return authorization?.startsWith("Bearer ") ? authorization.slice(7) : undefined;
}

function isObject(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function readBody(request: IncomingMessage): Promise<Buffer> {
	const chunks: Buffer[] = [];
	let size = 0;
	for await (const chunk of request) {
		size += chunk.length;
		if (size > config.maxBodyBytes) throw new HttpError(413, "request body too large");
		chunks.push(chunk);
	}
	return Buffer.concat(chunks);
}

async function readJson(request: IncomingMessage): Promise<Record<string, unknown>> {
	let payload: unknown;
	try {
		payload = JSON.parse((await readBody(request)).toString("utf8"));
	} catch (error) {
		if (error instanceof HttpError) throw error;
		throw new HttpError(400, "request body must be JSON");
	}
	if (!isObject(payload)) throw new HttpError(400, "request body must be a JSON object");
	return payload;
}

function namespaced(report: string, value: string): string {
	return `drh-${report}-${createHash("sha256").update(`${report}\0${value}`).digest("hex").slice(0, 32)}`;
}

function upstreamHeaders(request: IncomingMessage, route: Route, grant: Grant): Record<string, string> {
	const headers: Record<string, string> = {};
	for (const name of forwardedHeaders) {
		const value = request.headers[name];
		if (typeof value === "string") headers[name] = value;
	}
	if (route.upstream === "vercel") {
		headers.authorization = `Bearer ${config.vercelKey}`;
		return headers;
	}
	for (const name of sessionHeaders) {
		const value = request.headers[name];
		if (typeof value === "string" && value.length <= 256) headers[name] = namespaced(grant.report, value);
	}
	const source = request.headers["x-meridian-source"];
	if (typeof source === "string" && meridianSource.test(source)) headers["x-meridian-source"] = source;
	headers["x-meridian-agent"] = "pi";
	headers["x-api-key"] = config.meridianKey;
	return headers;
}

async function upstreamBody(request: IncomingMessage, route: Route): Promise<{ body?: string; model?: string }> {
	if (route.method === "GET") return {};
	const payload = await readJson(request);
	const model = payload.model;
	if (typeof model !== "string" || !route.models?.has(model)) throw new HttpError(403, `model ${String(model)} is not allowed on this route`);
	if (route.upstream === "vercel") {
		payload.providerOptions = { gateway: { disallowPromptTraining: true, inferenceRegion: { scope: "zone", geoRegion: "us" } } };
	}
	return { body: JSON.stringify(payload), model };
}

function upstreamUrl(route: Route, requestUrl: URL): string {
	const base = route.upstream === "meridian" ? config.meridianUrl : config.vercelUrl;
	const query = requestUrl.searchParams.get("beta") === "true" ? "?beta=true" : "";
	return `${base}${route.path}${query}`;
}

async function proxy(request: IncomingMessage, response: ServerResponse, route: Route, grant: Grant, requestUrl: URL) {
	const started = Date.now();
	const { body, model } = await upstreamBody(request, route);
	const abort = new AbortController();
	response.on("close", () => {
		if (!response.writableFinished) abort.abort();
	});
	const upstream = await fetch(upstreamUrl(route, requestUrl), {
		method: route.method,
		headers: upstreamHeaders(request, route, grant),
		body,
		signal: abort.signal,
	});
	const headers: Record<string, string> = {};
	for (const name of returnedHeaders) {
		const value = upstream.headers.get(name);
		if (value) headers[name] = value;
	}
	response.writeHead(upstream.status, headers);
	if (upstream.body) await pipeline(Readable.fromWeb(upstream.body), response);
	else response.end();
	log({ report: grant.report, route: `${route.method} ${requestUrl.pathname}`, model, status: upstream.status, ms: Date.now() - started });
}

async function handleInference(request: IncomingMessage, response: ServerResponse) {
	const requestUrl = new URL(request.url ?? "/", "http://broker");
	const route = routes.get(`${request.method} ${requestUrl.pathname}`);
	if (!route) throw new HttpError(404, "not found");
	const key = presentedKey(request);
	const grant = key ? grantFor(key) : undefined;
	if (!grant) throw new HttpError(401, "invalid or expired key");
	const running = active.get(grant.report) ?? 0;
	if (running >= config.maxConcurrency) throw new HttpError(429, "too many concurrent requests for this report");
	active.set(grant.report, running + 1);
	try {
		await proxy(request, response, route, grant, requestUrl);
	} finally {
		const remaining = (active.get(grant.report) ?? 1) - 1;
		if (remaining > 0) active.set(grant.report, remaining);
		else active.delete(grant.report);
	}
}

function isAdmin(request: IncomingMessage): boolean {
	const key = presentedKey(request);
	return key !== undefined && timingSafeEqual(digest(key), digest(config.adminToken));
}

function sendJson(response: ServerResponse, status: number, payload: unknown) {
	response.writeHead(status, { "content-type": "application/json" });
	response.end(JSON.stringify(payload));
}

async function handleAdmin(request: IncomingMessage, response: ServerResponse) {
	if (!isAdmin(request)) throw new HttpError(401, "invalid admin token");
	const { pathname } = new URL(request.url ?? "/", "http://broker");
	if (request.method === "GET" && pathname === "/grants") {
		sendJson(response, 200, liveGrants().map(({ report, expiresAt }) => ({ report, expiresAt })));
		return;
	}
	if (request.method === "POST" && pathname === "/grants") {
		const payload = await readJson(request);
		const report = payload.report;
		const ttlSeconds = payload.ttlSeconds ?? config.maxTtlSeconds;
		if (typeof report !== "string" || !reportId.test(report)) throw new HttpError(400, "report must match [A-Za-z0-9-]{1,64}");
		if (typeof ttlSeconds !== "number" || ttlSeconds <= 0 || ttlSeconds > config.maxTtlSeconds) {
			throw new HttpError(400, `ttlSeconds must be between 1 and ${config.maxTtlSeconds}`);
		}
		const grant = mint(report, ttlSeconds);
		log({ admin: "mint", report, expiresAt: grant.expiresAt });
		sendJson(response, 201, { report, ...grant });
		return;
	}
	const revoked = pathname.match(/^\/grants\/([A-Za-z0-9-]{1,64})$/);
	if (request.method === "DELETE" && revoked) {
		revoke(revoked[1]);
		log({ admin: "revoke", report: revoked[1] });
		response.writeHead(204).end();
		return;
	}
	throw new HttpError(404, "not found");
}

function log(entry: Record<string, unknown>) {
	console.log(JSON.stringify({ at: new Date().toISOString(), ...entry }));
}

function serve(port: number, handler: (request: IncomingMessage, response: ServerResponse) => Promise<void>) {
	createServer((request, response) => {
		handler(request, response).catch((error) => {
			const status = error instanceof HttpError ? error.status : 502;
			if (!(error instanceof HttpError)) log({ error: String(error) });
			if (response.headersSent) response.destroy();
			else sendJson(response, status, { error: error instanceof HttpError ? error.message : "upstream request failed" });
		});
	}).listen(port, config.host, () => log({ listening: `${config.host}:${port}` }));
}

serve(config.inferencePort, handleInference);
serve(config.adminPort, handleAdmin);
