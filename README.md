# dr-hands

Triage private GitHub security reports with coding agents, on throwaway cloud machines that hold nothing worth stealing.

Security reports come from strangers. Some carry prompt injection, malicious proof-of-concept code, or a story built to steer your verdict. dr-hands gives each report its own AWS machine, called a box. The box has a coding agent ([Pi](https://github.com/earendil-works/pi)), a locked-down network, and no credentials. The agents are the hands. You stay the head: you read the verdict, run the failing test, and take every GitHub action yourself.

[SECURITY.md](SECURITY.md) explains the threat model.

## How a triage goes

```fish
mise run add owner/repo GHSA-xxxx-xxxx-xxxx
```

1. Read the scanner's findings, then work with the agent in the terminal that opens. It writes `~/work/VERDICT.md` and a failing test.
2. Run the test yourself.
3. `mise run patch` brings the fix to your laptop. Review every line, apply it in your own checkout, and act in GitHub.
4. `mise run rm` destroys the box.

## Commands

`mise tasks` lists every command. Run `refresh` after a reporter replies, and `image` after you change stacks or settings.

## What you need

- macOS with [Ghostty](https://ghostty.org), fish, [mise](https://mise.jdx.dev), the 1Password CLI, and the GitHub CLI signed in
- An AWS account with Organizations. Setup creates a separate member account for boxes.
- A [Tailscale](https://tailscale.com) tailnet you administer
- A machine on your tailnet that runs the inference broker in Docker. The broker forwards to [Meridian](https://github.com/rynfar/meridian) for Claude and ChatGPT subscriptions, and to Vercel AI Gateway.

[docs/setup.md](docs/setup.md) walks through the one-time setup.

## Configure

Choose the languages on each box with `DR_HANDS_STACKS`:

```toml
# mise.local.toml
[env]
DR_HANDS_STACKS = "python node"
```

Stacks live in `stacks/`. [docs/configuration.md](docs/configuration.md) covers every setting and how to add a stack.

## Status

dr-hands is early. The full `add` flow has not yet run against a real box, and there are no end-to-end tests yet.
