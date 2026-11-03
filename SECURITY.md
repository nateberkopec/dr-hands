# Security

dr-hands specifies disposable runs for hostile investigations and experiments. Triage and gravity are declarative workflows in the same tool, not separate security engines. This page describes intended boundaries, not guarantees established by an implementation in this repository.

## Report a problem

Report security problems in dr-hands privately through [GitHub's private vulnerability reporting](https://github.com/nateberkopec/dr-hands/security/advisories/new). Don't open a public issue.

## What we assume

Every report is hostile, regardless of its source. Its author may control:

- the report text and comments, including hidden text aimed at AI;
- URLs, proof-of-concept snippets, model files, and packages encountered inside the run;
- descriptive source metadata and guest-produced findings;
- the agent itself, through prompt injection.

Report intake accepts only the [structured JSON text contract](docs/reports.md). Exporters and their credentials are outside scope. The local tool validates structure and bounds without rendering content, executing code, importing attachments, or following links. Text is data at this boundary, not trusted content; parsers and terminal handling still need care.

The operator selects declarative workflows, targets, and immutable images independently of the report. A manifest and input digests identify what enters a run; they do not establish that it is benign.

We assume the agent has root from the start. The report is infected, and the target is infected too: the agent may compromise it at any time. Guest root is an initial condition, not an escape.

The report is not the secret. Its author already has it. We protect:

- your laptop, its keys, and your logins
- operator credentials, including credentials for report sources that dr-hands never receives
- your home network and tailnet
- your money and AI quota

We cannot ensure the operator's cognitive security. Reports, agent output, and evidence can manipulate the person reading them, including through meme injection. Technical containment does not protect human judgment.

## How dr-hands protects you

**One isolated boundary per run.** Each workflow's roles and guest-writable resources belong to one disposable run. No role gets operator, production, cloud, report-source, or inference-administration credentials. Management is operator-initiated. Guest root does not confer access to the workstation, private networks, other runs, or provider metadata/control-plane endpoints.

**Network policy outside the guest.** Triage permits public HTTP(S) so the agent can follow hostile links. Gravity permits only declared role connections and bounded inference. A provider must enforce the selected policy outside the guest, including actual destination addresses, redirects, IPv6, and DNS rebinding. It must reject a policy it cannot enforce. See [Workflows](docs/workflows.md#mandatory-boundaries).

**Bounded inference, not a broker.** A role may hold its own expiring OpenRouter credential under a hard run budget and model allowlist. It never holds an administration key. Hosted tools are disabled and zero data retention is required. These are required service capabilities, not facts established merely by successful authentication.

**Inventory before execution.** Input snapshots, workflow declarations, immutable image identities, and the guest-writable resource inventory define the run. There is no shared persistent storage that a guest may infect outside that inventory.

**Opaque output and explicit export.** Guest-produced evidence crosses into fixed local filenames only through explicit export. It is never automatically rendered, executed, extracted, or treated as a local path. It remains hostile even after removal. Reviewing and applying a patch is a separate operator action.

**Externally enforced expiry and observed removal.** Run authority expires after the configured lifetime, at most twelve hours, independently of guest cooperation. Removal revokes authority, destroys every guest-writable runtime resource, and confirms absence through external services. Partial provisioning follows the same path. Trusted control-plane metadata and explicitly exported hostile evidence may survive; public-web requests and remote copies cannot be recalled.

## Why not a local VM

A local VM or container runs on the machine that holds your keys. If it escapes that boundary, it can reach the host. A cloud run places that boundary away from the workstation. This does not make a cloud escape impossible or harmless; the provider isolation boundary remains an explicit assumption.

## Escape goal and limits

The ambition is that escape requires a CVSS 9+ zero-day in a mature upstream boundary, with as few such assumptions as possible. The concrete requirement is no path beyond the declared authority without breaking a named upstream boundary. The score and novelty of a future vulnerability cannot be guaranteed. Misconfiguration, credential mistakes, and chains of less severe flaws must not be dismissed by this slogan.

Executing a malicious model, package, or serialized payload inside a guest is in scope and already covered by the root-compromise assumption. Reaching another tenant, provider host, credentials, or management service is an escape and must cross the declared upstream boundary. This states the threat class raised by the HuggingFace-style escape question; it does not claim to analyze or prevent any particular incident.

Public-web triage deliberately permits communication beyond the disposable run. Disclosing report contents or sending hostile public HTTP(S) requests is an accepted risk of that workflow, not an upstream-boundary failure. Gravity does not permit those paths.

## Gravity machine

[GRAVITY.md](GRAVITY.md) is the short contract. This section is its second acceptance layer: the assumptions, invariants, architecture, and limits behind the eight top-level claims. The [Gherkin scenarios](https://github.com/nateberkopec/dr-hands/blob/archive/design-stack-before-spec-only/features/gravity.feature) and [formal models](formal/README.md) carry the same IDs into deeper layers.

### What we assume

**A1 — Total guest compromise.** The attacker has root on both machines in a chamber and can coordinate them. Guest root and an infected target exist before any property below is evaluated.

**A2 — Hostile software and data.** The attacker-framework implementation, target implementation, models, tools, state stores, operating systems, dependencies, and generated output may be malicious. ARTEX and RubyGems.org are reference implementations, not privileged components.

**A3 — Trusted workstation.** The operator workstation, its AWS and OpenRouter credentials, and its OpenSSH client are not initially compromised.

**A4 — Correct AWS boundary.** AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall enforce their documented policies. Breaking one is an escape through a trusted service, not a guest-policy bypass.

**A5 — Correct OpenRouter boundary.** OpenRouter enforces workspace policy, model restrictions, spend limits, key expiry, revocation, and disabled hosted tools.

**A6 — Correct cryptography.** The cryptography and authenticated protocols used by AWS, SSH, TLS, and OpenRouter hold.

**A7 — No valuable target contents.** The target contains synthetic data and fake credentials. Disclosure of its contents to the attacker framework or OpenRouter is expected.

**A8 — Hostile artifacts remain opaque.** The operator does not execute or automatically render results. Transfers use fixed local names and do not interpret remote paths.

**A9 — Eventual control-plane progress.** For deletion to finish, AWS and OpenRouter eventually process accepted operations and the controller or sweeper eventually runs again. Expiry does not depend on this assumption.

**A10 — Availability is out of scope.** Guests may exhaust their own resources, corrupt the experiment, or prevent a useful result. The security property is containment.

### What must always remain true

**I1 — No valuable guest authority.** No guest possesses AWS, GitHub, registry, production, or operator credentials.

**I2 — No unmediated external path.** Every packet leaving the attacker subnet crosses AWS-managed DNS and TLS policy. The target subnet has no external route.

**I3 — Declared chamber paths only.** The attacker framework can reach the target only on declared service ports and OpenRouter only through the filtered route. The target can reach only declared callback ports.

**I4 — Chamber isolation.** A guest in one chamber cannot communicate with or exercise authority over another chamber or a triage box.

**I5 — Management is operator-initiated.** The operator may initiate SSH through EC2 Instance Connect Endpoint. A guest cannot initiate a connection to the workstation or management plane.

**I6 — Inference is bounded.** A chamber can invoke only allowed models, without hosted tools, under its own hard budget and expiry.

**I7 — Guest policy is irrelevant.** Replacing guest firewall, routing, DNS, proxy, container, or attacker-framework configuration cannot enlarge externally permitted authority.

**I8 — Expiry removes useful authority.** At or after the deadline, inference and management authority are unusable even if compute or network deletion is delayed.

**I9 — Revocation is monotonic.** Once authority is expired or revoked, no retry, stale response, or delayed operation can make it live again.

**I10 — Removal is observed, not presumed.** A run is removed only after external APIs confirm every run-owned resource and capability absent.

**I11 — Failure cleans up.** A partially provisioned run is never active and converges on the same removal path as a healthy run.

**I12 — Runs cannot mutate each other.** Provisioning, expiry, revocation, deletion, verification, and sweeping are scoped by immutable run identity and generation.

**I13 — Exported evidence outlives the chamber.** The local record of explicit exports is monotonic and remote teardown does not remove it. The controller owns the record; guest-produced evidence bytes remain hostile.

**I14 — Hostile output is not an active path.** Guest-controlled bytes are never printed directly, interpreted as paths, automatically extracted, or opened in a browser.

### The boundary

Each run gets a dedicated VPC. The attacker and target use separate private subnets and separate EC2 instances. The target has no default route. The attacker's only default route passes through AWS Network Firewall before NAT. Route 53 Resolver DNS Firewall and TLS inspection admit the exact OpenRouter destination. Direct IPs, alternate DNS, forged SNI or Host headers, redirects, shared-CDN neighbors, arbitrary CONNECT requests, and other protocols remain denied.

The operator reaches only the attacker, over SSH, through an EC2 Instance Connect Endpoint. Gravity machines do not join the tailnet. The target accepts only declared service traffic from the attacker. Its egress security group admits only declared callback ports to the attacker. Security groups, route tables, DNS policy, TLS inspection, and OpenRouter workspace policy live outside both guests.

The attacker and target roles run from immutable images built before the chamber starts. Runtime package and registry access are absent. An attacker implementation supplies its process, health check, target-and-scope input, inference configuration, and opaque result bundle. A target implementation supplies its processes, health check, declared service and callback ports, synthetic data, and opaque logs. Neither role may add a trusted path or capability.

The reference attacker is a pinned, source-built ARTEX release, kept as an external AGPL workload. The reference target is a pinned RubyGems.org revision with its Rails application, PostgreSQL, Memcached, and OpenSearch. It uses synthetic seed data and a gravity-only canary weakness, not production data or the public service. Other implementations may replace either role without changing the chamber boundary.

The attacker-framework implementation holds its own capped OpenRouter key because disclosure of that key does not enlarge its authority. The workspace, not guest configuration, enforces the model list, hosted-tool ban, retention policy, budget, and expiry. The target holds no secret.

No attacker-framework UI is exposed. Control commands discard guest output. Evidence crosses SSH as opaque bytes into fixed filenames and is not extracted automatically. A live viewer is a separate future design problem.

### The trusted set

The formal model admits only three groups:

- the operator workstation and OpenSSH client;
- AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall;
- OpenRouter's API and policy enforcement.

Every attacker and target implementation—including ARTEX, RubyGems.org, and their dependencies—guest Linux, Docker, packages, guest policy, application data, and findings is outside the trusted set. The Alloy model rejects architectures that add general HTTPS, guest enforcement, cross-run paths, shared authority, or outbound management. Designs with a local proxy, a custom inference broker, Tailscale inside a gravity guest, sibling containers as the outer boundary, or a local attacker-framework browser are rejected for enlarging this set.

### What the formal checks mean

Alloy checks principals, paths, capability scope, chamber separation, and the trusted cut set within a stated finite scope. Its useful-chamber witness prevents a disconnected architecture from passing. Known-bad variants must produce instances.

TLA+ checks provisioning, provider rejection and retry, delayed completion across run generations, activation, expiry, revocation, deletion, observation, and removal. Every provider operation carries an immutable run and generation. Deletion requests and observed absence are separate states. Expected-failing mutations prove that the model detects premature removal, wrong-run deletion, and stale authority attachment. Expiry safety is independent of the controller; eventual resource deletion uses A9.

The models do not prove AWS or OpenRouter correct, prove arbitrary scopes, or prove future Terraform matches the architecture. The feature scenarios are the implementation-level evidence for that last step.

## Risks we accept

### Report triage

- A structurally valid text report can still contain prompt injection or exploit parser and presentation bugs. Validation is not sanitization.
- Public HTTP(S) lets a compromised agent disclose report contents, follow attacker-controlled links, and send abusive requests to reachable services. Those effects can outlive the run.
- Guest root can alter guest policy and corrupt the experiment. Only external enforcement is a security boundary.
- Exported files can attack the software or person that later opens them. Fixed filenames and opaque transfer do not make contents safe.
- Report exporters are outside dr-hands. The operator is responsible for the tools used before supplying a report.
- The attacker shapes the verdict and the fix. Tests and human review can help, but neither guarantees the operator's cognitive security; hostile content may manipulate the reviewer.

### Gravity machine

- AWS, OpenRouter, OpenSSH, TLS, or their control planes may have a severe unknown vulnerability.
- OpenRouter receives attacker-framework prompts and synthetic target contents by design.
- A guest can spend its own capped inference budget and destroy its own run.
- A malicious evidence archive can attack software that the operator later chooses to open.
- A permanently lost controller can leave inert cloud resources until a trusted sweeper runs; externally enforced authority still expires.
- Formal verification can be wrong because its assumptions, abstraction, bounds, or mapping to an implementation are wrong.
