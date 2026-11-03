------------------------- MODULE GravityLifecycle -------------------------
EXTENDS Integers, FiniteSets, TLC

CONSTANTS Runs, Resources, Authorities, Lease, MaxTime, AllowCrash

Phases == {"Absent", "Provisioning", "Active", "RemovalRequested",
           "Expired", "Revoking", "Deleting", "Verifying", "Removed"}

VARIABLES phase, generation, deadline, present, deleteRequested,
          confirmedAbsent, revokeRequested, revoked, removalRequested,
          failed, evidence, now, controllerUp

vars == <<phase, generation, deadline, present, deleteRequested,
          confirmedAbsent, revokeRequested, revoked, removalRequested,
          failed, evidence, now, controllerUp>>

AuthorityUsable(run, authority) ==
  /\ authority \in Authorities
  /\ authority \notin revoked[run]
  /\ now < deadline[run]
  /\ phase[run] \in {"Provisioning", "Active"}

Init ==
  /\ phase = [run \in Runs |-> "Absent"]
  /\ generation = [run \in Runs |-> 0]
  /\ deadline = [run \in Runs |-> 0]
  /\ present = [run \in Runs |-> {}]
  /\ deleteRequested = [run \in Runs |-> {}]
  /\ confirmedAbsent = [run \in Runs |-> Resources]
  /\ revokeRequested = [run \in Runs |-> {}]
  /\ revoked = [run \in Runs |-> Authorities]
  /\ removalRequested = {}
  /\ failed = {}
  /\ evidence = {}
  /\ now = 0
  /\ controllerUp = TRUE

Start(run) ==
  /\ controllerUp
  /\ phase[run] = "Absent"
  /\ phase' = [phase EXCEPT ![run] = "Provisioning"]
  /\ generation' = [generation EXCEPT ![run] = 1]
  /\ deadline' = [deadline EXCEPT ![run] = now + Lease]
  /\ present' = [present EXCEPT ![run] = {}]
  /\ deleteRequested' = [deleteRequested EXCEPT ![run] = {}]
  /\ confirmedAbsent' = [confirmedAbsent EXCEPT ![run] = Resources]
  /\ revokeRequested' = [revokeRequested EXCEPT ![run] = {}]
  /\ revoked' = [revoked EXCEPT ![run] = {}]
  /\ removalRequested' = removalRequested \ {run}
  /\ failed' = failed \ {run}
  /\ UNCHANGED <<evidence, now, controllerUp>>

CreateResource(run, resource) ==
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ resource \in Resources \ present[run]
  /\ present' = [present EXCEPT ![run] = @ \cup {resource}]
  /\ confirmedAbsent' = [confirmedAbsent EXCEPT ![run] = @ \ {resource}]
  /\ UNCHANGED <<phase, generation, deadline, deleteRequested,
                  revokeRequested, revoked, removalRequested, failed,
                  evidence, now, controllerUp>>

Activate(run) ==
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ present[run] = Resources
  /\ run \notin failed
  /\ now < deadline[run]
  /\ phase' = [phase EXCEPT ![run] = "Active"]
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now, controllerUp>>

FailProvisioning(run) ==
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ phase' = [phase EXCEPT ![run] = "RemovalRequested"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ failed' = failed \cup {run}
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked, evidence,
                  now, controllerUp>>

RequestRemoval(run) ==
  /\ controllerUp
  /\ phase[run] \in {"Provisioning", "Active"}
  /\ phase' = [phase EXCEPT ![run] = "RemovalRequested"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked, failed,
                  evidence, now, controllerUp>>

Expire(run) ==
  /\ phase[run] \in {"Provisioning", "Active"}
  /\ now >= deadline[run]
  /\ phase' = [phase EXCEPT ![run] = "Expired"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked, failed,
                  evidence, now, controllerUp>>

BeginRevocation(run) ==
  /\ controllerUp
  /\ run \in removalRequested
  /\ phase[run] \in {"RemovalRequested", "Expired"}
  /\ phase' = [phase EXCEPT ![run] = "Revoking"]
  /\ revokeRequested' = [revokeRequested EXCEPT ![run] = Authorities]
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revoked, removalRequested, failed,
                  evidence, now, controllerUp>>

