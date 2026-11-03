------------------------- MODULE GravityLifecycle -------------------------
EXTENDS Integers, FiniteSets, TLC

CONSTANTS Runs, Resources, Authorities, Lease, MaxTime, MaxGeneration,
          AllowCrash, AllowReject, NoRun

Phases == {"Absent", "Provisioning", "Active", "RemovalRequested",
           "Expired", "Revoking", "Deleting", "Verifying", "Removed"}
Generations == 1..MaxGeneration
CreateOperations == Runs \X Generations \X Resources
AuthorityOperations == Runs \X Generations \X Authorities

VARIABLES phase, generation, deadline, present, resourceGeneration,
          deleteRequested, confirmedAbsent, revokeRequested, revoked,
          authorityGeneration, removalRequested, failed, evidence, now,
          controllerUp, pendingCreate, pendingGrant, pendingRevoke,
          pendingDelete, stepTarget

vars == <<phase, generation, deadline, present, resourceGeneration,
          deleteRequested, confirmedAbsent, revokeRequested, revoked,
          authorityGeneration, removalRequested, failed, evidence, now,
          controllerUp, pendingCreate, pendingGrant, pendingRevoke,
          pendingDelete, stepTarget>>

OpRun(operation) == operation[1]
OpGeneration(operation) == operation[2]
OpMember(operation) == operation[3]

AuthorityUsable(run, authority) ==
  /\ authority \in Authorities
  /\ authority \notin revoked[run]
  /\ authorityGeneration[run][authority] = generation[run]
  /\ now < deadline[run]
  /\ phase[run] \in {"Provisioning", "Active"}

Init ==
  /\ phase = [run \in Runs |-> "Absent"]
  /\ generation = [run \in Runs |-> 0]
  /\ deadline = [run \in Runs |-> 0]
  /\ present = [run \in Runs |-> {}]
  /\ resourceGeneration =
       [run \in Runs |-> [resource \in Resources |-> 0]]
  /\ deleteRequested = [run \in Runs |-> {}]
  /\ confirmedAbsent = [run \in Runs |-> Resources]
  /\ revokeRequested = [run \in Runs |-> {}]
  /\ revoked = [run \in Runs |-> Authorities]
  /\ authorityGeneration =
       [run \in Runs |-> [authority \in Authorities |-> 0]]
  /\ removalRequested = {}
  /\ failed = {}
  /\ evidence = {}
  /\ now = 0
  /\ controllerUp = TRUE
  /\ pendingCreate = {}
  /\ pendingGrant = {}
  /\ pendingRevoke = {}
  /\ pendingDelete = {}
  /\ stepTarget = NoRun

Start(run) ==
  LET nextGeneration == generation[run] + 1 IN
  /\ controllerUp
  /\ phase[run] \in {"Absent", "Removed"}
  /\ generation[run] < MaxGeneration
  /\ phase' = [phase EXCEPT ![run] = "Provisioning"]
  /\ generation' = [generation EXCEPT ![run] = nextGeneration]
  /\ deadline' = [deadline EXCEPT ![run] = now + Lease]
  /\ present' = [present EXCEPT ![run] = {}]
  /\ resourceGeneration' =
       [resourceGeneration EXCEPT
         ![run] = [resource \in Resources |-> 0]]
  /\ deleteRequested' = [deleteRequested EXCEPT ![run] = {}]
  /\ confirmedAbsent' = [confirmedAbsent EXCEPT ![run] = Resources]
  /\ revokeRequested' = [revokeRequested EXCEPT ![run] = {}]
  /\ revoked' = [revoked EXCEPT ![run] = Authorities]
  /\ authorityGeneration' =
       [authorityGeneration EXCEPT
         ![run] = [authority \in Authorities |-> 0]]
  /\ removalRequested' = removalRequested \ {run}
  /\ failed' = failed \ {run}
  /\ stepTarget' = run
  /\ UNCHANGED <<evidence, now, controllerUp, pendingCreate,
                  pendingGrant, pendingRevoke, pendingDelete>>

