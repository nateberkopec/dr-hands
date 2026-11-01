# Configuration

dr-hands reads its settings from the `[env]` table in `mise.toml`. Override any of them in `mise.local.toml`, which git ignores:

```toml
[env]
AWS_REGION = "us-east-2"
DR_HANDS_STACKS = "python node"
```

After you change a stack or a setting the image uses, run `mise run image`. `add` refuses to boot a box from an image that doesn't match your stacks, `image/`, and settings.

## Settings

| Setting | Used for | Rebuild image? |
|---|---|---|
| `AWS_REGION` | Where boxes and images live | Yes |
| `DR_HANDS_REGION` | The region `bootstrap-aws` sets up. Keep it equal to `AWS_REGION`. | No |
| `DR_HANDS_STACKS` | Languages on the box, separated by spaces | Yes |
| `DR_HANDS_BROKER_HOST` | The broker's TLS name on your tailnet, such as `broker.example.ts.net` | Yes |
| `DR_HANDS_BROKER_IP` | The broker's tailnet IPv4 address. The box firewall allows only this address, on port 3460. | Yes |
| `DR_HANDS_BROKER_SSH` | The SSH host your laptop uses to reach the broker's admin port | No |
| `DR_HANDS_BROKER_TOKEN_FILE` | The admin token file on the broker host | No |

Secrets live in 1Password. `op.env` lists the 1Password references that `op run` passes to each task: the AWS deploy key and the Tailscale OAuth client. Point those references at your own vault items.

## Stacks

A stack is a folder in `stacks/`. Every file in it is optional:

| File | Contents | Effect |
|---|---|---|
| `mise.toml` | A mise `[tools]` table | Installed for the agent at image build time |
| `hosts` | One host per line. A leading dot also allows subdomains. | Added to the proxy's allowlist |
| `packages` | Debian package names, one per line | Installed with apt at image build time |
| `risky-files` | Path patterns, one per line, such as `Cargo.toml` or `.cargo/*` | `mise run patch` marks matching files |

Every box also gets Node, Pi, git, and C build tools. It can always reach `github.com`, `codeload.github.com`, and `objects.githubusercontent.com`. `lib/risky-files` lists the patterns flagged for every stack, such as CI configuration and shell scripts.

The shipped stacks:

| Stack | Toolchain | Package hosts |
|---|---|---|
| `ruby` | Ruby | RubyGems |
| `node` | (Node is always installed) | npm, Yarn |
| `python` | Python, uv | PyPI |
| `go` | Go | the Go module proxy and checksum database |
| `rust` | Rust | crates.io |

### Add a stack

Make a folder and list what the language needs. For example, Elixir:

```
stacks/elixir/mise.toml      [tools] erlang = "…" and elixir = "…"
stacks/elixir/hosts          repo.hex.pm and builds.hex.pm
stacks/elixir/risky-files    mix.exs and mix.lock
```

Then add `elixir` to `DR_HANDS_STACKS` and run `mise run image`.

Keep `hosts` short. Every allowed host is a way out for the agent as well as a way in for an attacker's package. If a project pins a different language version, list that version in the stack too. The box can't download toolchains at run time.
