# dr-hands

This repository is a specification, not an implementation.

Investigate hostile reports and exercise attacker frameworks against disposable targets without putting your workstation inside the experiment.

## Images, data, and a fixed boundary

Users bring immutable images and declared inputs, not lifecycle code. Images implement fixed role interfaces; dr-hands owns provisioning, input delivery, role startup, observation, and removal. No local setup hooks, startup-command overrides, pre-agent scripts, or custom lifecycle steps are accepted.

An inventory distinguishes public software images from potentially sensitive images, reports, and application source. Every image layer and input is classified; missing sensitivity means private. Public does not mean trusted. We assume guest root and infected targets, so the inventory describes everything accessible inside the boundary, not just the agent's initial process.

## Avoid the lethal trifecta

Before provisioning, show whether the run has private data, hostile content, and external communication. Hostile content is always assumed. A run with private images or inputs cannot have public-web access, and there is no override.

- **Private analysis:** private reports or source, hostile content, and access only to the configured inference service.
- **Public browsing:** explicitly public images and inputs, hostile content, and public HTTP(S). Public requests and disclosures cannot be undone by teardown.
- **Gravity:** an attacker and disposable target, restricted role connections, and bounded inference. ARTEX and RubyGems.org are reference images, not separate lifecycle engines.

Use separate public browsing and private analysis runs, not stages on the same guest. Browsing results remain hostile when imported into private analysis. Private inputs and derived outputs cannot flow into a public run. Disclosure to the configured inference service and its serving providers is accepted and shown during approval; zero retention is not absence of disclosure.

## Read the contracts where they are used

- [`config.example.toml`](config.example.toml): annotated settings, role images, input inventory, classifications, and network policy. Copy to ignored `config.toml`.
- [`fnox.example.toml`](fnox.example.toml): annotated secret-store aliases. Copy to ignored `fnox.local.toml`; dr-hands resolves required aliases automatically.
- [`schemas/report.schema.json`](schemas/report.schema.json): report fields, bounds, and intake rules. Obtaining reports is outside scope.
- [`bin/dr-hands`](bin/dr-hands) and [`cli/`](cli/): command contracts, approval, side effects, and failure behavior.
- [`workflows/lifecycle.yaml`](workflows/lifecycle.yaml): bundled Dagu lifecycle; [`workflows/remove.yaml`](workflows/remove.yaml): independent removal. These are tool-owned graphs, not user inputs.
- [`provisioners/README.md`](provisioners/README.md): external enforcement and resource ownership.

```fish
bin/dr-hands --help
bin/dr-hands help run
bin/dr-hands help resume
bin/dr-hands help lint-report
```

The report linter uses Python 3 and [`requirements-lint.txt`](requirements-lint.txt). It validates structure without rendering contents or fetching links. Every other command explains its contract; help exits successfully, while action invocations report that no action was performed and exit nonzero.

## Security and evidence

[VALUES.md](VALUES.md) states the design principles. [GLOSSARY.md](GLOSSARY.md) defines the domain language. [SECURITY.md](SECURITY.md) defines the threat model, the trifecta policy, and accepted inference disclosure. Technical containment does not ensure the cognitive security of the operator.

Removal destroys all guest-writable runtime resources, revokes authority, and verifies absence. Explicitly exported evidence survives as opaque, still-hostile files. Externally enforced expiry does not depend on the laptop or workflow runner. Reconnection resumes reconciliation and cleanup without extending the deadline.

[GRAVITY.md](GRAVITY.md) describes the restricted reference workflow and its [Alloy and TLA+ models](formal/README.md). Those models do not prove public-web browsing, input classification, or the configuration contract. The [archived design stack](https://github.com/nateberkopec/dr-hands/tree/archive/design-stack-before-spec-only) preserves earlier versions and their Gherkin scenarios.