RequestCreate(run, resource) ==
  LET operation == <<run, generation[run], resource>> IN
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ resource \in Resources \ present[run]
  /\ operation \notin pendingCreate
  /\ pendingCreate' = pendingCreate \cup {operation}
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingGrant, pendingRevoke, pendingDelete>>

CompleteCreate(operation) ==
  LET run == OpRun(operation) IN
  LET operationGeneration == OpGeneration(operation) IN
  LET resource == OpMember(operation) IN
  LET current ==
    operationGeneration = generation[run] /\ phase[run] = "Provisioning"
  IN
  /\ operation \in pendingCreate
  /\ pendingCreate' = pendingCreate \ {operation}
  /\ present' =
       IF current
       THEN [present EXCEPT ![run] = @ \cup {resource}]
       ELSE present
  /\ resourceGeneration' =
       IF current
       THEN [resourceGeneration EXCEPT
              ![run][resource] = operationGeneration]
       ELSE resourceGeneration
  /\ confirmedAbsent' =
       IF current
       THEN [confirmedAbsent EXCEPT ![run] = @ \ {resource}]
       ELSE confirmedAbsent
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, deleteRequested,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingGrant, pendingRevoke, pendingDelete>>

CompleteCurrentCreate(operation) ==
  /\ OpGeneration(operation) = generation[OpRun(operation)]
  /\ phase[OpRun(operation)] = "Provisioning"
  /\ CompleteCreate(operation)

CompleteStaleCreate(operation) ==
  /\ ~(OpGeneration(operation) = generation[OpRun(operation)]
       /\ phase[OpRun(operation)] = "Provisioning")
  /\ CompleteCreate(operation)

RejectCreate(operation) ==
  /\ AllowReject
  /\ operation \in pendingCreate
  /\ pendingCreate' = pendingCreate \ {operation}
  /\ stepTarget' = OpRun(operation)
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingGrant, pendingRevoke, pendingDelete>>

RequestGrant(run, authority) ==
  LET operation == <<run, generation[run], authority>> IN
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ authority \in revoked[run]
  /\ operation \notin pendingGrant
  /\ pendingGrant' = pendingGrant \cup {operation}
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingRevoke, pendingDelete>>

CompleteGrant(operation) ==
  LET run == OpRun(operation) IN
  LET operationGeneration == OpGeneration(operation) IN
  LET authority == OpMember(operation) IN
  LET current ==
    operationGeneration = generation[run] /\ phase[run] = "Provisioning"
  IN
  /\ operation \in pendingGrant
  /\ pendingGrant' = pendingGrant \ {operation}
  /\ revoked' =
       IF current
       THEN [revoked EXCEPT ![run] = @ \ {authority}]
       ELSE revoked
  /\ authorityGeneration' =
       IF current
       THEN [authorityGeneration EXCEPT
              ![run][authority] = operationGeneration]
       ELSE authorityGeneration
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingRevoke,
                  pendingDelete>>

CompleteCurrentGrant(operation) ==
  /\ OpGeneration(operation) = generation[OpRun(operation)]
  /\ phase[OpRun(operation)] = "Provisioning"
  /\ CompleteGrant(operation)

CompleteStaleGrant(operation) ==
  /\ ~(OpGeneration(operation) = generation[OpRun(operation)]
       /\ phase[OpRun(operation)] = "Provisioning")
  /\ CompleteGrant(operation)

RejectGrant(operation) ==
  /\ AllowReject
  /\ operation \in pendingGrant
  /\ pendingGrant' = pendingGrant \ {operation}
  /\ stepTarget' = OpRun(operation)
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingRevoke, pendingDelete>>

Activate(run) ==
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ present[run] = Resources
  /\ revoked[run] = {}
  /\ run \notin failed
  /\ now < deadline[run]
  /\ phase' = [phase EXCEPT ![run] = "Active"]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, removalRequested, failed,
                  evidence, now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

