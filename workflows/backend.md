# Infrastructure backend

Alchemy is the selected infrastructure backend. Use its programmatic plan/apply/destroy APIs behind the constrained workflow contract. Do not expose unrestricted Alchemy programs as security-checked workflows. Cloud execution stays outside this specification change.

Encore's application model and Nitric's requirements specification informed the separation between workflow intent and infrastructure. Alchemy is the closest evaluated fit for local state, inspectable plans, library calls, and resource-owned cleanup. It does not provide the whole dr-hands safety model.

## Local evidence

An isolated probe used published Alchemy 2.0.0-beta.85, Effect 4.1.2, and Bun 1.4.3 with a filesystem-only provider. All 15 process invocations had network access denied by the OS and no operator credentials. No cloud resources were created. The probe and its logs were local scratch artifacts outside this repository, not a committed regression suite or a cloud security certification.

- Planning exposed three resource operations without applying them.
- Library calls applied and destroyed the resources without CLI subprocesses.
- A fresh process resumed after forced exit without duplicates because the test provider used idempotent identities and read-back.
- Destroy generated reverse-dependency cleanup even with a broken workflow program.
- Deletion failures surfaced and could be retried.
- TypeScript rejected a provider missing its delete implementation.
- A separate scratch policy checker rejected private/unclassified input plus public web. That checker was not an Alchemy guarantee.

## Limits that the integration must enforce

Alchemy planning evaluates construction code. Constrained authoring must exclude arbitrary side effects; a no-apply flag alone is not an offline or read-only boundary. Remote-state bootstrap during planning is forbidden for dry-run.

Alchemy permits `retain`, which skips physical deletion. Reject it for runtime resources. Inspect actual removal policy, not only the create/update diff: policy changes can be reported as no-ops.

A deliberately faulty delete implementation returned success while leaving the simulated resources present. Alchemy removed its state records, and a second destroy planned no deletions. Keep an independent ownership inventory, verify absence externally, and discover leftovers. A delete method's existence is not evidence that it worked.

Do not persist reports, credentials, or guest outputs in resource properties, outputs, traces, or state. Store only bounded non-secret references and controller metadata. Disable telemetry that would disclose run data. Select credentials explicitly through fnox rather than ambient fallbacks.

Reverse dependency order does not establish revocation-before-deletion. Run state, approval, deadlines, cancellation, operation serialization, export, and authority revocation remain explicit controller duties. Local resource recovery does not establish end-to-end investigation resumption.

Real-service checks must establish IAM/network policy compilation, EC2/storage/firewall cleanup, inference revocation, and external expiry. Provider correctness, data erasure, concurrency safety, and complete rejection of arbitrary TypeScript effects were not established by the probe. Beta APIs require a pinned integration and renewed checks when upgraded.

## Sources

- [Alchemy programmatic API](https://alchemy.run/cli/api)
- [Resource lifecycle and retain semantics](https://alchemy.run/infrastructure-as-code/resource-lifecycle)
- [State storage and bootstrap](https://alchemy.run/state-store)
- [Inspected source revision](https://github.com/alchemy-run/alchemy/tree/03f8e3a2ad9c96fe92c2755695b6ccd854753b2e)
- [Encore application model](https://encore.dev/docs/understanding-encore)
- [Nitric infrastructure specification](https://nitric.io/docs/get-started/foundations/infrastructure)
