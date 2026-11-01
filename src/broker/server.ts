import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { join } from "node:path";
import { Readable, Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import { StringDecoder } from "node:string_decoder";

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
	maxBodyBytes: Number(env("MAX_BODY_BYTES", String(8 * 1024 * 1024))),
	maxTokens: Number(env("MAX_TOKENS_PER_GRANT", String(20_000_000))),
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
	tokens: number;
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
const vercelFields = new Set(["model", "messages", "system", "tools", "tool_choice", "max_tokens", "temperature", "top_p", "top_k", "stop_sequences", "stream", "thinking", "output_config"]);
const reportId = /^[A-Za-z0-9-]{1,64}$/;

const grantsPath = join(config.dataDir, "grants.json");
let grants: Grant[] = loadGrants();
const active = new Map<string, number>();

function loadGrants(): Grant[] {
	try {
		const now = Date.now();
		return (JSON.parse(readFileSync(grantsPath, "utf8")).grants as Grant[]).filter((grant) => grant.expiresAt > now);
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
	grants = [...liveGrants().filter((grant) => grant.report !== report), { hash: digest(key).toString("hex"), report, expiresAt, tokens: 0 }];
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
		if (value === undefined) continue;
		if (typeof value !== "string" || value.length > 256) throw new HttpError(400, `${name} must be one value of at most 256 characters`);
		headers[name] = namespaced(grant.report, value);
	}
	headers["x-session-affinity"] ??= namespaced(grant.report, "");
	const source = request.headers["x-meridian-source"];
	if (typeof source === "string" && meridianSource.test(source)) headers["x-meridian-source"] = source;
	headers["x-meridian-agent"] = "pi";
	headers["x-api-key"] = config.meridianKey;
	return headers;
}

async function upstreamBody(request: IncomingMessage, route: Route, grant: Grant): Promise<{ body?: string; model?: string }> {
	if (route.method === "GET") return {};
	let payload = await readJson(request);
	const model = payload.model;
	if (typeof model !== "string" || !route.models?.has(model)) throw new HttpError(403, `model ${String(model)} is not allowed on this route`);
	if (route.upstream === "vercel") {
		payload = Object.fromEntries(Object.entries(payload).filter(([field]) => vercelFields.has(field)));
		payload.providerOptions = { gateway: { disallowPromptTraining: true, inferenceRegion: { scope: "zone", geoRegion: "us" } } };
	} else {
		delete payload.metadata;
		delete payload.fallbacks;
		delete payload.client_metadata;
		delete payload.previous_response_id;
		if (typeof payload.prompt_cache_key === "string") payload.prompt_cache_key = namespaced(grant.report, payload.prompt_cache_key);
	}
	return { body: JSON.stringify(payload), model };
}

const usageFields = ["input_tokens", "output_tokens", "cache_creation_input_tokens"];

function usageOf(event: unknown): Record<string, unknown> | undefined {
	if (!isObject(event)) return undefined;
	for (const holder of [event, event.message, event.response]) {
		if (isObject(holder) && isObject(holder.usage)) return holder.usage;
	}
	return undefined;
}

function meter(): { stream: Transform; tokens: () => number } {
	const usage: Record<string, number> = {};
	const decoder = new StringDecoder("utf8");
	let pending = "";
	let whole = "";
	const consume = (text: string) => {
		let event: unknown;
		try {
			event = JSON.parse(text);
		} catch {
			return;
		}
		const found = usageOf(event);
		if (!found) return;
		for (const field of usageFields) {
			const value = found[field];
			if (typeof value === "number") usage[field] = value;
		}
	};
	const consumeLine = (line: string) => {
		if (line.startsWith("data:") && line.includes("usage")) consume(line.slice(5).trim());
	};
	const stream = new Transform({
		transform(chunk: Buffer, _encoding, callback) {
			const text = decoder.write(chunk);
			if (whole.length <= config.maxBodyBytes) whole += text;
			pending += text;
			const lines = pending.split("\n");
			pending = lines.pop() ?? "";
			lines.forEach(consumeLine);
			callback(null, chunk);
		},
		flush(callback) {
			const tail = decoder.end();
			pending += tail;
			whole += tail;
			consumeLine(pending);
			if (Object.keys(usage).length === 0 && whole.length <= config.maxBodyBytes) consume(whole);
			pending = "";
			whole = "";
			callback();
		},
	});
	return { stream, tokens: () => Object.values(usage).reduce((sum, value) => sum + value, 0) };
}

function upstreamUrl(route: Route, requestUrl: URL): string {
	const base = route.upstream === "meridian" ? config.meridianUrl : config.vercelUrl;
	const query = requestUrl.searchParams.get("beta") === "true" ? "?beta=true" : "";
	return `${base}${route.path}${query}`;
}

async function proxy(request: IncomingMessage, response: ServerResponse, route: Route, grant: Grant, requestUrl: URL, entry: Record<string, unknown>) {
	const { body, model } = await upstreamBody(request, route, grant);
	entry.model = model;
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
	entry.status = upstream.status;
	if (!upstream.body) {
		response.end();
		return;
	}
	const usage = meter();
	try {
		await pipeline(Readable.fromWeb(upstream.body), usage.stream, response);
	} finally {
		entry.tokens = usage.tokens();
		grant.tokens = (grant.tokens ?? 0) + usage.tokens();
		saveGrants();
	}
}

async function handleInference(request: IncomingMessage, response: ServerResponse) {
	const key = presentedKey(request);
	const grant = key ? grantFor(key) : undefined;
	if (!grant) throw new HttpError(401, "invalid or expired key");
	const requestUrl = new URL(request.url ?? "/", "http://broker");
	const route = routes.get(`${request.method} ${requestUrl.pathname}`);
	if (!route) throw new HttpError(404, "not found");
	if ((grant.tokens ?? 0) >= config.maxTokens) throw new HttpError(429, "this report has used its token allowance");
	const running = active.get(grant.report) ?? 0;
	if (running >= config.maxConcurrency) throw new HttpError(429, "too many concurrent requests for this report");
	active.set(grant.report, running + 1);
	const started = Date.now();
	const entry: Record<string, unknown> = { report: grant.report, route: `${route.method} ${requestUrl.pathname}` };
	try {
		await proxy(request, response, route, grant, requestUrl, entry);
	} catch (error) {
		entry.error = error instanceof HttpError ? error.status : String(error);
		throw error;
	} finally {
		log({ ...entry, ms: Date.now() - started, used: grant.tokens ?? 0 });
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
		sendJson(response, 200, liveGrants().map(({ report, expiresAt, tokens }) => ({ report, expiresAt, tokens: tokens ?? 0 })));
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
