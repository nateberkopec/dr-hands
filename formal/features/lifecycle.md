# Lifecycle

The TLA+ model proves that run-scoped operations, including delayed completions from older generations, cannot revive authority, mutate another run, or declare removal before observation.

## Sub-features

- `LC-1`: incomplete provisioning never activates.
- `LC-2`: provider operations carry immutable run and generation identities.
- `LC-3`: rejected operations can be retried.
- `LC-4`: stale creation and grant completions cannot attach to a later generation.
- `LC-5`: expiry makes authority unusable without controller progress.
- `LC-6`: revocation is monotonic during cleanup.
- `LC-7`: removal requires confirmed absence.
- `LC-8`: one operation can mutate only its requested run.
- `LC-9`: cleanup eventually finishes under the stated fairness assumption.
- `LC-10`: three unsafe lifecycle mutations produce failing traces.

## How to get to it (reviewer POV)

Read `formal/tla/GravityLifecycle.tla`, then the three normal configs. Read `GravityLifecycleMutations.tla` and its configs last; each mutation corresponds to one claimed detector.

## Driving it with the formal harness

Preconditions: `mise run verify-formal-doctor` passes.

- Run `mise run verify-formal`.
- Read `tla-lifecycle.log` for cleanup liveness.
- Read `tla-generation.log` for generation-two delayed-operation, rejection, and retry coverage.
- Read `tla-isolation.log` for two-run `RunIsolation` coverage.
- Read `tla-crash.log` for controller crash, resume, rejection, and retry coverage.
- Read each `mutation-*.log` for the named violated invariant or action property and the concrete trace.
- Read `summary.json` to confirm all critical actions were exercised.

## Gotchas

The model collapses provider resources into finite classes and assumes provider progress for liveness. Crash safety is checked separately from cleanup liveness. Resource and authority classes are abstract; implementation scenarios enumerate their provider-specific members. A rejected operation is a modeled provider failure, not a model of every provider error. Evidence persistence is model state plus harness behavior; it is not cloud durability.
