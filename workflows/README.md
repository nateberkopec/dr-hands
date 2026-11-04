# Workflow contract

A trusted operator-authored workflow constructs a typed plan through library APIs. Operators invoke dr-hands; workflows never invoke the CLI. Guest images own guest processes. Reports and guest output cannot select trusted code, alter the graph, or widen permissions.

The two supplied descriptions are [triage](triage.ts) and [gravity](gravity.ts). Their shared [type](contract.ts) requires owned-resource cleanup. These are type-checked specification data, not an executor or a proof of policy enforcement. `dr-hands lint` describes the complete plan checks; it does not implement them. The report linter is the working validation command.

## One source of structure

The workflow owns roles, parameter declarations, input destinations, permitted relationships, outputs, and cleanup obligations. Config supplies parameter values, not a second graph. Missing sensitivity is private. Omitted optional inputs are absent from the inventory; required inputs must exist. Reject unknown parameters, mismatched kinds, dangling references, duplicate destinations, invalid ports, and unsupported role interfaces.

A plan freezes the workflow/tool version, parameters, image identities, input digests, resources, authority, recipients, permissions, cleanup obligations, and deadline. A fresh Run ID and generation identify its execution. Material changes require a new run and approval.

## Lifecycle

`lint` is local; `doctor` diagnoses required tools and service capabilities; `dry-run` previews changes using read-only service access. None may create cloud resources or mint authority. Arbitrary TypeScript side effects are not made safe by an engine's plan flag. Only the constrained authoring API belongs in a workflow; trusted extensions require separate review.

`provision` obtains approval and creates an expiring prepared run. External policy must hold before images boot. Boot itself can execute hostile code and read private image layers. Run-specific inputs and inference authority are withheld until activation.

`run WORKFLOW` provisions and executes a fresh run. `run --prepared RUN_ID` reconciles the frozen prepared run without extending its deadline. Completion, failure, cancellation, and expiry enter removal. Export is explicit and cannot delay removal.

`status`, `resume`, and `remove` operate on recorded ownership even when the workflow definition is broken. Serialize mutations for each run. Resume observes resources and authority before replay; expired or removing runs can only continue removal. No local daemon is required. External expiry continues while the workstation is absent.

## Ownership and cleanup

Every created resource and capability has one run owner and a registered cleanup operation. Generate cleanup from that inventory, not an author's hand-maintained delete script. Reject retained runtime resources and unmanaged side effects. Source images and explicit exports are distinct from disposable runtime resources.

Request revocation first, then delete runtime resources in dependency order. A revocation failure must not prevent deletion attempts; record all unresolved failures. Backend success is not proof of deletion. Independently verify absence and discover leftovers beyond backend state before marking a run removed. Preserve unresolved inventory through crashes and retries.

[Backend evaluation](backend.md) records Alchemy's selection and its limits. [Data-flow policy](../security/data-flow.md) defines allowed disclosures. [CLI help](../cli/help/) defines operator commands.
