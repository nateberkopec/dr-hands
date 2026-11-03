# Security

dr-hands runs coding agents on private security reports. Strangers write those reports, and some will try to trick the agent. This page explains what dr-hands protects and how.

## Report a problem

Report security problems in dr-hands privately through [GitHub's private vulnerability reporting](https://github.com/nateberkopec/dr-hands/security/advisories/new). Don't open a public issue.

## What we assume

Every report is hostile, regardless of its source. Its author may control:

- the report text, comments, and attachments, including hidden text aimed at AI
- proof-of-concept code and the packages it pulls in
- source-local metadata that becomes filenames, identifiers, or error text
- the agent itself, through prompt injection

A report source is different from a report. Source executables run as you on your laptop and are trusted code. GitHub and text are built in; you are responsible for every custom source you configure.

A provisioner is also trusted local code. It runs with infrastructure credentials and owns the external isolation boundary. AWS is built in; you are responsible for the code and real-service evidence of a custom provisioner. Schema validation can catch a broken result but cannot make a malicious executable safe.

So we treat the agent as the attacker. It gets a shell, but nothing worth stealing.

The report is not the secret. Its author already has it. We protect:

- your laptop, its keys, and your logins
- credentials for GitHub, HackerOne, or any other report source
- your home network and tailnet
- your money and AI quota
- your judgment about the report

## How dr-hands protects you

**One cloud box per run.** Each normalized report snapshot gets fresh infrastructure from the selected provisioner. It holds no report-source, GitHub, infrastructure, or AI provider keys. It deletes itself after 12 hours.

**No network by default.** The agent can reach two things: a proxy that allows GitHub and your package hosts, and the AI broker. A firewall on the box blocks the rest, including DNS and the cloud metadata service.

**A broker for AI.** Boxes never see a real AI key. Each box gets its own short-lived broker key. The broker allows only listed models, caps tokens per report, and keeps each report's sessions apart.

**A locked-down tailnet.** Boxes can reach the broker's port and nothing else, not even other boxes or your laptop.

**A trusted local intake boundary.** A report source finishes before cloud provisioning. dr-hands accepts only fixed snapshot filenames, captures source output, and keeps source credentials out of the snapshot and run state.

**A scanner, as a tripwire.** Your laptop scans every normalized snapshot for hidden text, lookalike letters, and words aimed at AI. Plain-English tricks still get through.

**A guarded terminal.** You connect in a separate terminal window that blocks clipboard access, links, and images.

**You stay in charge.** You take every report-source and repository action yourself. Fixes come back as patch files, and dr-hands flags changes to build files and dependencies. Read every line before you apply one.

## Why not a local VM

A local VM or container runs on the machine that holds your keys. If the agent breaks out, it lands there. A container shares its host's kernel, so one kernel bug is enough. A break-out from a cloud box lands on a host with nothing of yours, off your network. That costs about a dollar per report.

## Gravity machine

[GRAVITY.md](GRAVITY.md) is the short contract. This section is its second acceptance layer: the assumptions, invariants, architecture, and limits behind the eight top-level claims. The [Gherkin scenarios](features/gravity.feature) and [formal models](formal/README.md) carry the same IDs into deeper layers.

### What we assume

**A1 — Total guest compromise.** The attacker may obtain root on both machines in a chamber and coordinate them. Guest root exists before any property below is evaluated.

**A2 — Hostile software and data.** The attacker-framework implementation, target implementation, models, tools, state stores, operating systems, dependencies, and generated output may be malicious. ARTEX and RubyGems.org are reference implementations, not privileged components.

**A3 — Trusted workstation and provisioner.** The operator workstation, selected provisioner executable, infrastructure and OpenRouter credentials, and OpenSSH client are not initially compromised.

**A4 — Correct infrastructure boundary.** The selected provisioner's declared control plane, compute boundary, network boundary, and management ingress enforce their documented policies. Breaking one is an escape through a trusted service, not a guest-policy bypass. For the bundled implementation these roles are AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall.

**A5 — Correct OpenRouter boundary.** OpenRouter enforces workspace policy, model restrictions, spend limits, key expiry, revocation, and disabled hosted tools.

**A6 — Correct cryptography.** The cryptography and authenticated protocols used by the selected infrastructure, SSH, TLS, and OpenRouter hold.

**A7 — No valuable target contents.** The target contains synthetic data and fake credentials. Disclosure of its contents to the attacker framework or OpenRouter is expected.

**A8 — Hostile artifacts remain opaque.** The operator does not execute or automatically render results. Transfers use fixed local names and do not interpret remote paths.

**A9 — Eventual control-plane progress.** For deletion to finish, the selected infrastructure and OpenRouter eventually process accepted operations and the controller or sweeper eventually runs again. Expiry does not depend on this assumption.

**A10 — Availability is out of scope.** Guests may exhaust their own resources, corrupt the experiment, or prevent a useful result. The security property is containment.

### What must always remain true

**I1 — No valuable guest authority.** No guest possesses infrastructure, GitHub, registry, production, or operator credentials.

**I2 — No unmediated external path.** Every packet leaving the attacker role crosses the provisioner's external DNS and TLS policy. The target subnet has no external route.

**I3 — Declared chamber paths only.** The attacker framework can reach the target only on declared service ports and OpenRouter only through the filtered route. The target can reach only declared callback ports.

**I4 — Chamber isolation.** A guest in one chamber cannot communicate with or exercise authority over another chamber or a triage box.

**I5 — Management is operator-initiated.** The operator may initiate SSH through the provisioner's external management ingress. A guest cannot initiate a connection to the workstation or management plane.

**I6 — Inference is bounded.** A chamber can invoke only allowed models, without hosted tools, under its own hard budget and expiry.

**I7 — Guest policy is irrelevant.** Replacing guest firewall, routing, DNS, proxy, container, or attacker-framework configuration cannot enlarge externally permitted authority.

**I8 — Expiry removes useful authority.** At or after the deadline, inference and management authority are unusable even if compute or network deletion is delayed.

**I9 — Revocation is monotonic.** Once authority is expired or revoked, no retry, stale response, or delayed operation can make it live again.

**I10 — Removal is observed, not presumed.** A run is removed only after the provisioner's independent read-only view and external authority APIs confirm every run-owned resource and capability absent.

**I11 — Failure cleans up.** A partially provisioned run is never active and converges on the same removal path as a healthy run.

**I12 — Runs cannot mutate each other.** Provisioning, expiry, revocation, deletion, verification, and sweeping are scoped by immutable run identity and generation.

**I13 — Evidence outlives the chamber.** Trusted local evidence is monotonic and remote teardown does not remove it.

**I14 — Hostile output is not an active path.** Guest-controlled bytes are never printed directly, interpreted as paths, automatically extracted, or opened in a browser.

### The boundary

Every provisioner must keep compute isolation, network enforcement, management ingress, and the control plane outside both guest roles. Its provider-neutral request contains only the declared roles and paths. Its external read-only observer must agree with normal inspection before activation and must prove absence after deletion. A replacement cannot move enforcement into a guest or add a path.

The bundled AWS implementation maps this contract to a dedicated VPC. The attacker and target use separate private subnets and separate EC2 instances. The target has no default route. The attacker's only default route passes through AWS Network Firewall before NAT. Route 53 Resolver DNS Firewall and TLS inspection admit the exact OpenRouter destination. Direct IPs, alternate DNS, forged SNI or Host headers, redirects, shared-CDN neighbors, arbitrary CONNECT requests, and other protocols remain denied.

The operator reaches only the attacker, over SSH, through an EC2 Instance Connect Endpoint. Gravity machines do not join the tailnet. The target accepts only declared service traffic from the attacker. Its egress security group admits only declared callback ports to the attacker. Security groups, route tables, DNS policy, TLS inspection, and OpenRouter workspace policy live outside both guests.

The attacker and target roles run from immutable images built before the chamber starts. Runtime package and registry access are absent. An attacker implementation supplies its process, health check, target-and-scope input, inference configuration, and opaque result bundle. A target implementation supplies its processes, health check, declared service and callback ports, synthetic data, and opaque logs. Neither role may add a trusted path or capability.

The reference attacker is a pinned, source-built ARTEX release, kept as an external AGPL workload. The reference target is a pinned RubyGems.org revision with its Rails application, PostgreSQL, Memcached, and OpenSearch. It uses synthetic seed data and a gravity-only canary weakness, not production data or the public service. Other implementations may replace either role without changing the chamber boundary.

The attacker-framework implementation holds its own capped OpenRouter key because disclosure of that key does not enlarge its authority. The workspace, not guest configuration, enforces the model list, hosted-tool ban, retention policy, budget, and expiry. The target holds no secret.

No attacker-framework UI is exposed. Control commands discard guest output. Evidence crosses SSH as opaque bytes into fixed filenames and is not extracted automatically. A live viewer is a separate future design problem.

### The trusted set

The formal model admits only three groups:

- the operator workstation, selected provisioner executable, and OpenSSH client;
- the provisioner's declared control plane, compute boundary, network boundary, and management ingress;
- OpenRouter's API and policy enforcement.

The AWS implementation maps the infrastructure group to AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall. A third-party implementation names its own services but cannot add another trust role.

Every attacker and target implementation—including ARTEX, RubyGems.org, and their dependencies—guest Linux, Docker, packages, guest policy, application data, and findings is outside the trusted set. The Alloy model rejects architectures that add general HTTPS, guest enforcement, cross-run paths, shared authority, or outbound management. Designs with a local proxy, a custom inference broker, Tailscale inside a gravity guest, sibling containers as the outer boundary, or a local attacker-framework browser are rejected for enlarging this set.

### What the formal checks mean

Alloy checks principals, paths, capability scope, chamber separation, and the trusted cut set within a stated finite scope. Its useful-chamber witness prevents a disconnected architecture from passing. Known-bad variants must produce instances.

TLA+ checks provisioning, provider rejection and retry, delayed completion across run generations, activation, expiry, revocation, deletion, observation, and removal. Every provider operation carries an immutable run and generation. Deletion requests and observed absence are separate states. Expected-failing mutations prove that the model detects premature removal, wrong-run deletion, and stale authority attachment. Expiry safety is independent of the controller; eventual resource deletion uses A9.

The models do not prove a selected provisioner, AWS, or OpenRouter correct, prove arbitrary scopes, or prove future infrastructure code matches the architecture. The feature scenarios are the implementation-level evidence for that last step.

## Risks we accept

### Report triage and local extensions

- A custom report source is trusted code running as you. A malicious or vulnerable source can compromise your laptop before a box exists.
- A custom provisioner is trusted code running with infrastructure credentials. A malicious or vulnerable provisioner can compromise your laptop or infrastructure account before a guest exists.
- Report-source APIs can return hostile metadata as well as hostile prose. Capturing and normalizing output reduces terminal risk but cannot make a trusted source executable safe.
- An agent that gets root on its box can remove the firewall. It still holds only that report's broker key, which expires.
- Allowed hosts work both ways. The agent could send data to GitHub or a package host, or pull in an attacker's package.
- The agent can reach any server it starts on its own box.
- Text from the box reaches your terminal and SSH client.
- The attacker shapes the verdict and the fix. The failing test and your review are the defense.

### Gravity machine

- The selected infrastructure, AWS reference services, OpenRouter, OpenSSH, TLS, or their control planes may have a severe unknown vulnerability.
- OpenRouter receives attacker-framework prompts and synthetic target contents by design.
- A guest can spend its own capped inference budget and destroy its own run.
- A malicious evidence archive can attack software that the operator later chooses to open.
- A permanently lost controller can leave inert cloud resources until a trusted sweeper runs; externally enforced authority still expires.
- Formal verification can be wrong because its assumptions, abstraction, bounds, or mapping to an implementation are wrong.
