# Formal verification

This is the deepest layer of the gravity acceptance pyramid. Start at [GRAVITY.md](../GRAVITY.md), then read the [threat model](../SECURITY.md#gravity-machine) and [behavioral acceptance](../features/gravity.feature) before reading the models.

Run both model checkers with:

```sh
mise run verify-formal
```

The task downloads checksum-pinned Alloy 6.2.0 and TLA+ 1.7.4 jars into `tmp/formal/tools/`. Results go to `tmp/verify/formal/`. Neither directory is committed.

## What is modeled

The two models answer different questions.

- [Alloy](alloy/gravity.als) asks who can reach whom, who holds authority, which component enforces each boundary, and whether an escape can avoid the named trusted set.
- [TLA+](tla/GravityLifecycle.tla) asks whether partial provisioning, time, controller failure, revocation, deletion, observation, and retries can put a run into an unsafe lifecycle state.

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

- phase and immutable generation;
- deadline and logical time;
- resources believed present;
- deletion requests;
- externally confirmed absence;
- revocation requests and confirmed revocation;
- removal and provisioning failure;
- trusted local evidence;
- controller availability.

The phases are `Absent`, `Provisioning`, `Active`, `RemovalRequested`, `Expired`, `Revoking`, `Deleting`, `Verifying`, and `Removed`.

Deletion has three different facts: deletion was requested, the resource is no longer present, and an external observation confirmed absence. `Removed` requires the third. Revocation is modeled the same way.

Authority usability is derived from phase, deadline, and confirmed revocation. Advancing time beyond a deadline makes authority unusable without waiting for a controller action.

### Actions

The transition system includes starting a run, creating each resource in any order, activation, provisioning failure, requested removal, expiry, revocation, deletion, absence observation, final verification, evidence preservation, time advancement, controller crash, and controller resume.

The liveness configuration disables crashes and checks cleanup under an available controller. A crash configuration checks all safety invariants with controller loss and return. A reduced isolation configuration checks the same invariants across two interleaved runs. This separation keeps temporal and cross-run checking small while retaining crash states in safety exploration.

### Safety

TLC checks that:

- types remain valid;
- only a complete run becomes active;
- deadline expiry makes authority unusable;
- revocation is complete before deletion and cannot go backwards within a generation;
- a run's deadline cannot move within a generation;
- `Removed` means no resource remains and all absence is confirmed;
- removed runs have no authority;
- failed provisioning never becomes active;
- evidence remains run-scoped and monotonic;
- one transition cannot mutate two runs.

### Liveness

With weak or strong fairness for time, revocation, provider deletion, observation, and verification, TLC checks that:

- a removal request eventually reaches `Removed`;
- expiry eventually reaches confirmed revocation;
- failed provisioning eventually reaches `Removed`;
- a requested deletion eventually makes the resource absent.

These properties depend on SECURITY.md assumption A9. If the controller never returns or a provider never completes an accepted operation, full deletion cannot be guaranteed. Deadline-based loss of authority remains a safety property and does not use A9.

### Bounds

`GravityLifecycle.cfg` checks one run, three resource classes, two authority classes, a two-tick lease, and time through tick four. `GravityCrash.cfg` checks the same classes with controller crashes through tick three and no temporal properties. `GravityIsolation.cfg` checks two runs with one abstract chamber resource and one authority through tick two. Resources in the full models stand for the network, attacker, and target; authorities stand for inference and management.

The model deliberately collapses provider-specific resources. Implementation scenarios must enumerate instances, volumes, interfaces, endpoints, firewall resources, and keys.

## Traceability

| Claim | Security invariants | Alloy | TLA+ | Behavioral acceptance |
|---|---|---|---|---|
| G1 useful chamber | I3 | `UsefulChamberIsContained` | `ActiveImpliesComplete` | reference ARTEX/RubyGems.org canary and matching log |
| G2 root contained | I2, I7 | `TargetHasOnlyChamberPaths`, `NoGuestEnforcesPolicy` | authority derived outside guest state | root path and policy-replacement scenarios |
| G3 declared paths | I2–I5 | `ManagementIsInboundOnly`, `NoCrossChamberReachability` | run-scoped resource state | allowed and forbidden path scenarios |
| G4 bounded inference | I6, I8, I9 | `InferenceIsRunScoped` | `ExpiredAuthorityUnusable`, `RevocationMonotonic`, `DeadlineStable` | workspace, budget, expiry, and egress-evasion scenarios |
| G5 nothing valuable | I1 | `NoValuableGuestCapability` | authority classes only | credential and immutable-image scenarios |
| G6 inert output | I14 | outside the model | `EvidenceIsRunScoped`, `EvidenceMonotonic` | status and opaque-result scenarios |
| G7 expiry first | I8, I9 | capability scope | expiry and revocation properties | absent-controller and stale-operation scenarios |
| G8 proven teardown | I10–I13 | cross-chamber capability and path checks | removal safety, liveness, and `RunIsolation` | removal, partial failure, sweep, and observation scenarios |

## What these checks do not prove

They do not prove that AWS or OpenRouter satisfy A4 and A5, that cryptography holds, that the finite scope generalizes, that the model contains every relevant capability, or that future infrastructure code implements this design. They also do not assign a CVSS score to an unknown vulnerability.

Their purpose is narrower: make every trust assumption visible, find ordinary paths that avoid those assumptions, and reject lifecycle orderings that strand authority or declare cleanup early. Real-service feature scenarios close the model-to-implementation gap when the system is built.