ConfirmRevoked(run, authority) ==
  /\ controllerUp
  /\ authority \in revokeRequested[run] \ revoked[run]
  /\ revoked' = [revoked EXCEPT ![run] = @ \cup {authority}]
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, removalRequested,
                  failed, evidence, now, controllerUp>>

BeginDeletion(run) ==
  /\ controllerUp
  /\ phase[run] = "Revoking"
  /\ revoked[run] = Authorities
  /\ phase' = [phase EXCEPT ![run] = "Deleting"]
  /\ deleteRequested' = [deleteRequested EXCEPT ![run] = present[run]]
  /\ UNCHANGED <<generation, deadline, present, confirmedAbsent,
                  revokeRequested, revoked, removalRequested, failed,
                  evidence, now, controllerUp>>

DeleteResource(run, resource) ==
  /\ resource \in deleteRequested[run] \cap present[run]
  /\ present' = [present EXCEPT ![run] = @ \ {resource}]
  /\ UNCHANGED <<phase, generation, deadline, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now, controllerUp>>

ObserveAbsent(run, resource) ==
  /\ controllerUp
  /\ resource \in Resources \ present[run]
  /\ resource \notin confirmedAbsent[run]
  /\ confirmedAbsent' = [confirmedAbsent EXCEPT ![run] = @ \cup {resource}]
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  revokeRequested, revoked, removalRequested, failed,
                  evidence, now, controllerUp>>

BeginVerification(run) ==
  /\ controllerUp
  /\ phase[run] = "Deleting"
  /\ present[run] = {}
  /\ phase' = [phase EXCEPT ![run] = "Verifying"]
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now, controllerUp>>

VerifyRemoved(run) ==
  /\ controllerUp
  /\ phase[run] = "Verifying"
  /\ confirmedAbsent[run] = Resources
  /\ revoked[run] = Authorities
  /\ present[run] = {}
  /\ phase' = [phase EXCEPT ![run] = "Removed"]
  /\ UNCHANGED <<generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now, controllerUp>>

PreserveEvidence(run) ==
  /\ controllerUp
  /\ phase[run] \in {"Active", "RemovalRequested", "Expired",
                      "Revoking", "Deleting", "Verifying"}
  /\ run \notin evidence
  /\ evidence' = evidence \cup {run}
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, now, controllerUp>>

AdvanceTime ==
  /\ now < MaxTime
  /\ now' = now + 1
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, controllerUp>>

ControllerCrash ==
  /\ AllowCrash
  /\ controllerUp
  /\ controllerUp' = FALSE
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now>>

ControllerResume ==
  /\ ~controllerUp
  /\ controllerUp' = TRUE
  /\ UNCHANGED <<phase, generation, deadline, present, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  removalRequested, failed, evidence, now>>

Next ==
  \/ \E run \in Runs: Start(run)
  \/ \E run \in Runs, resource \in Resources: CreateResource(run, resource)
  \/ \E run \in Runs: Activate(run)
  \/ \E run \in Runs: FailProvisioning(run)
  \/ \E run \in Runs: RequestRemoval(run)
  \/ \E run \in Runs: Expire(run)
  \/ \E run \in Runs: BeginRevocation(run)
  \/ \E run \in Runs, authority \in Authorities:
       ConfirmRevoked(run, authority)
  \/ \E run \in Runs: BeginDeletion(run)
  \/ \E run \in Runs, resource \in Resources: DeleteResource(run, resource)
  \/ \E run \in Runs, resource \in Resources: ObserveAbsent(run, resource)
  \/ \E run \in Runs: BeginVerification(run)
  \/ \E run \in Runs: VerifyRemoved(run)
  \/ \E run \in Runs: PreserveEvidence(run)
  \/ AdvanceTime
  \/ ControllerCrash
  \/ ControllerResume