FailProvisioning(run) ==
  /\ controllerUp
  /\ phase[run] = "Provisioning"
  /\ phase' = [phase EXCEPT ![run] = "RemovalRequested"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ failed' = failed \cup {run}
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, evidence, now,
                  controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

RequestRemoval(run) ==
  /\ controllerUp
  /\ phase[run] \in {"Provisioning", "Active"}
  /\ phase' = [phase EXCEPT ![run] = "RemovalRequested"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, failed, evidence, now,
                  controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

Expire(run) ==
  /\ phase[run] \in {"Provisioning", "Active"}
  /\ now >= deadline[run]
  /\ phase' = [phase EXCEPT ![run] = "Expired"]
  /\ removalRequested' = removalRequested \cup {run}
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, failed, evidence, now,
                  controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

BeginRevocation(run) ==
  /\ controllerUp
  /\ run \in removalRequested
  /\ phase[run] \in {"RemovalRequested", "Expired"}
  /\ phase' = [phase EXCEPT ![run] = "Revoking"]
  /\ revokeRequested' = [revokeRequested EXCEPT ![run] = Authorities]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revoked,
                  authorityGeneration, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

RequestRevoke(run, authority) ==
  LET operation == <<run, generation[run], authority>> IN
  /\ controllerUp
  /\ phase[run] = "Revoking"
  /\ authority \in revokeRequested[run] \ revoked[run]
  /\ operation \notin pendingRevoke
  /\ pendingRevoke' = pendingRevoke \cup {operation}
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingGrant, pendingDelete>>

CompleteRevoke(operation) ==
  LET run == OpRun(operation) IN
  LET operationGeneration == OpGeneration(operation) IN
  LET authority == OpMember(operation) IN
  LET current ==
    operationGeneration = generation[run] /\ phase[run] = "Revoking"
  IN
  /\ operation \in pendingRevoke
  /\ pendingRevoke' = pendingRevoke \ {operation}
  /\ revoked' =
       IF current
       THEN [revoked EXCEPT ![run] = @ \cup {authority}]
       ELSE revoked
  /\ authorityGeneration' =
       IF current
       THEN [authorityGeneration EXCEPT ![run][authority] = 0]
       ELSE authorityGeneration
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingGrant,
                  pendingDelete>>

RejectRevoke(operation) ==
  /\ AllowReject
  /\ operation \in pendingRevoke
  /\ pendingRevoke' = pendingRevoke \ {operation}
  /\ stepTarget' = OpRun(operation)
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingGrant, pendingDelete>>

BeginDeletion(run) ==
  /\ controllerUp
  /\ phase[run] = "Revoking"
  /\ revoked[run] = Authorities
  /\ phase' = [phase EXCEPT ![run] = "Deleting"]
  /\ deleteRequested' = [deleteRequested EXCEPT ![run] = present[run]]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  confirmedAbsent, revokeRequested, revoked,
                  authorityGeneration, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

RequestDelete(run, resource) ==
  LET operation == <<run, generation[run], resource>> IN
  /\ controllerUp
  /\ phase[run] = "Deleting"
  /\ resource \in deleteRequested[run] \cap present[run]
  /\ operation \notin pendingDelete
  /\ pendingDelete' = pendingDelete \cup {operation}
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingGrant, pendingRevoke>>

CompleteDelete(operation) ==
  LET run == OpRun(operation) IN
  LET operationGeneration == OpGeneration(operation) IN
  LET resource == OpMember(operation) IN
  LET current ==
    operationGeneration = generation[run] /\ phase[run] = "Deleting"
  IN
  /\ operation \in pendingDelete
  /\ pendingDelete' = pendingDelete \ {operation}
  /\ present' =
       IF current
       THEN [present EXCEPT ![run] = @ \ {resource}]
       ELSE present
  /\ resourceGeneration' =
       IF current
       THEN [resourceGeneration EXCEPT ![run][resource] = 0]
       ELSE resourceGeneration
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  authorityGeneration, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke>>

