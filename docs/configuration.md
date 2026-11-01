# Configuration

dr-hands reads its settings from the `[env]` table in `mise.toml`. Override any of them in `mise.local.toml`, which git ignores:

```toml
[env]
AWS_REGION = "us-east-2"
DR_HANDS_STACKS = "python node"
```

After you change a stack or a setting marked below, run `mise run image`.

## Settings

| Setting | Used for | Rebuild image? |
|---|---|---|
| `AWS_REGION` | Where boxes and images live | Yes |
| `DR_HANDS_REGION` | The region `bootstrap-aws` sets up. Keep it equal to `AWS_REGION`. | No |
| `DR_HANDS_STACKS` | Languages on the box, separated by spaces | Yes |
| `DR_HANDS_BROKER_HOST` | The broker's TLS name on your tailnet, such as `broker.example.ts.net` | Yes |
| `DR_HANDS_BROKER_IP` | The broker's tailnet IPv4 address | Yes |
| `DR_HANDS_BROKER_SSH` | The SSH host your laptop uses to reach the broker's admin port | No |
| `DR_HANDS_BROKER_TOKEN_FILE` | The admin token file on the broker host | No |

Point the 1Password references in `op.env` at your own vault items.

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