Fairness ==
  /\ WF_vars(AdvanceTime)
  /\ WF_vars(ControllerResume)
  /\ \A run \in Runs:
       /\ WF_vars(Expire(run))
       /\ SF_vars(BeginRevocation(run))
       /\ SF_vars(BeginDeletion(run))
       /\ SF_vars(BeginVerification(run))
       /\ SF_vars(VerifyRemoved(run))
       /\ \A authority \in Authorities: SF_vars(ConfirmRevoked(run, authority))
       /\ \A resource \in Resources:
            /\ WF_vars(DeleteResource(run, resource))
            /\ SF_vars(ObserveAbsent(run, resource))

Spec == Init /\ [][Next]_vars /\ Fairness

TypeOK ==
  /\ phase \in [Runs -> Phases]
  /\ generation \in [Runs -> 0..1]
  /\ deadline \in [Runs -> Nat]
  /\ present \in [Runs -> SUBSET Resources]
  /\ deleteRequested \in [Runs -> SUBSET Resources]
  /\ confirmedAbsent \in [Runs -> SUBSET Resources]
  /\ revokeRequested \in [Runs -> SUBSET Authorities]
  /\ revoked \in [Runs -> SUBSET Authorities]
  /\ removalRequested \subseteq Runs
  /\ failed \subseteq Runs
  /\ evidence \subseteq Runs
  /\ now \in 0..MaxTime
  /\ controllerUp \in BOOLEAN
  /\ AllowCrash \in BOOLEAN

ActiveImpliesComplete ==
  \A run \in Runs:
    phase[run] = "Active" => present[run] = Resources

IncompleteNeverActive ==
  \A run \in Runs:
    present[run] /= Resources => phase[run] /= "Active"

ExpiredAuthorityUnusable ==
  \A run \in Runs:
    now >= deadline[run] =>
      \A authority \in Authorities: ~AuthorityUsable(run, authority)

RevokedBeforeDeletion ==
  \A run \in Runs:
    phase[run] \in {"Deleting", "Verifying", "Removed"} =>
      revoked[run] = Authorities

RevocationMonotonicStep ==
  \A run \in Runs:
    generation'[run] = generation[run]
      => revoked[run] \subseteq revoked'[run]

RevocationMonotonic == [][RevocationMonotonicStep]_vars

EvidenceMonotonic == [][evidence \subseteq evidence']_vars

DeadlineStableStep ==
  \A run \in Runs:
    generation'[run] = generation[run]
      => deadline'[run] = deadline[run]

DeadlineStable == [][DeadlineStableStep]_vars

RemovedImpliesNothingRemote ==
  \A run \in Runs:
    phase[run] = "Removed" =>
      /\ present[run] = {}
      /\ revoked[run] = Authorities
      /\ confirmedAbsent[run] = Resources

RemovalRequiresObservation ==
  \A run \in Runs:
    phase[run] = "Removed" => confirmedAbsent[run] = Resources

GenerationBounded ==
  \A run \in Runs: generation[run] \in 0..1

RunState(run) ==
  <<phase[run], generation[run], deadline[run], present[run],
    deleteRequested[run], confirmedAbsent[run], revokeRequested[run],
    revoked[run], run \in removalRequested, run \in failed,
    run \in evidence>>

RunIsolationStep ==
  \A left, right \in Runs:
    left /= right /\ RunState(left)' /= RunState(left)
      => RunState(right)' = RunState(right)

RunIsolation == [][RunIsolationStep]_vars

NoAuthorityAfterRemoval ==
  \A run \in Runs:
    phase[run] = "Removed" =>
      \A authority \in Authorities: ~AuthorityUsable(run, authority)

FailedProvisioningNotUsable ==
  \A run \in failed:
    phase[run] /= "Active"

EvidenceIsRunScoped == evidence \subseteq Runs

RemovalRequestedLeadsToRemoved ==
  \A run \in Runs:
    (run \in removalRequested) ~> (phase[run] = "Removed")

ExpiredLeadsToRevoked ==
  \A run \in Runs:
    (phase[run] = "Expired") ~> (revoked[run] = Authorities)

FailedLeadsToRemoved ==
  \A run \in Runs:
    (run \in failed) ~> (phase[run] = "Removed")

DeleteRequestedLeadsAbsent ==
  \A run \in Runs, resource \in Resources:
    (resource \in deleteRequested[run]) ~> (resource \notin present[run])

=============================================================================