RejectDelete(operation) ==
  /\ AllowReject
  /\ operation \in pendingDelete
  /\ pendingDelete' = pendingDelete \ {operation}
  /\ stepTarget' = OpRun(operation)
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, controllerUp,
                  pendingCreate, pendingGrant, pendingRevoke>>

ObserveAbsent(run, resource) ==
  /\ controllerUp
  /\ resource \in Resources \ present[run]
  /\ resource \notin confirmedAbsent[run]
  /\ confirmedAbsent' = [confirmedAbsent EXCEPT ![run] = @ \cup {resource}]
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, revokeRequested,
                  revoked, authorityGeneration, removalRequested, failed,
                  evidence, now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

BeginVerification(run) ==
  /\ controllerUp
  /\ phase[run] = "Deleting"
  /\ present[run] = {}
  /\ phase' = [phase EXCEPT ![run] = "Verifying"]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, removalRequested, failed,
                  evidence, now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

VerifyRemoved(run) ==
  /\ controllerUp
  /\ phase[run] = "Verifying"
  /\ confirmedAbsent[run] = Resources
  /\ revoked[run] = Authorities
  /\ present[run] = {}
  /\ phase' = [phase EXCEPT ![run] = "Removed"]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, removalRequested, failed,
                  evidence, now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

PreserveEvidence(run) ==
  /\ controllerUp
  /\ phase[run] \in {"Active", "RemovalRequested", "Expired",
                      "Revoking", "Deleting", "Verifying"}
  /\ run \notin evidence
  /\ evidence' = evidence \cup {run}
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, now, controllerUp,
                  pendingCreate, pendingGrant, pendingRevoke,
                  pendingDelete>>

AdvanceTime ==
  /\ now < MaxTime
  /\ now' = now + 1
  /\ stepTarget' = NoRun
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, controllerUp,
                  pendingCreate, pendingGrant, pendingRevoke,
                  pendingDelete>>

ControllerCrash ==
  /\ AllowCrash
  /\ controllerUp
  /\ controllerUp' = FALSE
  /\ stepTarget' = NoRun
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, pendingCreate,
                  pendingGrant, pendingRevoke, pendingDelete>>

ControllerResume ==
  /\ ~controllerUp
  /\ controllerUp' = TRUE
  /\ stepTarget' = NoRun
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, revoked, authorityGeneration,
                  removalRequested, failed, evidence, now, pendingCreate,
                  pendingGrant, pendingRevoke, pendingDelete>>

Next ==
  \/ \E run \in Runs: Start(run)
  \/ \E run \in Runs, resource \in Resources: RequestCreate(run, resource)
  \/ \E operation \in CreateOperations: CompleteCurrentCreate(operation)
  \/ \E operation \in CreateOperations: CompleteStaleCreate(operation)
  \/ \E operation \in CreateOperations: RejectCreate(operation)
  \/ \E run \in Runs, authority \in Authorities: RequestGrant(run, authority)
  \/ \E operation \in AuthorityOperations: CompleteCurrentGrant(operation)
  \/ \E operation \in AuthorityOperations: CompleteStaleGrant(operation)
  \/ \E operation \in AuthorityOperations: RejectGrant(operation)
  \/ \E run \in Runs: Activate(run)
  \/ \E run \in Runs: FailProvisioning(run)
  \/ \E run \in Runs: RequestRemoval(run)
  \/ \E run \in Runs: Expire(run)
  \/ \E run \in Runs: BeginRevocation(run)
  \/ \E run \in Runs, authority \in Authorities: RequestRevoke(run, authority)
  \/ \E operation \in AuthorityOperations: CompleteRevoke(operation)
  \/ \E operation \in AuthorityOperations: RejectRevoke(operation)
  \/ \E run \in Runs: BeginDeletion(run)
  \/ \E run \in Runs, resource \in Resources: RequestDelete(run, resource)
  \/ \E operation \in CreateOperations: CompleteDelete(operation)
  \/ \E operation \in CreateOperations: RejectDelete(operation)
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
       /\ \A authority \in Authorities:
            /\ SF_vars(RequestRevoke(run, authority))
            /\ SF_vars(CompleteRevoke(
                 <<run, generation[run], authority>>))
       /\ \A resource \in Resources:
            /\ SF_vars(RequestDelete(run, resource))
            /\ SF_vars(CompleteDelete(
                 <<run, generation[run], resource>>))
            /\ SF_vars(ObserveAbsent(run, resource))

