# Configuration

Settings go in the `[env]` table of `mise.local.toml`. Secrets go in `fnox.local.toml`. Git ignores both files.

After you change a stack or a setting marked below, run `mise run image`.

## Settings

| Setting | Used for | Rebuild image? |
|---|---|---|
| `AWS_REGION` | Where boxes and images live | Yes |
| `DR_HANDS_STACKS` | Languages on the box, separated by spaces | Yes |
| `DR_HANDS_BROKER_HOST` | The broker's TLS name on your tailnet, such as `broker.example.ts.net` | Yes |
| `DR_HANDS_BROKER_IP` | The broker's tailnet IPv4 address | Yes |
| `DR_HANDS_BROKER_SSH` | The SSH host your laptop uses to reach the broker's admin port | No |
| `DR_HANDS_BROKER_TOKEN_FILE` | The admin token file on the broker host | No |
| `DR_HANDS_REPORT_SOURCE_NAME` | The trusted executable for a custom report source named `NAME` | No |

## Secrets

`fnox.toml` names the built-in secrets dr-hands needs. Tell [fnox](https://fnox.jdx.dev) where yours live in `fnox.local.toml`. Custom report sources may name additional secrets. For 1Password:

```toml
[providers.op]
type = "1password"

[secrets]
AWS_ACCESS_KEY_ID = { provider = "op", value = "op://Private/dr-hands-aws-deploy/username" }
AWS_SECRET_ACCESS_KEY = { provider = "op", value = "op://Private/dr-hands-aws-deploy/credential" }
TAILSCALE_OAUTH_CLIENT_ID = { provider = "op", value = "op://Private/dr-hands-tailscale/username" }
TAILSCALE_OAUTH_CLIENT_SECRET = { provider = "op", value = "op://Private/dr-hands-tailscale/credential" }
```

Any other fnox provider works too.

## Report sources

A report source is trusted local code. It reads a source-specific locator and writes a normalized snapshot before dr-hands creates any cloud resource. GitHub and text files are built in.

```sh
mise run add github GHSA-xxxx-xxxx-xxxx --repo owner/repo
mise run add text ./report.md --repo owner/repo
```

Add another source by setting `DR_HANDS_REPORT_SOURCE_NAME` to its executable in `mise.local.toml`:

```toml
[env]
DR_HANDS_REPORT_SOURCE_HACKERONE = "hackerone-dr-hands"
```

Then `mise run add hackerone 123456 --repo owner/repo` invokes:

```text
hackerone-dr-hands fetch 123456 --output DIRECTORY
```

The executable writes `report.json` and `report.md` into the empty directory. `report.json` has a protocol version, a stable source-local ID, a title, a body, and comments. It may also name the repository when `--repo` did not. Optional code supplied with the report is a Git bundle at the fixed path `code.bundle`; dr-hands imports its branches under `report/`.

The source's name and stable ID identify the report. IDs from different sources do not collide. `refresh RUN` invokes the same source and locator again, and refuses a changed ID or repository.

A source executable runs as you on your laptop. It can read your files and credentials, so install only code you trust. Its fetched report is still hostile. dr-hands captures source output instead of printing it, scans the normalized snapshot, and never copies source credentials into a box or local run state.

## Stacks

A stack is a folder in `stacks/`. Every file in it is optional:

| File | Contents |
|---|---|
| `mise.toml` | A mise `[tools]` table for the agent |
| `hosts` | Hosts the agent may reach through the proxy, one per line. A leading dot also allows subdomains. |
| `packages` | Debian packages, one per line |
| `risky-files` | Path patterns that `mise run patch` should flag, one per line |

### Add a stack

Make a folder and list what the language needs. For example, Elixir:

```
stacks/elixir/mise.toml      [tools] erlang = "…" and elixir = "…"
stacks/elixir/hosts          repo.hex.pm and builds.hex.pm
stacks/elixir/risky-files    mix.exs and mix.lock
```

Then add `elixir` to `DR_HANDS_STACKS` and run `mise run image`.

Keep `hosts` short. Every allowed host is a way out for the agent as well as a way in for an attacker's package. If a project pins a different language version, list that version in the stack too. The box can't download toolchains at run time.
