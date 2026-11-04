import assert from "node:assert/strict";
import { readdir, readFile, stat } from "node:fs/promises";
import { dirname, resolve, relative } from "node:path";
import triage from "../workflows/triage.ts";
import gravity from "../workflows/gravity.ts";
import type { WorkflowDefinition } from "../workflows/contract.ts";

const root = resolve(import.meta.dir, "..");
async function files(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { withFileTypes: true });
  const results: string[] = [];
  for (const entry of entries) {
    if ([".git", "node_modules", "tmp"].includes(entry.name)) continue;
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) results.push(...await files(path));
    else if (entry.isFile()) results.push(path);
  }
  return results;
}
for (const path of await files(root)) {
  if (!path.endsWith(".md")) continue;
  const text = await readFile(path, "utf8");
  const local = relative(root, path);
  if (local === "SECURITY.md" || local.startsWith("security/")) {
    assert(Buffer.byteLength(text) <= 4096, `${local} exceeds 4 KiB`);
  }
  for (const match of text.matchAll(/\]\(([^\s)]+)\)/g)) {
    const target = match[1];
    if (target.includes("://") || target.startsWith("#")) continue;
    await stat(resolve(dirname(path), target.split("#")[0]));
  }
}
for (const filename of ["config.example.toml", "fnox.example.toml", "mise.toml"]) {
  Bun.TOML.parse(await readFile(resolve(root, filename), "utf8"));
}
for (const workflow of [triage, gravity] satisfies WorkflowDefinition[]) {
  const definition: WorkflowDefinition = workflow;
  assert.equal(definition.cleanup, "owned-resources");
  for (const role of Object.values(definition.roles)) {
    assert.equal(definition.parameters[role.imageParameter]?.kind, "image");
    assert.equal(definition.parameters[role.sensitivityParameter]?.kind, "sensitivity");
  }
  for (const input of definition.inputs) {
    assert.equal(definition.parameters[input.parameter]?.kind, input.kind);
    assert.equal(definition.parameters[input.sensitivityParameter]?.kind, "sensitivity");
    assert(input.role in definition.roles);
  }
  for (const connection of definition.connections) {
    assert(connection.from in definition.roles && connection.to in definition.roles);
    assert.equal(definition.parameters[connection.portsParameter]?.kind, "ports");
  }
  for (const role of definition.inferenceRoles) assert(role in definition.roles);
  for (const output of definition.outputs) assert(output.role in definition.roles);
  if (typeof definition.network !== "string") {
    assert.equal(definition.parameters[definition.network.parameter]?.kind, "network");
  }
}
console.log("Specification links, security file bounds, TOML, and bundled workflow references passed.");
