import type { WorkflowDefinition } from "./contract.ts";

// The operator starts verify with `dr-hands verify RUN_ID FINDING`. The controller
// takes the target and its frozen image identities from RUN_ID's plan, or from a
// named configured target to check a fix, and one exported finding, which stays
// hostile input and keeps RUN_ID's sensitivity. No agent and no inference run
// here, so "verified" never depends on a model or on text the reporter wrote.
// The target seeds fresh credentials and canary values, so a transcript that
// carries values or credentials from the source run captures nothing. The dr-hands
// replayer receives the credentials and canary values, sends the transcript as the
// named identities, reads the sink's hits, and reports which canaries were
// captured. It minimizes the transcript when the target can reset to its seed.
// Side effects are integrity-check results, sink hits, availability, and the
// controller's boundary observations of outbound traffic. That is what the
// boundary and the declared checks can see, not a full diff of target state.
// The replayer and sink are dr-hands images but still guests. A target compromised
// by the transcript can attack them and forge what they report. Verification is
// strong evidence, not proof. See security/canaries.md and security/handoff.md.
export default {
  name: "verify",
  parameters: {
    target: { kind: "target", required: true },
    finding: { kind: "finding", required: true },
    finding_sensitivity: { kind: "sensitivity", required: false, default: "private" },
  },
  roles: {
    replayer: { interface: "replayer" },
    target: { interface: "target", targetParameter: "target", clients: ["replayer"] },
    sink: { interface: "sink" },
  },
  inputs: [
    { parameter: "finding", kind: "finding", sensitivityParameter: "finding_sensitivity", role: "replayer", destination: "/run/dr-hands/inputs/finding.json" },
  ],
  network: "isolated",
  connections: [],
  inferenceRoles: [],
  outputs: [
    { role: "replayer", path: "/run/dr-hands/outputs/verification.json", name: "verification.json", format: "verification" },
  ],
  cleanup: "owned-resources",
} satisfies WorkflowDefinition;
