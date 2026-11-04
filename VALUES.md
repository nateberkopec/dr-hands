# Values

These values explain why dr-hands works the way it does. The specifications say what it does. Every change must follow every rule here.

## The problem we solve

Checking a security report can mean opening hostile links, reading text written to trick you, and running an attacker's code. Doing that on your workstation puts your credentials, your network, and your other work at risk. Testing an attack tool against a live target can harm both the agent and the target.

dr-hands moves that work into a disposable run. You can investigate a report and collect evidence without giving the agent access to your workstation or production systems. dr-hands cannot protect your judgment from what you read.

## Assume everything in a run is hostile

- Every report is hostile, whatever its source.
- Every guest has root from the moment it boots. Assume the target is compromised from the start.
- Every image, input, and output is hostile, including public ones. Public means "allowed to be disclosed," not "safe."
- Schema validation and image pinning check structure and identity. They do not prove safety.
- [Security](SECURITY.md) links the threat model, data-flow policy, lifecycle, and accepted risks. The [gravity workflow](workflows/gravity.ts) states its reference assumptions.

## Enforce rules outside the guest

- Guest root can change anything inside the guest, so guest settings are never a security boundary.
- Put the rules that matter in services outside the guest: cloud networks, cloud access policy, and the inference service's workspace limits.
- If a provider cannot enforce a required rule, refuse the run. Never fall back to a guest firewall.

## Keep private data away from the public web

- Record the sensitivity of every image layer, input, and output. Missing sensitivity means private.
- Refuse any run that combines private data with public-web access. No approval or setting overrides this.
- Use separate runs for public browsing and private analysis. Never move private data into a public-browsing run.
- The configured inference service and its serving providers can read anything the run can read. Show them as recipients before approval. Zero retention limits storage; it does not prevent disclosure.

## Remove everything a guest could touch

- Every runtime resource and run capability belongs to exactly one run and has a registered cleanup step. Generate cleanup from that ownership record, not from a handwritten script.
- Never keep a runtime resource after removal.
- Request revocation first, then delete resources. Attempt deletion even if revocation fails, and keep all unresolved failures visible. Confirm revocation and each resource's absence independently of the backend. A successful delete call is not proof.
- A run's deadline is fixed at provisioning. Nothing extends it. Expiry must work even when the workstation is off.
- Exported evidence may survive as opaque files. It stays hostile.
- Removal cannot recall public-web requests or data already sent to the inference service.

## Trust as little as possible

Our goal is that escaping dr-hands requires a critical (CVSS 9+) zero-day in a mature upstream service, such as a cloud hypervisor or the inference service. This is a goal, not a promise about any unknown exploit. The firm rule is that every escape path must cross a named upstream security boundary. Keep that list of boundaries short.

- Let managed services enforce the rules. Do not run a long-lived custom control plane.
- Servers and databases inside a run are hostile workloads. They are destroyed with the run.
- Misconfiguration and chains of small bugs still matter. A provider's reputation does not prove a deployment secure.

## Separate the operator from the workflow

- The operator runs the dr-hands CLI. Workflows never call the CLI.
- A workflow is trusted TypeScript. It builds a typed plan through a constrained library API. Users may write their own workflows.
- The workflow defines roles, inputs, permitted connections, outputs, and cleanup obligations. Config supplies parameter values only. It never repeats the workflow's structure.
- Derive permissions from the relationships the plan declares, not from what the agent does.
- Images define what guests do. dr-hands adds no startup hooks or lifecycle scripts inside guests.
- Reports and guest output can never choose workflow code, change the plan, or widen permissions.

## Build on one backend: Alchemy

- Alchemy is the infrastructure backend. dr-hands calls it as a library, behind the constrained workflow API.
- Alchemy's state and delete results are not the ownership record. dr-hands keeps its own inventory and checks absence itself.

## Run locally and resume locally

- The controller runs on the operator's workstation. It needs no daemon, scheduler, or external workflow engine.
- After a crash, resume from saved state. Check real resources before repeating any step.

## Run anywhere

dr-hands targets macOS and Linux, from any shell and terminal. One mise-pinned Bun toolchain runs the CLI and its checks. Getting reports is separate from running them. The core needs no GitHub login and no particular report source.

## Define everything as code

Cloud resources come from code, not console clicks. A one-time manual step is acceptable only when the docs spell it out.

## Keep personal data out of the repository

- Personal settings live in the ignored `config.toml`. The tracked `config.example.toml` shows the format.
- Secrets live in your own secret store, reached through fnox. Settings name secret aliases, never secret values.
- Report sources connect by producing the documented report format. dr-hands never runs report-source plugins.

## Record every accepted risk

When we accept a new risk, add it to [accepted risks](security/risks.md).