Spec == Init /\ [][Next]_vars /\ Fairness

TypeOK ==
  /\ phase \in [Runs -> Phases]
  /\ generation \in [Runs -> 0..MaxGeneration]
  /\ deadline \in [Runs -> Nat]
  /\ present \in [Runs -> SUBSET Resources]
  /\ resourceGeneration \in
       [Runs -> [Resources -> 0..MaxGeneration]]
  /\ deleteRequested \in [Runs -> SUBSET Resources]
  /\ confirmedAbsent \in [Runs -> SUBSET Resources]
  /\ revokeRequested \in [Runs -> SUBSET Authorities]
  /\ revoked \in [Runs -> SUBSET Authorities]
  /\ authorityGeneration \in
       [Runs -> [Authorities -> 0..MaxGeneration]]
  /\ removalRequested \subseteq Runs
  /\ failed \subseteq Runs
  /\ evidence \subseteq Runs
  /\ now \in 0..MaxTime
  /\ controllerUp \in BOOLEAN
  /\ AllowReject \in BOOLEAN
  /\ pendingCreate \subseteq CreateOperations
  /\ pendingGrant \subseteq AuthorityOperations
  /\ pendingRevoke \subseteq AuthorityOperations
  /\ pendingDelete \subseteq CreateOperations
  /\ stepTarget \in Runs \cup {NoRun}
  /\ NoRun \notin Runs

ActiveImpliesComplete ==
  \A run \in Runs:
    phase[run] = "Active" =>
      /\ present[run] = Resources
      /\ revoked[run] = {}

IncompleteNeverActive ==
  \A run \in Runs:
    present[run] /= Resources => phase[run] /= "Active"

NoStaleAttachment ==
  /\ \A run \in Runs:
       \A resource \in present[run]:
         resourceGeneration[run][resource] = generation[run]
  /\ \A run \in Runs:
       \A authority \in Authorities \ revoked[run]:
         authorityGeneration[run][authority] = generation[run]

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
    phase[run] \in {"Revoking", "Deleting", "Verifying", "Removed"}
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
  \A run \in Runs: generation[run] \in 0..MaxGeneration

PendingFor(run, operations) ==
  {operation \in operations: OpRun(operation) = run}

RunState(run) ==
  <<phase[run], generation[run], deadline[run], present[run],
    resourceGeneration[run], deleteRequested[run], confirmedAbsent[run],
    revokeRequested[run], revoked[run], authorityGeneration[run],
    run \in removalRequested, run \in failed, run \in evidence,
    PendingFor(run, pendingCreate), PendingFor(run, pendingGrant),
    PendingFor(run, pendingRevoke), PendingFor(run, pendingDelete)>>

RunScopedStep ==
  \A run \in Runs:
    RunState(run)' /= RunState(run) => stepTarget' = run

RunIsolation == [][RunScopedStep]_vars

NoAuthorityAfterRemoval ==
  \A run \in Runs:
    phase[run] = "Removed" =>
      \A authority \in Authorities: ~AuthorityUsable(run, authority)

FailedProvisioningNotUsable ==
  \A run \in failed: phase[run] /= "Active"
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
