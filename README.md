# dr-hands

Triage private GitHub security reports with coding agents, on throwaway cloud machines that hold nothing worth stealing.

Security reports come from strangers. Some carry prompt injection, malicious proof-of-concept code, or a story built to steer your verdict. dr-hands gives each report its own AWS machine, called a box. The box has a coding agent ([Pi](https://github.com/earendil-works/pi)), a locked-down network, and no credentials. The agents are the hands. You stay the head: you read the verdict, run the failing test, and take every GitHub action yourself.

[SECURITY.md](SECURITY.md) explains the threat model.

## How a triage goes

```fish
mise run add owner/repo GHSA-xxxx-xxxx-xxxx
```

1. Your laptop fetches the advisory and its comments, then scans them for hidden text and other tricks.
2. A fresh box boots from your image and joins your tailnet.
3. The box gets the report, a clone of the repository, and the advisory's temporary private fork if it has one. It also gets an AI key that lasts 12 hours.
4. A locked-down terminal opens on the box. The agent tries to reproduce the report with a failing test, writes a fix, and writes `~/work/VERDICT.md`.
5. You read the verdict and run the test yourself.
6. `mise run patch` copies the fix to your laptop and flags changes to build files and dependencies.
7. You review the patch, apply it in your own checkout, and act in GitHub.
8. `mise run rm` destroys the box. Boxes delete themselves after 12 hours anyway.

## Commands

| Command | What it does |
|---|---|
| `mise run add OWNER/REPO GHSA-…` | Boot a box for a report, load it, and open a terminal. Add `--no-attach` to skip the terminal. |
| `mise run attach GHSA-…` | Reopen the terminal on a report's box. |
| `mise run refresh GHSA-…` | Fetch the advisory, comments, and private fork again, and push them to the box. |
| `mise run patch GHSA-…` | Copy the agent's `fix` branch to `state/` as a patch and flag risky files. |
| `mise run rm GHSA-…` | Destroy one box, its tailnet device, and its AI key, then check that they're gone. |
| `mise run down` | Destroy every box and sweep up anything left behind. |
| `mise run image` | Build the box image. Run it again after you change stacks or settings. |

## What you need

- macOS with [Ghostty](https://ghostty.org), fish, [mise](https://mise.jdx.dev), the 1Password CLI, and the GitHub CLI signed in
- An AWS account with Organizations. Setup creates a separate member account for boxes.
- A [Tailscale](https://tailscale.com) tailnet you administer
- A machine on your tailnet that runs the inference broker in Docker. The broker forwards to [Meridian](https://github.com/rynfar/meridian) for Claude and ChatGPT subscriptions, and to Vercel AI Gateway.

[docs/setup.md](docs/setup.md) walks through the one-time setup.

## Configure

Boxes come with Node and the agent. Choose more languages with `DR_HANDS_STACKS`:

```toml
# mise.local.toml
[env]
DR_HANDS_STACKS = "python node"
```

dr-hands ships stacks for Ruby, Node, Python, Go, and Rust. A stack sets the box's toolchain and the package hosts the agent may reach. It also lists the files `patch` should flag. [docs/configuration.md](docs/configuration.md) covers every setting and how to add a stack.

## How it works

[docs/architecture.md](docs/architecture.md) describes the box, its network, the broker, and how report data moves in and out.

## Status

dr-hands is early. The broker, the image build, the scanner, the patch check, and teardown have each been tested. The full `add` flow has not yet run against a real box. The end-to-end acceptance tests in [docs/architecture.md](docs/architecture.md#acceptance-tests) are not written yet.
