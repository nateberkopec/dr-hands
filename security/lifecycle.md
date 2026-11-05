# Run lifecycle

Freeze the workflow/tool version, image identities, all input digests/destinations/sensitivities, recipients, derived permissions, budget, and deadline in the plan. Validate before asking for approval. Material changes require a new run and approval.

## Preparation and activation

Provisioning creates an expiring prepared run with immutable Run ID and generation. Install the external boundary before booting an image. Boot may execute hostile code and read private image layers; a later start signal is not a security barrier.

Withhold run-specific inputs and inference credentials until activation. The prepared run's deadline starts at provisioning and does not move when work starts. An expired run cannot activate. Partial provisioning enters removal rather than becoming active.

The controller is local and needs no daemon. Guest work may continue while the workstation is absent; external authority expiry remains effective. Persist bounded non-secret metadata, not credentials, report contents, or guest outputs in backend state or logs.

## Recovery

Serialize mutating operations for each run. Reconcile external state, ownership, generation, deadline, and revoked authority before replay. Never infer absence solely from missing local state. Never revive expired authority, adopt unrelated resources, or let stale completions attach to another generation.

Removal must work from recorded ownership even if the workflow definition is broken. Backend state is not the only inventory: losing its records must not make resources invisible.

## Removal and evidence

Completion, failure, cancellation, and expiry enter generated cleanup. Each runtime resource and capability has an owner and registered cleanup operation. Retaining guest-writable runtime resources is forbidden.

Request authority revocation before deletion. If revocation fails, still attempt resource deletion and retain all unresolved failures. Dependency-ordered destruction alone does not prove this ordering or absence.

Observe resource absence and authority revocation independently of backend success. Discover leftovers before recording removal. Preserve unresolved inventory through retries. A successful delete callback, an exited process, or a missing state row cannot certify removal.

Authority expires externally after the configured lifetime, at most twelve hours, even if the controller or guests fail. Full deletion requires eventual provider progress and a returning controller. This distinction is model assumption A9 in the Gravity Machine workflow.

Explicit export copies declared output bytes to fixed local filenames. Never print guest-controlled content directly, extract it, execute it, render it, or interpret it as a local path. Export cannot block cleanup or extend expiry. Completed exports and non-secret controller metadata survive removal; exports remain hostile and retain their sensitivity.
