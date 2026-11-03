# Harness integrity

The harness proves that the expected models ran with pinned tools, reads their actual output, preserves evidence, and demonstrates that unsafe controls fail.

## Sub-features

- `HI-1`: Alloy and TLC artifacts have pinned SHA-256 digests.
- `HI-2`: checksum command failure and digest mismatch fail closed.
- `HI-3`: doctor checks prerequisites without changing evidence.
- `HI-4`: each run gets an isolated evidence directory.
- `HI-5`: model-checker exit status and literal output are both checked.
- `HI-6`: critical action coverage is nonzero.
- `HI-7`: scratch state is cleaned and evidence remains.
- `HI-8`: summary JSON binds evidence to a git revision and artifact hashes.

## How to get to it (reviewer POV)

Read `formal/verify.fish`, `formal/lib.fish`, `formal/test-verify.fish`, and `formal/check_evidence.rb` in that order.

## Driving it with the formal harness

Preconditions: mise has installed Java, Fish, and Ruby.

- Run `mise run verify-formal-doctor`; it must not create a new evidence directory.
- Run `DR_HANDS_VERIFY_RUN=review mise run verify-formal` once in a clean evidence root.
- Run the same command again; it must refuse to overwrite the first proof.
- Read `tmp/verify/formal/review/SUMMARY.md`, then inspect the raw artifacts it names.
- Confirm no `dr-hands-formal-states` directory remains under `/tmp` for the finished process.

## Gotchas

The tool cache is mutable only through checksum-verified replacement and is not proof. An explicit run ID must contain only safe filename characters. CI uploads the evidence directory, but local evidence remains only under `tmp/` and is not committed.
