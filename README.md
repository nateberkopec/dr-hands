# dr-hands

This repository is a specification, not an implementation.

Investigate hostile reports and exercise attacker frameworks against disposable targets without putting your workstation inside the run.

## Operators use the CLI; workflows use library APIs

The operator asks dr-hands to lint, diagnose, preview, provision, or run a selected workflow. A trusted workflow constructs a typed plan; it never calls dr-hands as a subprocess. Images own guest processes. Reports and guest output cannot select trusted code or widen permissions.

We supply [issue triage](workflows/triage.ts) and [gravity](workflows/gravity.ts). Operators may author workflows through the same [typed contract](workflows/contract.ts). [The workflow contract](workflows/README.md) defines ownership, generated cleanup, preparation, and recovery. [The backend evaluation](workflows/backend.md) records Alchemy's selection and what it does not prove.

The CLI files are executable documentation: operational actions exit 3 without doing work. **Report linting works locally.** The TypeScript workflow descriptions are checked as specification data; they do not execute investigations or enforce cloud policy.

## Keep private data away from public browsing

Inventory image layers, reports, application source, and outputs. Missing sensitivity means private. Public does not mean safe: assume guest root and compromised targets in every run.

Reject private images or inputs combined with public-web access. Use separate public-browsing and private-analysis runs, with no private-to-public transfer. The configured inference service and its serving providers are explicit disclosure recipients. Zero retention is not absence of disclosure.

[Security](SECURITY.md) links the threat model, data-flow rules, lifecycle obligations, and accepted risks. [Values](VALUES.md) states why these rules matter. [The glossary](GLOSSARY.md) defines the shared terms.

## Local tools and contracts

```fish
mise trust
mise run setup
mise exec -- bin/dr-hands --help
mise exec -- bin/dr-hands help run
mise exec -- bin/dr-hands lint-report ./report.json
mise run lint
mise run test
```

One mise-pinned Bun toolchain runs the CLI, TypeScript checks, and report validation. Report intake uses [JSON Schema](schemas/report.schema.json), rejects duplicate keys and oversized input, and never renders contents or fetches links. Tests exercise the CLI without credentials or infrastructure operations.

- [config.example.toml](config.example.toml): annotated settings and workflow parameters; copy to ignored config.toml.
- [fnox.example.toml](fnox.example.toml): secret-store references; copy to ignored fnox.local.toml.
- [cli/help/](cli/help/): one command contract per file.
- [provisioners/README.md](provisioners/README.md): external enforcement and resource ownership.

The [Alloy and TLA+ models](formal/README.md) cover bounded reference-gravity assumptions, not typed-plan compilation, public browsing, or real-service correctness. [Archive tags](https://github.com/nateberkopec/dr-hands/tree/archive/design-stack-before-spec-only) preserve the earlier designs and their behavioral scenarios.
