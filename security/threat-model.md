# Threat model

Every report is hostile, regardless of source. Its author may control report text, comments, URLs, code snippets, model files, packages, and provenance strings. Prompt injection may control the agent. Assume root on every guest and a compromised target from the start.

Report intake accepts only [bounded JSON](../schemas/report.schema.json). Obtaining reports and handling report-source credentials are outside dr-hands. The local validator checks structure and bounds without rendering markup, executing snippets, importing attachments, or following links. Validation does not certify safety.

## Trusted control plane

The operator selects a trusted workflow independently of the report. Workflow code constructs a typed plan through a constrained API. It runs with local trust; arbitrary TypeScript is not sandboxed merely because it describes infrastructure. Reports and guest outputs cannot choose workflow code, alter the plan, or grant permissions.

The controller, policy compiler, infrastructure backend, selected provisioner, runtime, and dependencies are trusted code that require review. The finite gravity model does not enumerate their internals. Types can expose obligations but do not establish that a provider performs deletion or enforces networking.

The operator supplies immutable images and declared inputs. Images own guest processes; no process-ordering assumption hides data from guest root. All image layers count, including deleted-but-recoverable files. Pinning identifies content, not safety or correct classification.

## External enforcement

One run owns its disposable resources and authority. Guest policy cannot enlarge externally permitted access. Deny the workstation, unrelated private networks, metadata/control-plane endpoints, and other runs. Verify actual destinations, redirects, IPv6, and DNS rebinding outside guests. A provider that cannot enforce the requested policy must refuse the run.

Guests receive no operator, production, cloud-administration, report-source, registry, or inference-administration credentials. Disposable inference credentials are bounded by service-enforced model/tool restrictions, budget, and expiry. Authentication alone does not establish those capabilities.

A cloud boundary places hostile computation away from the workstation. It does not make provider escape impossible: provider isolation, policy enforcement, cryptography, and the trusted controller remain assumptions. Hostile model deserialization or package execution inside a guest is already in scope; crossing to provider hosts, other tenants, management services, or unrelated credentials is not.

No live host mounts or shared guest-writable persistent storage enter the run. Source snapshots reject links escaping their declared root. Inputs use fixed destinations; outputs are opaque and exported only by explicit operator action.
