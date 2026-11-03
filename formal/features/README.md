# Formal proof map

This directory is the maintained source for driving and reviewing Gravity's formal claims. Read this index after `formal/README.md`, then use the matching feature file to inspect the model and its evidence.

## Baseline preconditions

- Run from a clean dr-hands checkout with mise-installed Java, Fish, and Ruby.
- Run `mise run verify-formal-doctor` before investigating a surprising result.
- Treat `tmp/formal/tools/` as a checksum-verified cache, not evidence.
- Give concurrent runs different `DR_HANDS_VERIFY_RUN` values.
- Never delete an earlier evidence directory to make a later run pass.

## Proof conventions

- A useful architecture witness must exist; absence of counterexamples alone is insufficient.
- Every unsafe mutation must produce a concrete witness or failing TLC trace.
- Every critical lifecycle action must have nonzero TLC coverage.
- The harness reads model-checker output back and asserts literal results.
- Evidence includes the git revision, raw logs, Alloy receipt, summary, and artifact hashes.
- Scratch state is removed after a run; evidence is not.

## Features

- [Static trust boundary](static-trust-boundary.md) covers principals, paths, capability scope, useful connectivity, and Alloy mutations.
- [Lifecycle](lifecycle.md) covers provisioning, retries, delayed completions, generations, expiry, revocation, teardown, crashes, and run isolation.
- [Harness integrity](harness-integrity.md) covers pinned tools, doctor checks, negative controls, read-back, evidence, and cleanup.
