# Lifecycle

The TLA+ model checks, within finite bounds, that run-scoped operations, including delayed completions from older generations, cannot revive authority, mutate another run, or declare removal before observation.

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

## Verification

No task in this revision runs these models. The earlier verification harness is preserved at [archive/design-stack-before-spec-only](https://github.com/nateberkopec/dr-hands/tree/archive/design-stack-before-spec-only/formal). Its dependencies and evidence apply to that archived revision, not this checkout.

## Gotchas

The model collapses provider resources into finite classes and assumes provider progress for liveness. Crash safety is checked separately from cleanup liveness. Resource and authority classes are abstract; implementation scenarios enumerate their provider-specific members. A rejected operation is a modeled provider failure, not a model of every provider error. Evidence persistence is model state plus harness behavior; it is not cloud durability.
