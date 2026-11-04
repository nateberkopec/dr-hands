# Provisioners

A provisioner maps an approved plan to infrastructure and an externally enforced boundary. Its backend manages resource operations; it does not define the workflow or its allowed data flows. The controller, provisioner, backend, and dependencies are trusted code.

## Selection

config.toml selects the provisioner and settings under provisioners.<name>. Required credentials are fnox aliases, not guest inputs. A trusted workflow selects typed operations, not infrastructure credential values. Reports and images cannot select local executables or integrations.

Another integration requires deliberate installation and review of its named boundaries and supported policies. Interface compatibility does not establish containment. Refuse unsupported requirements rather than falling back to a guest firewall or another provider.

## Responsibilities

- Check configuration and selected capabilities without mutation during doctor.
- Resolve immutable image references and compile declared relationships into externally enforced policy.
- Refuse private images/inputs combined with public-web access; classify the entire run, not isolated roles.
- Enforce policy before any image boots. Deny workstation, unrelated private-network, metadata/control-plane, and other-run access.
- Provision owned resources with stable Run ID and generation; reject unrelated resource adoption.
- Deliver only declared inputs at fixed destinations and grant only bounded run authority at activation.
- Implement idempotent operations and recovery from partially completed mutations.
- Register cleanup for every runtime resource and capability, including storage, interfaces, firewall resources, and inference authority.
- Enumerate owned resources independently of backend state and verify external absence.

The controller coordinates inference revocation with infrastructure deletion. Request revocation first; attempt deletion even if revocation fails, preserving failures. Compute deletion alone does not establish removal.

## State and failures

Keep an independent ownership inventory with original provider, configuration references, Run ID, generation, deadline, and pending operations. Do not store reports, credentials, or guest outputs in backend inputs, outputs, state, or traces. Changing config affects new runs only.

Serialize mutations for each run. Reconcile external state before replay and reject stale responses. Missing backend state is not proof of absence. Backend delete success does not authorize discarding unresolved inventory. Removal needs both confirmed revocation and observed resource absence.

The [backend evaluation](../workflows/backend.md) identifies Alchemy as the selected backend, used through its library API, with local state and generated resource cleanup. Policy validation, safe dry-run behavior, external expiry, and independent removal verification remain controller/provisioner obligations. A local cleanup handler cannot cover permanent workstation loss.
