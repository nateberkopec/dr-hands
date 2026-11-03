# Configuration

This is the proposed configuration experience. Only the example file and documentation exist; commands and integrations are not implemented.

## Files and selection

Tracked [`config.example.toml`](../config.example.toml) is the canonical template. Personal `config.toml` sits next to it and is gitignored. `dr-hands init` copies the example to `config.toml` and refuses to overwrite an existing file. It does not install tools, log in, access a secret store, create a fnox configuration, or deploy resources.

By default, commands read `config.toml` in the current directory. `--config PATH` selects exactly one other file. Relative paths in that file resolve from its directory, not from the caller's working directory. There are no implicit user-wide files, environment-variable overrides, or merged configuration layers. The example is never silently used as a live configuration.

These rules apply to dr-hands settings. An external credential tool may still use its own documented authentication environment; it must not silently override the selected dr-hands provider or configuration.

## Contract

| Field or table | Meaning |
| --- | --- |
| `version` | Integer configuration version; initially `1` |
| `provisioner` | Name of the selected provisioner, initially `aws` |
| `workflows` | Operator-chosen names mapped to declarative TOML manifest paths |
| `secrets.file` | Path to the separate fnox configuration |
| `provisioners.<name>` | Settings specific to that provisioner, such as AWS region |
| `provisioners.<name>.secrets` | Required credential names mapped to fnox aliases, never values |
| `inference.service` | Bounded inference service; initially `openrouter` |
| `inference.models` | Exact service model identifiers allowed for the run |
| `inference.budget_usd` | Positive finite per-run dollar ceiling |
| `inference.secrets` | Operator credential names mapped to fnox aliases |
| `run.lifetime_hours` | Positive lifetime, at most twelve hours |

The example uses DeepSeek V4.1 Flash 1017, a five-dollar budget, and a twelve-hour lifetime as editable examples, not hidden defaults. Its workflow paths describe the intended layout; workflow files are not shipped in this specs-only checkout. The example is therefore parseable TOML, not a runnable installation. The AWS and OpenRouter aliases must be mapped in the user's fnox configuration before use.

Unknown keys, unsupported versions, wrong types, duplicate keys, missing selected-provider settings, invalid limits, and undeclared secret aliases are errors. Each provider owns the schema under its own table; core settings contain no AWS-specific keys. A run cannot silently fall back to AWS when its selected provider is missing. Secret values are forbidden in this file. Malformed configuration errors identify the field, not its potentially sensitive contents.

## Deep fnox integration

Keep one secret-store setup: fnox owns providers, authentication, and mappings to stored secrets. dr-hands names aliases and calls fnox automatically. Users do not wrap commands in `fnox exec`, duplicate provider definitions in the main config, or put plaintext credentials in either example or personal configuration.

`secrets.file` points at the operator's fnox file, normally ignored `fnox.local.toml`. A user may instead point at an existing fnox configuration. Relative paths are relative to `config.toml`. The selected file must explicitly define each required alias; dr-hands does not search unrelated directories for a secret with the same name. The exact fnox invocation must honor that file selection and the supported fnox version.

For the example, fnox must map `aws_access_key_id`, `aws_secret_access_key`, and `openrouter_admin_key` to the operator's secret store. Other provisioners declare their own aliases under their own table. There are no report-source aliases or credentials: reports are text data and exporters are outside scope.

Resolve only aliases required by the selected workflow, provisioner, and inference service. Missing or expired credentials fail explicitly without provisioning. Resolved values stay in memory for the required control-plane operation; they must not appear in logs, diagnostics, snapshots, rendered configuration, process arguments, or persistent run state. Do not forward the controller's whole environment to a guest or provider process.

Provisioner control-plane code receives only the operator credentials its operation needs. Guest roles receive no operator, cloud, report-source, or inference-administration credentials. A role that uses inference receives only its own bounded, expiring run credential. Failures from fnox are surfaced with secret values redacted, not converted to empty credentials or silent fallback behavior.

## Commands and side effects

| Proposed command | What it does | What it must not do |
| --- | --- | --- |
| `dr-hands init` | Copies the example to adjacent `config.toml` | Overwrite files, resolve secrets, contact services, or provision |
| `dr-hands check` | Validates config, manifests, required aliases, and local paths | Resolve secret values or contact remote services |
| `dr-hands doctor --workflow NAME` | Resolves required aliases and makes non-mutating service checks | Create resources, issue run credentials, build images, or charge an inference request |
| `dr-hands run --workflow NAME` | Validates again, resolves needed aliases, then provisions the selected run | Skip checks because a previous doctor succeeded |

`check` validates required alias declarations and local structure without accessing the secret store. Checking a reference is not proof that its secret exists or grants useful permissions. For a selected workflow, `doctor` checks credential resolution, authentication, pinned image availability, model availability, and service policy support wherever non-mutating APIs allow it. It reports checks it cannot establish; it must not call a mutating API merely to turn an unknown into a pass.

Provider-dependent capabilities such as budget enforcement, expiry, network filtering, and external teardown observations must be substantiated. A successful credential probe is not evidence for those security guarantees. Unsupported required capabilities stop run creation.

## Frozen run configuration

A run records a non-secret snapshot of its workflow, provider selection, resolved immutable image identities, policy, limits, and alias names. Configuration edits affect new runs only. Cleanup uses the original resource inventory, provider, and authority identities; a new default must not strand old runs. Changed or unavailable credentials must produce an actionable cleanup failure, never a claim that removal succeeded.

Workflows select role images and guest dependencies rather than local `stacks/` hooks. Network permissions belong to the workflow declaration and external enforcement, not a guest proxy allowlist. See [Workflows](workflows.md), [Report input](reports.md), and [Provisioners](../provisioners/README.md).
