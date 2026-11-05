import assert from "node:assert/strict";
import { cp, mkdtemp, readdir, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve, dirname } from "node:path";
import schema from "../schemas/report.schema.json";

const root = resolve(import.meta.dir, "..");
const work = await mkdtemp(resolve(tmpdir(), "dr-hands-cli-"));
const env = { PATH: `${dirname(process.execPath)}:/usr/bin:/bin`, HOME: work, BUN_RUNTIME_TRANSPILER_CACHE_PATH: "0" };
let checks = 0;
function invoke(args: string[], expected: number) {
  const result = Bun.spawnSync([resolve(root, "bin/dr-hands"), ...args], {
    cwd: work, env, stdout: "pipe", stderr: "pipe", timeout: 10_000,
  });
  const output = result.stdout.toString() + result.stderr.toString();
  assert.equal(result.exitCode, expected, `${args.join(" ")}: ${output}`);
  assert(!output.includes("\x1b"));
  assert(!output.includes("MUST_NOT_APPEAR"));
  checks++;
  return output;
}
try {
  invoke(["--help"], 0);
  invoke(["help"], 0);
  for (const command of ["init", "lint", "doctor", "dry-run", "provision", "run", "status", "resume", "remove", "export", "verify", "handoff"]) {
    invoke([command, "--help"], 0);
    invoke(["help", command], 0);
    assert(invoke([command, "example"], 3).includes("no action performed"));
  }
  invoke(["run", "--prepared", "run-example"], 3);
  invoke(["--config", "config.toml", "run", "triage"], 3);
  for (const args of [["unknown"], ["lifecycle"], ["help", "../../outside"], ["--config"], ["--config", "", "run"], ["--help", "extra"]]) invoke(args, 2);
  assert.deepEqual(await readdir(work), []);
  invoke(["lint-report", "--help"], 0);
  invoke(["lint-report"], 2);
  invoke(["lint-report", "absent.json"], 2);
  invoke(["lint-report", work], 2);
  invoke(["--config", "config.toml", "lint-report", "report.json"], 2);
  const valid = { version: 1, title: "Example", body: "Hostile text remains data." };
  const encode = (value: unknown) => Buffer.from(JSON.stringify(value));
  const fixtures: [Uint8Array, number][] = [
    [encode(valid), 0],
    ...schema.examples.map((example): [Uint8Array, number] => [encode(example), 0]),
    [encode({ ...valid, body: "\u001b]52;c;MUST_NOT_APPEAR\u0007" }), 0],
    [encode({ ...valid, comments: Array.from({ length: 1000 }, () => ({ body: "x" })) }), 0],
    [encode({ ...valid, comments: Array.from({ length: 1001 }, () => ({ body: "x" })) }), 1],
    [encode({ ...valid, version: true }), 1],
    [encode({ ...valid, version: 2 }), 1],
    [encode({ ...valid, title: "" }), 1],
    [encode({ ...valid, body: ["not text"] }), 1],
    [encode({ ...valid, source: { name: "github" } }), 1],
    [encode({ ...valid, "MUST_NOT_APPEAR\u001b": "secret" }), 1],
    [Buffer.from('{"version":1,"title":"a","title":"b","body":"x"}'), 1],
    [Buffer.from('{"version":1,"title":"a","\\u0074itle":"b","body":"x"}'), 1],
    [Buffer.from('{"version":1,"title":"a","body":"x","source":{"name":"a","name":"b","reference":"x"}}'), 1],
    [Buffer.from('{"version":NaN,"title":"a","body":"x"}'), 1],
    [Buffer.from('{"version":Infinity,"title":"a","body":"x"}'), 1],
    [Buffer.from('{"version":1,"title":"a","body":"x",}'), 1],
    [Buffer.from('/* comment */ {"version":1,"title":"a","body":"x"}'), 1],
    [Buffer.from([0xff]), 1],
    [Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), encode(valid)]), 1],
    [Buffer.from("{}"), 1], [Buffer.from("null"), 1], [Buffer.from("[]"), 1], [Buffer.from(""), 1],
    [Buffer.from("[".repeat(3000) + "]".repeat(3000)), 1],
  ];
  const overhead = encode({ ...valid, body: "" }).length;
  const exact = encode({ ...valid, body: "a".repeat(1024 * 1024 - overhead) });
  assert.equal(exact.length, 1024 * 1024);
  fixtures.push([exact, 0], [Buffer.concat([exact, Buffer.from(" ")]), 1]);
  for (const [index, [bytes, status]] of fixtures.entries()) {
    const path = resolve(work, `case-${index}.json`);
    await writeFile(path, bytes);
    invoke(["lint-report", path], status);
  }
  assert.equal((await readdir(work)).length, fixtures.length);
  await writeFile(resolve(work, "node"), "#!/bin/sh\nprintf 'Unexpected system Node invocation\\n' >&2\nexit 93\n", { mode: 0o755 });
  const lint = Bun.spawnSync([process.execPath, "run", "lint"], {
    cwd: root, env: { ...env, PATH: `${work}:${env.PATH}` },
    stdout: "pipe", stderr: "pipe", timeout: 30_000,
  });
  assert.equal(lint.exitCode, 0, lint.stdout.toString() + lint.stderr.toString());
  assert(!lint.stderr.toString().includes("Unexpected system Node invocation"));
  checks++;
  const cold = resolve(work, "cold");
  for (const path of ["bin", "cli", "lib", "schemas", "package.json", "bun.lock", "tsconfig.json"]) {
    await cp(resolve(root, path), resolve(cold, path), { recursive: true });
  }
  let registryRequests = 0;
  const registry = Bun.serve({
    hostname: "127.0.0.1", port: 0,
    fetch() { registryRequests++; return new Response("Unavailable", { status: 404 }); },
  });
  try {
    await writeFile(resolve(cold, "bunfig.toml"), `[install]\nregistry = "${registry.url}"\n`);
    for (const [args, expected] of [
      [["--help"], 0], [["run", "triage"], 3], [["lint-report", resolve(work, "case-0.json")], 1],
    ] satisfies [string[], number][]) {
      const child = Bun.spawn([resolve(cold, "bin/dr-hands"), ...args], {
        cwd: cold, env: { ...env, BUN_INSTALL_CACHE_DIR: resolve(work, "empty-cache") },
        stdout: "pipe", stderr: "pipe", timeout: 10_000,
      });
      const [code, stdout, stderr] = await Promise.all([
        child.exited, new Response(child.stdout).text(), new Response(child.stderr).text(),
      ]);
      assert.equal(code, expected, stdout + stderr);
      assert.equal(registryRequests, 0, "CLI attempted dependency installation");
      checks++;
    }
  } finally {
    registry.stop(true);
  }
  console.log(`Passed ${checks} CLI system checks with an isolated environment and no stub filesystem effects.`);
} finally {
  await rm(work, { recursive: true, force: true });
}
