# Provisioners

A provisioner implements a Run's infrastructure and externally enforced security boundary. Workflows declare roles and requirements; they do not run local lifecycle hooks or choose their own infrastructure credentials.

## Selection and configuration

`config.toml` selects `provisioner = "aws"` or another explicitly installed integration. Settings belong under `provisioners.<name>`, with fnox aliases under `provisioners.<name>.secrets`. A report or workflow manifest cannot supply a local executable path.

Provisioner code operates with operator authority and must be installed deliberately. This is distinct from guest role code, which is assumed malicious, and report data, which is never executed locally. Using another provider requires reviewing its named security boundaries and supported policies; interface compatibility alone does not establish containment.

## Responsibilities

A provisioner must:

- validate its configuration and declare the policies it can enforce;
- check selected service capabilities without mutation during doctor;
- resolve and verify immutable image references for declared roles;
- create isolated role resources and enforce permitted paths outside the guests;
- deny workstation, private-network, other-run, metadata, and management access;
- establish operator-initiated management and verify guest identity;
- inventory every run-owned resource and capability by immutable run identity and generation;
- remove partial or complete runs idempotently and observe external absence;
- enumerate and sweep run-owned resources using provider state, not just local directories.

The same lifecycle serves triage, gravity, and custom workflows. If a provider cannot enforce public-web restrictions or gravity's tighter policy, it must reject that workflow. A guest firewall is not a fallback for missing external enforcement.

Inference authority belongs to the selected inference service. The controller coordinates its revocation with provider cleanup; destroying compute alone does not mean a run is removed.

## State and failures

Each run records its provider, non-secret configuration snapshot, resource identities, and generation. Changing the selected provider affects new runs only. Cleanup uses the original provider and inventory and fails visibly if required credentials or external observations are unavailable.

Retries must not attach stale resources or revive expired authority. Removal checks for every guest-writable runtime surface, including storage, interfaces, and policy resources, not only machines. Explicitly exported evidence is outside the runtime inventory and remains hostile.

A provisioner owns its internal infrastructure tool and state layout. The core contract does not require Terraform or AWS-specific identifiers.
