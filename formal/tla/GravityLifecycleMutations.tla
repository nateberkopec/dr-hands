--------------------- MODULE GravityLifecycleMutations ---------------------
EXTENDS GravityLifecycle

CONSTANT MutationKind

UnsafePrematureRemoval(run) ==
  /\ phase[run] = "Active"
  /\ phase' = [phase EXCEPT ![run] = "Removed"]
  /\ stepTarget' = run
  /\ UNCHANGED <<generation, deadline, present, resourceGeneration,
                  deleteRequested, confirmedAbsent, revokeRequested,
                  revoked, authorityGeneration, removalRequested, failed,
                  evidence, now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke, pendingDelete>>

UnsafeWrongRunDelete(operation, victim) ==
  LET requestedRun == OpRun(operation) IN
  LET resource == OpMember(operation) IN
  /\ operation \in pendingDelete
  /\ victim \in Runs \ {requestedRun}
  /\ resource \in present[victim]
  /\ pendingDelete' = pendingDelete \ {operation}
  /\ present' = [present EXCEPT ![victim] = @ \ {resource}]
  /\ resourceGeneration' =
       [resourceGeneration EXCEPT ![victim][resource] = 0]
  /\ stepTarget' = requestedRun
  /\ UNCHANGED <<phase, generation, deadline, deleteRequested,
                  confirmedAbsent, revokeRequested, revoked,
                  authorityGeneration, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingGrant,
                  pendingRevoke>>

UnsafeStaleGrant(operation) ==
  LET run == OpRun(operation) IN
  LET operationGeneration == OpGeneration(operation) IN
  LET authority == OpMember(operation) IN
  /\ operation \in pendingGrant
  /\ operationGeneration /= generation[run]
  /\ authority \in revoked[run]
  /\ pendingGrant' = pendingGrant \ {operation}
  /\ revoked' = [revoked EXCEPT ![run] = @ \ {authority}]
  /\ authorityGeneration' =
       [authorityGeneration EXCEPT
         ![run][authority] = operationGeneration]
  /\ stepTarget' = run
  /\ UNCHANGED <<phase, generation, deadline, present,
                  resourceGeneration, deleteRequested, confirmedAbsent,
                  revokeRequested, removalRequested, failed, evidence,
                  now, controllerUp, pendingCreate, pendingRevoke,
                  pendingDelete>>

MutationNext ==
  \/ Next
  \/ CASE MutationKind = "premature-removal" ->
            \E run \in Runs: UnsafePrematureRemoval(run)
       [] MutationKind = "wrong-run-delete" ->
            \E operation \in CreateOperations, victim \in Runs:
              UnsafeWrongRunDelete(operation, victim)
       [] MutationKind = "stale-grant" ->
            \E operation \in AuthorityOperations:
              UnsafeStaleGrant(operation)
       [] OTHER -> FALSE

MutantSpec == Init /\ [][MutationNext]_vars

=============================================================================
