import type { WorkflowDefinition } from "./contract.ts";

// Gravity Machine points an attacker image at the configured target and hunts for
// canaries until its inference budget or deadline runs out. It takes no report.
// Triage proves one claim; Gravity Machine looks for any. Both share the target,
// findings format, verify run, and handoff. Scheduling repeated runs is the
// operator's choice and outside dr-hands; each run's deadline and budget bound it.
// All guests have root and may cooperate maliciously. Images implement stable
// interfaces; they do not supply local lifecycle scripts. The reference pair is
// pinned, source-built ARTEX (external AGPL workload) and a pinned RubyGems.org
// revision with Rails, PostgreSQL, Memcached, OpenSearch, and synthetic seed data.
// Neither the public RubyGems.org service nor production data is a target. Its
// canaries belong to this fixture, not to upstream RubyGems.org.
//
// AWS boundary: a dedicated VPC, separate EC2 instances/private subnets, no target
// default route, and attacker egress through Network Firewall before NAT. DNS
// Firewall and TLS inspection admit the exact configured OpenRouter destination.
// Deny direct-IP bypass, alternate DNS, forged SNI/Host, redirect escapes, CDN
// neighbors, arbitrary CONNECT, and other protocols. Policies live outside guests.
// Operator SSH enters only the attacker via EC2 Instance Connect Endpoint. The
// target accepts its configured entry ports, returns only declared callback
// traffic, and reaches the run's callback sink.
// No tailnet membership, attacker web UI, shared guest-writable storage, runtime
// package/registry access, custom inference broker, or guest-enforced boundary.
// Images contain dependencies; no host mounts or reusable credentials enter them.
//
// Acceptance claims (IDs match formal/README.md and archived behavior scenarios):
// G1: The attacker captures a configured canary, and a verify run that never saw
// the attacker reproduces the capture; a disconnected run does not pass. G2: Guest
// root cannot widen authority by replacing routes, DNS, proxies, firewalls,
// containers, or framework settings. G3: Only operator-to-attacker management,
// declared role connections, target-to-sink callbacks, and filtered attacker-to-
// inference paths are allowed. G4: The service enforces allowed models, no hosted
// tools, zero retention, hard budget, and expiry. Zero retention does not prevent
// disclosure. G5: Reference target data is synthetic; no guest gets operator,
// production, cloud, registry, or source credentials. The attacker's only
// credential is bounded run inference authority. G6: Status is control-plane data;
// exports use fixed filenames and remain hostile evidence. Only schema-valid
// findings reach a handoff prompt, and prose never does. G7: Inference and
// management authority expire by the deadline (at most twelve hours), even with
// delayed deletion; retries cannot revive them. G8: Removal requires external
// absence observations for every runtime resource and capability. Partial failures
// follow the same removal path; one run cannot remove another. Exports and
// non-secret controller metadata survive.
//
// Model assumptions:
// A1: Both guests are compromised from the start. A2: Images, dependencies, tools,
// models, state, and outputs may be malicious. A3: The workstation, credentials,
// and OpenSSH client are initially trusted. A4: AWS IAM, EC2, VPC, Instance Connect,
// DNS Firewall, and Network Firewall enforce their policies. A5: OpenRouter
// enforces budget, model/tool policy, expiry, and revocation. A6: AWS/SSH/TLS and
// OpenRouter cryptography hold. A7: The reference target has only synthetic data
// and fake credentials; inference disclosure is expected. A8: Exports stay opaque.
// A9: Eventual deletion needs providers to make progress and a controller to return;
// authority expiry does not. A10: Guest availability and useful results are not
// guaranteed. Misclassification and provider bugs remain real risks.
//
// Model invariants:
// I1: No valuable guest authority. I2: No unmediated external path. I3: Only declared
// service/callback ports and filtered inference. I4: No cross-run communication.
// I5: Management is operator-initiated. I6: Inference is bounded. I7: Guest policy
// cannot enlarge access. I8: Expired inference/management authority is unusable.
// I9: Revocation is monotonic. I10: Removal needs observed absence, not delete
// success. I11: Partial provisioning cannot activate and proceeds to removal.
// I12: All operations use the original immutable Run ID and generation. I13: The
// controller's export record is monotonic; evidence bytes are still hostile.
// I14: Hostile output is not printed, interpreted as paths, extracted, or rendered;
// handoff reads only schema-valid finding fields checked against the operator tree.
//
// The bounded models name the workstation/OpenSSH, AWS, and OpenRouter as trusted
// principals. They model one attacker and one target per chamber; the sink, a
// front proxy, and verify runs are outside them. A design that adds a trusted
// principal falls outside this reference contract. The models omit controller and
// backend implementation internals, which still require review. They do not prove provider correctness, arbitrary scopes, policy
// compilation, image classification, or infrastructure conformance. Alloy checks
// allowed paths and known-bad architectures; TLA+ separates deletion requests from
// observed absence and checks delayed operations, expiry, and recovery. Its model
// orders confirmed revocation before deletion; the runtime contract additionally
// attempts resource deletion after a revocation error without claiming removal.
// Real-service checks must cover that difference and every guest-writable surface.
// See formal/README.md for the G1-G8 traceability map and archived scenarios.
export default {
  name: "gravity-machine",
  parameters: {
    attacker_image: { kind: "image", required: true },
    attacker_sensitivity: { kind: "sensitivity", required: false, default: "private" },
    target: { kind: "target", required: true },
    callback_ports: { kind: "ports", required: true },
  },
  roles: {
    attacker: { interface: "attacker", imageParameter: "attacker_image", sensitivityParameter: "attacker_sensitivity" },
    target: { interface: "target", targetParameter: "target", clients: ["attacker"] },
    sink: { interface: "sink" },
  },
  inputs: [],
  network: "inference-only",
  connections: [
    { from: "target", to: "attacker", portsParameter: "callback_ports" },
  ],
  inferenceRoles: ["attacker"],
  outputs: [
    { role: "attacker", path: "/run/dr-hands/outputs/findings.json", name: "findings.json", format: "findings" },
    { role: "attacker", path: "/run/dr-hands/outputs/VERDICT.md", name: "verdict.md", format: "prose" },
  ],
  cleanup: "owned-resources",
} satisfies WorkflowDefinition;
