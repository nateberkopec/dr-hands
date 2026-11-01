# Design: run dr-hands anywhere, without a broker

Status: proposed. Code follows in a separate pull request.

## Goal

Today only its author can run dr-hands. Setup needs macOS, fish, Ghostty, a Docker host on the tailnet, and [Meridian](https://github.com/rynfar/meridian). This change cuts the list down so anyone can set it up in an afternoon, with no machine of their own to run.

## What you need after this change

- macOS or Linux, with [mise](https://mise.jdx.dev) and the GitHub CLI signed in
- A secret store that [fnox](https://fnox.jdx.dev) can read
- An AWS account with Organizations
- A [Tailscale](https://tailscale.com) tailnet you administer
- An [OpenRouter](https://openrouter.ai) account with credits

There is no shell, terminal, Docker host, or always-on machine on the list.

## What changes

| Part | Today | After |
|---|---|---|
| Commands | fish scripts and `scan.rb` | One TypeScript CLI on Node 24. mise task names stay the same. |
| Inference | Our broker on a home server, in front of Meridian and Vercel | OpenRouter, with one capped key per report. No broker. |
| Tailnet | Boxes may reach the broker; you may SSH to boxes | You may SSH to boxes. Boxes get no grants at all. |
| Terminal | Ghostty on macOS, required | Your current terminal. A hardened Ghostty window is optional. |
| Models | Baked into the image | A setting. `add` writes Pi's config on each box. |
| AWS deploy key | Saved to 1Password | Printed once, for any secret store |

## Inference

Each user gets one OpenRouter **workspace** for dr-hands. Terraform in a new `openrouter/` folder creates and updates it, using OpenRouter's official provider. A `mise run setup-openrouter` task applies it.

The workspace sets rules that every key in it inherits. A box cannot change them:

- **Default guardrail:** only the models in `DR_HANDS_MODELS`, and zero data retention for every model group.
- **Server tools off:** `disabled_server_tools` lists all of OpenRouter's hosted tools, such as web search, web fetch, and the sandboxed shell. A request that names one gets a 403.
- **No logging:** prompt logging and the training-data discount are off.

For each report, `add` makes a key in that workspace. The key has a dollar limit, `DR_HANDS_REPORT_BUDGET`, and expires after 12 hours, like the box. `add` writes the key into Pi's `auth.json` on the box. `rm` deletes the key. `down` deletes every dr-hands key in the workspace.

The box reaches `openrouter.ai` through the existing Squid proxy. That host joins the default allowlist.

The laptop holds a management key that can act only inside the dr-hands workspace. You make it once in the OpenRouter dashboard.

### Why OpenRouter

We compared OpenRouter, Vercel AI Gateway, LiteLLM, Bifrost, and agentgateway. We did not want to run our own gateway, so the hosted services won. Between those two, the deciding question was which rules a hostile box cannot switch off.

- OpenRouter puts the model allowlist, zero data retention, and the server-tool ban on the workspace. These work on the standard plan.
- Vercel applies its allowlists and zero data retention to the whole team. They need the Pro plan and add a fee per request. Without them, each request carries its own privacy flags, and the box writes the requests. We found no way to turn off Vercel's hosted search and fetch tools.
- Vercel charges no markup. OpenRouter charges 5.5% on credits. We accept that cost.

## Network

The box firewall stays default-deny for the agent user. With no broker, the agent can reach only loopback, which includes Squid. Squid allows GitHub, OpenRouter, and the hosts of the chosen stacks.

The tailnet carries only your SSH to boxes. Boxes are tagged `tag:dr-hands-box`, and no grant names that tag as a source. This replaces `tag:ghsa`. The Tailscale OAuth client is scoped to the new tag.

## Commands

One CLI, `cli/main.ts`, runs on Node 24 without a build step. mise installs Node, Terraform, the AWS CLI, and fnox. The commands are the same as today: `add`, `attach`, `refresh`, `patch`, `rm`, `down`, `image`, and `bootstrap-aws`, plus `setup-openrouter`.

`attach` runs the session in your current terminal. With `DR_HANDS_TERMINAL=ghostty`, it opens a Ghostty window with clipboard, links, images, and reports turned off. That works on macOS and Linux. For other terminals, the docs list the settings to turn off.

## Settings and secrets

Settings live in `mise.local.toml`:

| Setting | Meaning |
|---|---|
| `AWS_REGION` | Where boxes and images live |
| `DR_HANDS_STACKS` | Languages on the box |
| `DR_HANDS_MODELS` | OpenRouter model IDs. The first is Pi's default. |
| `DR_HANDS_REPORT_BUDGET` | Dollar limit per report key. Default 20. |
| `DR_HANDS_TERMINAL` | Optional. `ghostty` for the hardened window. |

Changing `DR_HANDS_MODELS` means running `setup-openrouter` again. It no longer means rebuilding the image.

Secrets go through fnox: the AWS deploy key, the Tailscale OAuth client, and the OpenRouter workspace management key. `setup-openrouter` also needs an account-level management key. Only that task uses it.

## Security changes

`SECURITY.md` changes in these ways:

- **The box holds a real provider key.** A hijacked agent could copy it out through an allowed host. The key works only in the dr-hands workspace, only for allowed models, up to its dollar limit, for at most 12 hours.
- **Hosted tools are blocked by OpenRouter, not by us.** The broker never blocked them, so this is a gain.
- **OpenRouter sees every prompt.** It does not store prompts unless you opt in. Zero data retention is enforced for the model providers behind it.
- **US-only inference is gone.** OpenRouter offers it only on its Business plan.
- **Per-report session namespacing is gone.** It existed only for Meridian's subscription seats.

## To verify while building

1. `disabled_server_tools` also blocks the deprecated `web` plugin.
2. OpenRouter does not pass a provider's own hosted tool through the Messages API, such as Anthropic's `web_search_20250305`.
3. Terraform can set the workspace's default guardrail, logging, and server-tool list.
4. Pi's OpenRouter provider works through Squid.

If 1 or 2 fails, `SECURITY.md` lists it as an accepted risk.

## Rollout

1. Merge this document.
2. Build the change on the `portable` branch, and test it end to end against real AWS and OpenRouter.
3. Move the author's setup: new tailnet tag and OAuth client, the OpenRouter workspace, and a new image.
4. Remove the old broker from the home server, in the homelab repository.
