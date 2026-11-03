# Static trust boundary

The Alloy model proves that useful attacker and target roles fit inside the named trust cut without an ordinary path to protected principals or another chamber.

## Sub-features

- `ST-1`: a useful chamber reaches its target and OpenRouter.
- `ST-2`: management is inbound only.
- `ST-3`: valuable authority never belongs to a guest.
- `ST-4`: inference authority and network paths are chamber-scoped.
- `ST-5`: policy enforcement stays outside guests.
- `ST-6`: every modeled escape requires a named trusted failure.
- `ST-7`: five known-bad architectures remain satisfiable witnesses.

## How to get to it (reviewer POV)

Start with `formal/alloy/gravity.als`. Read `CommonShape`, `SafeArchitecture`, `effectiveNetwork`, and `Escapes`, then read assertions before mutation predicates.

## Driving it with the formal harness

Preconditions: `mise run verify-formal-doctor` passes.

- Run `mise run verify-formal`.
- Open the printed evidence directory.
- Read `alloy.log` for one intended `SAT`, nine assertion `UNSAT` results, and five mutation `SAT` results.
- Read `alloy/receipt.json` for the concrete instances.
- Read `summary.json` to confirm the harness independently recognized the exact command set and key mutation edges.

## Gotchas

Alloy is bounded to two chambers. `TrustedSetIsNamed` limits modeled principals, not provider internals. A mutation witness proves model sensitivity only for that mutation. None of these checks proves Terraform implements the relation.
