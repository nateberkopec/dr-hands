# Formal verification

This is the deepest layer of the gravity acceptance pyramid. Start at [GRAVITY.md](../GRAVITY.md), then read the [threat model](../SECURITY.md#gravity-machine) and [behavioral acceptance](../features/gravity.feature) before reading the models.

The [proof map](features/README.md) is the maintained guide to every formal feature and its evidence.

## Verification protocol

**Doctor:** `mise run verify-formal-doctor` checks Java, Fish, Ruby, model files, and any cached tool checksums without creating evidence.

**Drive:** `mise run verify-formal` runs the harness self-test, Alloy, three passing TLC configurations, and three expected-failing TLC mutations. Set `DR_HANDS_VERIFY_RUN=NAME` for a stable evidence name.

**Observe:** the harness reads `receipt.json` and TLC logs back, requires the exact Alloy command set, inspects key mutation edges, requires nonzero lifecycle action coverage, and checks each TLA+ mutation's literal violation. Exit status alone is not proof.

**Evidence:** each run writes a new `tmp/verify/formal/NAME/` containing raw logs, the Alloy receipt, the git revision, artifact hashes, `summary.json`, and `SUMMARY.md`. A second run cannot overwrite it.

**Cleanup:** model-checker state directories are scratch and disappear when the process exits. Tool caches and every evidence directory remain. Neither is committed.

## What is modeled

The two models answer different questions.

- [Alloy](alloy/gravity.als) asks who can reach whom, who holds authority, which component enforces each boundary, and whether an escape can avoid the named trusted set.
- [TLA+](tla/GravityLifecycle.tla) asks whether partial provisioning, rejected and delayed provider operations, later generations, time, controller failure, revocation, deletion, and observation can put a run into an unsafe lifecycle state.

Neither model fixes an attacker framework or target implementation. ARTEX and RubyGems.org implement those abstract roles for G1's behavioral canary check; their behavior is not a formal claim.

## Alloy: static authority

### Vocabulary

The model contains two chambers, each with one abstract attacker-framework role and one abstract target role. It distinguishes the operator, workstation, AWS control plane, hypervisor, AWS network guard, EC2 Instance Connect, OpenRouter, and the public Internet. Network reachability and capability possession are separate relations.

`IntactArchitecture` fixes the intended paths:

```text
workstation -> Instance Connect -> attacker
attacker <-> same-chamber target
attacker -> AWS network guard -> OpenRouter
```

There is no guest edge to the workstation, AWS control plane, Internet, another chamber, or a triage box. Inference capabilities belong to one chamber. Cloud and OpenRouter administration belong only to the operator.

`effectiveNetwork` adds the consequences of compromising a trusted boundary. This lets `EscapeRequiresTrustedFailure` state the intended cut-set property: the declared architecture has no escape unless a named trusted component is broken.

### Checks

The model checks:

- a useful attacker reaches both its target and OpenRouter;
- a target reaches no destination beyond its chamber and the allowed inference path through its cooperating attacker;
- management is inbound only;
- guests hold no cloud or OpenRouter administration;
- inference authority is chamber-scoped;
- no guest enforces policy;
- chambers cannot reach one another;
- escape requires a trusted failure;
- the trusted set contains only the named principals.

A satisfiable `IntactArchitecture` run prevents the checks from passing because no usable chamber exists.

### Known-bad architectures

The same model requires witnesses for five unsafe mutations:

- general Internet egress;
- an inference capability scoped to another chamber;
- a cross-chamber network edge;
- a guest added to the enforcement set;
- outbound management access to the workstation.

The task fails if an intended check finds a counterexample or if a known-bad mutation no longer has one. This tests the model's sensitivity as well as its preferred design.

### Bounds

All Alloy commands use exactly two chambers, two attackers, two targets, and two inference capabilities. Singleton trusted principals are exact by declaration. Alloy proves the assertions only within this scope. Two chambers are enough to expose shared authority and cross-run edges, but not every larger topology error.

## TLA+: lifecycle

### State

The lifecycle model tracks, per run:

- phase, current generation, and operation target;
- deadline and logical time;
- resources and authorities with the generation that attached them;
- pending create, grant, revoke, and delete operations carrying run and generation identity;
- rejected operations and retries;
- deletion and revocation requests;
- externally confirmed absence;
- removal and provisioning failure;
- trusted local evidence;
- controller availability.

The phases are `Absent`, `Provisioning`, `Active`, `RemovalRequested`, `Expired`, `Revoking`, `Deleting`, `Verifying`, and `Removed`.

Deletion has three different facts: deletion was requested, the resource is no longer present, and an external observation confirmed absence. `Removed` requires the third. Revocation is modeled the same way.

Authority usability is derived from phase, deadline, confirmed revocation, and matching generation. Advancing time beyond a deadline makes authority unusable without waiting for a controller action. A delayed completion is consumed, but changes a run only when both its run and generation still match.

### Actions

The transition system includes starting and later reusing a run, requesting, completing, and rejecting provider operations, activation, provisioning failure, requested removal, expiry, revocation, deletion, absence observation, final verification, evidence preservation, time advancement, controller crash, and controller resume.

The liveness configuration uses one abstract resource and authority for one generation. A generation configuration exercises rejection, retry, delayed completion, and reuse across two generations without liveness. The crash configuration uses one abstract resource and authority with controller loss, return, rejection, and retry. The isolation configuration checks two interleaved runs. This separation keeps temporal checking small while retaining the distinct failure shapes in safety exploration.

### Safety

TLC checks that:

- types remain valid;
- only a complete run with current-generation authority becomes active;
- stale operation completions cannot attach resources or authority;
- deadline expiry makes authority unusable;
- revocation is complete before deletion and cannot go backwards during cleanup;
- a run's deadline cannot move within a generation;
- `Removed` means no resource remains and all absence is confirmed;
- removed runs have no authority;
- failed provisioning never becomes active;
- evidence remains run-scoped and monotonic;
- an operation can mutate only the run identity it carries.

### Liveness

With weak or strong fairness for time, revocation, provider deletion, observation, and verification, TLC checks that:

- a removal request eventually reaches `Removed`;
- expiry eventually reaches confirmed revocation;
- failed provisioning eventually reaches `Removed`;
- a requested deletion eventually makes the resource absent.

These properties depend on SECURITY.md assumption A9. If the controller never returns or a provider never completes an accepted operation, full deletion cannot be guaranteed. Deadline-based loss of authority and stale-generation rejection remain safety properties and do not use A9.

### Negative controls

`GravityLifecycleMutations.tla` deliberately permits premature removal, deletion of the wrong run, and application of a stale authority grant. Each has its own configuration. Verification succeeds only when TLC returns a failing trace naming `RemovedImpliesNothingRemote`, `RunIsolation`, and `NoStaleAttachment`, respectively.

### Bounds

`GravityLifecycle.cfg` checks one run and generation with one abstract resource and authority, a two-tick lease, and time through tick four. `GravityGeneration.cfg` checks the same run across two generations with rejection, retry, and delayed completion. `GravityCrash.cfg` checks one abstract resource and authority with rejection, retry, and controller crashes through tick three. `GravityIsolation.cfg` checks two runs with one abstract resource and authority through tick two. The three mutation configs use the smallest scopes that can exhibit their unsafe behavior.

The model deliberately collapses provider-specific resources. Implementation scenarios must enumerate instances, volumes, interfaces, endpoints, firewall resources, and keys.

## Traceability

| Claim | Security invariants | Alloy | TLA+ | Behavioral acceptance |
|---|---|---|---|---|
| G1 useful chamber | I3 | `UsefulChamberIsContained` | `ActiveImpliesComplete` | reference ARTEX/RubyGems.org canary and matching log |
| G2 root contained | I2, I7 | `TargetHasOnlyChamberPaths`, `NoGuestEnforcesPolicy` | authority derived outside guest state | root path and policy-replacement scenarios |
| G3 declared paths | I2–I5 | `ManagementIsInboundOnly`, `NoCrossChamberReachability` | run-scoped resource state | allowed and forbidden path scenarios |
| G4 bounded inference | I6, I8, I9 | `InferenceIsRunScoped` | `NoStaleAttachment`, `ExpiredAuthorityUnusable`, `RevocationMonotonic`, `DeadlineStable` | workspace, budget, expiry, and egress-evasion scenarios |
| G5 nothing valuable | I1 | `NoValuableGuestCapability` | authority classes only | credential and immutable-image scenarios |
| G6 inert output | I14 | outside the model | `EvidenceIsRunScoped`, `EvidenceMonotonic` | status and opaque-result scenarios |
| G7 expiry first | I8, I9 | capability scope | generation-tagged operations, `NoStaleAttachment`, expiry and revocation properties | absent-controller and stale-operation scenarios |
| G8 proven teardown | I10–I13 | cross-chamber capability and path checks | run-tagged operations, removal safety, liveness, `RunIsolation`, and wrong-run mutation | removal, partial failure, sweep, and observation scenarios |

## What these checks do not prove

They do not prove that AWS or OpenRouter satisfy A4 and A5, that cryptography holds, that the finite scope generalizes, that the model contains every relevant capability, or that future infrastructure code implements this design. They also do not assign a CVSS score to an unknown vulnerability.

Their purpose is narrower: make every trust assumption visible, find ordinary paths that avoid those assumptions, and reject lifecycle orderings that strand authority or declare cleanup early. Real-service feature scenarios close the model-to-implementation gap when the system is built.
