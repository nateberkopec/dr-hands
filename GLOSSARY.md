# dr-hands language

Use these terms for the investigation boundary, its contents, and its lifecycle. Formal gravity models retain some older names; the mappings below make those names explicit.

## Plans and execution

**Operator**:
The person who selects trusted workflow code, supplies parameters, and approves a run.
_Avoid_: User (when authorship or approval is meant)

**Controller**:
The trusted local process that validates plans, manages run transitions, and verifies removal.
_Avoid_: Agent, guest framework

**Approval**:
The operator's consent to one frozen plan before provisioning.
_Avoid_: Preview, schema validation

**Workflow**:
A trusted definition of an investigation's roles, inputs, permitted relationships, outputs, and cleanup obligations.
_Avoid_: Lifecycle script, experiment manifest

**Plan**:
A resolved workflow with its parameter values, resource ownership, permissions, input identities, and cleanup obligations.
_Avoid_: Workflow, deployment config

**Run**:
One execution of an approved plan, identified independently from its report or workflow.
_Avoid_: Box, session, experiment, chamber (except in the reference gravity models)

**Prepared run**:
A provisioned run whose investigation has not started and whose original expiry already applies.
_Avoid_: Idle environment, reusable stack

**Activation**:
The transition from a prepared run to an investigation with declared inputs and bounded inference authority.
_Avoid_: Boot, provisioning

**Generation**:
The incarnation of a run to which a resource, capability, or pending operation belongs.
_Avoid_: Retry number, workflow version

**Provisioner**:
The trusted integration that maps a run's requirements to infrastructure and external enforcement.
_Avoid_: Report source, guest framework

**Backend**:
The infrastructure engine used by a provisioner to plan and reconcile resources.
_Avoid_: Provisioner, workflow runner

## Contents and authority

**Guest**:
A hostile execution environment inside a run, assumed to have root from boot.
_Avoid_: Trusted worker, box

**Run boundary**:
The externally enforced limit on a run's access to other systems and authority.
_Avoid_: Guest firewall, container boundary

**Role**:
A participant in a workflow, such as an investigating agent, attacker, or target.
_Avoid_: Machine type, framework

**Image**:
An immutable software environment for a role, including all layers and embedded data.
_Avoid_: Trusted base, safe image

**Input**:
An operator-declared item supplied to a run with an identity, destination, and sensitivity.
_Avoid_: Implicit mount, setup hook

**Report**:
Structured text containing a security claim and supporting material, treated as hostile input.
_Avoid_: Issue (when the source is not an issue tracker), advisory copy

**Report source**:
The report's origin, recorded only as provenance.
_Avoid_: Source plugin, exporter

**Sensitivity**:
Whether contents are permitted for public disclosure or may be private; it is separate from trustworthiness.
_Avoid_: Safety level, taint (when confidentiality is meant)

**Hostile content**:
Data or code assumed capable of attacking its reader or execution environment, whether public or private.
_Avoid_: Infected content, private content (when hostility is meant)

**Private analysis**:
An investigation allowed to read private inputs while communicating externally only with configured inference recipients.
_Avoid_: Offline analysis, zero-egress run

**Public browsing**:
An investigation with public HTTP(S) access and only explicitly public images and inputs.
_Avoid_: General triage (when web permission is meant)

**Lethal trifecta**:
The combination of private data, hostile content, and external communication in one disclosure boundary.
_Avoid_: A safety score

**Recipient**:
An external service allowed to receive run data, including inference services and their serving providers.
_Avoid_: Safe endpoint, zero-egress service

**Run authority**:
The bounded capabilities granted to one run, including inference and management access.
_Avoid_: Credentials (when the effective permissions are meant)

**Runtime resource**:
A disposable resource created for a run, including every guest-writable storage or network surface.
_Avoid_: Instance (when all resources are meant)

**Ownership inventory**:
The controller's record of a run's resources, capabilities, identities, and unresolved cleanup obligations.
_Avoid_: Backend state, local directory

## Results and removal

**Evidence**:
Guest-produced findings, logs, or other output that remain hostile regardless of validity. Workflow output declarations name the evidence eligible for export.
_Avoid_: Trusted result, safe artifact

**Export**:
An explicit transfer of declared evidence into opaque local files outside the disposable runtime.
_Avoid_: Render, publish, declassify

**Revocation**:
Withdrawal of run authority, distinct from requesting or observing resource deletion.
_Avoid_: Shutdown, teardown

**Deadline**:
The fixed time at which a run's authority expires; historical models call its bounded duration a lease.
_Avoid_: Retry timeout, renewable lease

**Cleanup obligation**:
The requirement to revoke a run capability or delete a runtime resource as part of removal.
_Avoid_: Optional cleanup hook

**Cleanup operation**:
A registered revocation or deletion action that discharges an ownership obligation only after independent verification.
_Avoid_: Removal complete (when only a delete callback returned)

**Reconciliation**:
Comparison of recorded ownership with external observations to recover pending work and find leftovers; historical guides call leftover discovery a sweep.
_Avoid_: Blind retry, state-file deletion

**Expiry**:
The externally enforced end of a run's usable authority at its original deadline.
_Avoid_: Deletion, controller timeout

**Removal**:
Revocation and destruction of runtime resources, completed only after independent absence observations.
_Avoid_: Delete request, backend success
