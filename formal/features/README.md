# Formal model map

These guides describe the restricted reference-gravity models and their evidence requirements. Read [the model guide](../README.md) for scope and limitations. The models do not establish public-browsing safety, sensitivity classification, or the lethal-trifecta policy.

No current task runs the models. The earlier harness and its integrity checks are preserved at [archive/design-stack-before-spec-only](https://github.com/nateberkopec/dr-hands/tree/archive/design-stack-before-spec-only/formal).

## Evidence requirements

- Require a useful architecture witness, not just an absence of counterexamples.
- Require a concrete witness or failing trace for each unsafe mutation.
- Require coverage of every critical lifecycle action.
- Read literal model-checker results, not just exit status.
- Preserve raw output, model/tool hashes, and the checked revision with each result.

## Models

- [Static trust boundary](static-trust-boundary.md): principals, paths, scoped authority, useful connectivity, and Alloy mutations.
- [Lifecycle](lifecycle.md): provisioning, delayed operations, generations, expiry, revocation, removal, crashes, and run isolation.
