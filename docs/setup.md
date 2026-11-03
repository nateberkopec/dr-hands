# Setup

## 1. Create a configuration

The `dr-hands init` command copies tracked `config.example.toml` to ignored `config.toml` beside it. It refuses to overwrite a file and makes no network calls. The user can also copy and edit the example manually.

Choose a provisioner, select workflow manifest paths, and set inference models, budget, and lifetime. Provider-specific settings stay nested under `provisioners.<name>`. Workflow manifests declare role images and target selection; untrusted reports cannot choose these for you.

[Workflows](workflows.md) defines the manifest contract.

## 2. Connect your existing secret store

Configure fnox normally for your secret store and map the required aliases in the file named by `secrets.file`. The default path is adjacent `fnox.local.toml`. There is no dr-hands secret-store wizard and no second provider configuration.

For the AWS example, map the two AWS aliases and the OpenRouter administration alias. Use limited operator provisioning credentials, not cloud root credentials. Other provisioners specify their own requirements. No report-exporter credentials belong here.

## 3. Validate locally

```fish
dr-hands check
```

This validates configuration, manifests, paths, and secret alias declarations without resolving values or contacting services. Errors identify the field and rule. It does not print report contents or secret values.

## 4. Check the selected services

```fish
dr-hands doctor --workflow triage
```

dr-hands invokes fnox itself and checks the selected provider and inference service without creating cloud resources, minting run keys, or making a billed inference request. A doctor result distinguishes confirmed capabilities from those a read-only probe cannot establish. It is not proof of containment.

Provisioning is a separate explicit action. Do not infer that a successful doctor grants permission to deploy.

## 5. Supply data and start a run

Obtain a report however you choose and save a document matching [Report input](reports.md). Start with harmless synthetic text and a disposable target you control.

```fish
dr-hands run --workflow triage --report ./report.json
```

This command validates the selected inputs again, resolves only the required credentials, and provisions the run. Triage may follow public HTTP(S) links from inside the guest; gravity does not inherit that access. Neither workflow may reach the workstation, private networks, other runs, or provider metadata/control-plane endpoints.

## 6. Export and remove

```fish
dr-hands export RUN
dr-hands remove RUN
```

An explicit export saves selected guest-produced evidence as opaque files under fixed local names. They remain hostile; do not execute or automatically render them. Removal destroys every guest-writable runtime resource and revokes run authority, then confirms absence through external services. Exported evidence and trusted control-plane metadata may survive. Earlier requests to public services cannot be undone by removal.

There is no broker, persistent custom control plane, or report-source plugin to install. See [Configuration](configuration.md) for exact settings and side-effect boundaries.
