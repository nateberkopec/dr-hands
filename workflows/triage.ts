import type { WorkflowDefinition } from "./contract.ts";

// The operator selects this trusted definition, not a command named in a report.
// It describes inputs and relationships; an executor compiles and validates the
// plan before obtaining approval. No definition invokes dr-hands as a subprocess.
// Triage proves or refutes one report's claim against the configured target.
// The agent writes findings.json, a typed claim with an HTTP transcript and the
// canaries it captured, and VERDICT.md, prose for the operator only. Neither a
// test nor a fix leaves the run. See security/handoff.md and security/canaries.md.
// Private analysis is the default. Public browsing uses a fresh run of this same
// workflow with explicitly public images/inputs and public-http permission.
// Never move private or derived private data into the browsing run. A sensitive
// URL is private data too. Public browsing output remains hostile when imported
// into private analysis. Source snapshots must reject links escaping their root.
// The agent image owns its guest processes. Boot can execute them before input
// delivery; isolation must already hold. Package downloads need permitted web
// access; restricted runs must have their dependencies baked into the image.
// See security/data-flow.md and cli/help/run.txt for the mandatory run contract.
export default {
  name: "triage",
  parameters: {
    agent_image: { kind: "image", required: true },
    agent_sensitivity: { kind: "sensitivity", required: false, default: "private" },
    target: { kind: "target", required: true },
    report: { kind: "report", required: true },
    report_sensitivity: { kind: "sensitivity", required: false, default: "private" },
    source: { kind: "source-tree", required: false },
    source_sensitivity: { kind: "sensitivity", required: false, default: "private" },
    network: { kind: "network", required: false, default: "inference-only" },
  },
  roles: {
    agent: { interface: "agent", imageParameter: "agent_image", sensitivityParameter: "agent_sensitivity" },
    target: { interface: "target", targetParameter: "target", clients: ["agent"] },
    sink: { interface: "sink" },
  },
  inputs: [
    { parameter: "report", kind: "report", sensitivityParameter: "report_sensitivity", role: "agent", destination: "/run/dr-hands/inputs/report.json" },
    { parameter: "source", kind: "source-tree", sensitivityParameter: "source_sensitivity", role: "agent", destination: "/run/dr-hands/inputs/source" },
  ],
  network: { parameter: "network" },
  connections: [],
  inferenceRoles: ["agent"],
  outputs: [
    { role: "agent", path: "/root/work/findings.json", name: "findings.json", format: "findings" },
    { role: "agent", path: "/root/work/VERDICT.md", name: "verdict.md", format: "prose" },
  ],
  cleanup: "owned-resources",
} satisfies WorkflowDefinition;
