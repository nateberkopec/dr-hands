# dr-hands

This repository is a specification, not an implementation.

Investigate hostile security reports and exercise attacker frameworks against disposable targets without putting your workstation inside the experiment.

## The problem

A report can lead through malicious links, prompt injection, exploit code, packages, and model files. We assume the agent has root and any target it touches is infected. The goal is a clear, disposable technical boundary, not a trustworthy agent. dr-hands cannot ensure the cognitive security of the person reading the report or its results.

## One tool, pluggable workflows

A **Workflow** declares roles, inputs, permitted connections, and outputs. A **Run** is one execution with its own resources, authority, deadline, and evidence. Triage and gravity share the same lifecycle and cleanup rules.

- **Triage:** an agent investigates a structured report and may follow public HTTP(S) links from inside the isolated run. This accepts disclosure to public services and the risk of hostile outbound requests, while keeping private and management networks out of reach.
- **Gravity:** an attacker framework exercises a disposable target without general Internet access. ARTEX and RubyGems.org are the reference roles, not fixed engine components. The allowed external service is bounded OpenRouter inference.

Custom workflows use declarative manifests, not local lifecycle hooks. Provisioners implement infrastructure and external policy enforcement. A workflow cannot override mandatory isolation. See [Workflows](docs/workflows.md), the [provisioner contract](provisioners/README.md), and the [glossary](GLOSSARY.md).

## Report data, not source plugins

Supply a UTF-8 JSON report with a version, title, body, and optional comments and provenance. How you obtain it is up to you. GHSA and HackerOne exporters are outside this repository; dr-hands does not execute them or manage their credentials.

The local tool checks structure and size, but never treats the content as safe, follows its links, or renders its markup. The operator selects the workflow and target separately. [Report input](docs/reports.md) defines the contract.

## Configuration flow

Keep ignored `config.toml` beside tracked [`config.example.toml`](config.example.toml). It selects declarative workflow manifests and nests provider-specific settings. Secret aliases refer to a separate fnox file; dr-hands resolves them automatically without a manual `fnox exec` wrapper.

```fish
dr-hands init
dr-hands check
dr-hands doctor --workflow triage
dr-hands run --workflow triage --report ./report.json
dr-hands export RUN
dr-hands remove RUN
```

`init` copies the example without overwriting an existing configuration. `check` is local and does not resolve secrets. `doctor` checks selected credentials and services without creating resources. Only the explicit run command provisions a run. Use `--config /path/to/config.toml` to select another configuration; there are no implicit global or environment-variable overrides.

[Setup](docs/setup.md) describes the sequence. [Configuration](docs/configuration.md) specifies the file and fnox integration. The example model is DeepSeek V4.1 Flash 1017; `doctor` must check current OpenRouter availability and policy support rather than assume it.

## Security and teardown

[VALUES.md](VALUES.md) states the problems and design principles. [SECURITY.md](SECURITY.md) defines assumptions, boundaries, and accepted risks. The ambition is that escape would require a CVSS 9+ zero-day in mature upstream infrastructure; the actual requirement is that every escape path cross a named upstream security boundary, with as few such assumptions as possible. No numeric severity or novelty of a future exploit is guaranteed.

Every run has bounded inference authority and an expiry. Removal destroys all guest-writable runtime resources, revokes authority, and verifies absence. Explicitly exported evidence may survive as opaque, still-hostile files. Public-web requests and copies made by external services cannot be undone by teardown.

## Specifications and verification

[GRAVITY.md](GRAVITY.md) describes the restricted gravity workflow and its [Alloy and TLA+ specifications](formal/README.md). The gravity network model does not prove public-web triage or arbitrary workflow manifests. The [archived design stack](https://github.com/nateberkopec/dr-hands/tree/archive/design-stack-before-spec-only) preserves earlier versions and their Gherkin scenarios.
