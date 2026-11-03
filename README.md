# dr-hands

This repository contains specifications and documentation only. The implementation has been archived and removed. Commands and setup instructions below and in the other documents describe the proposed or archived design, not runnable software in this checkout. See [History and recovery](docs/history.md) to read or restore the archived versions.

Triage private security reports and run attacker frameworks against live targets, on throwaway cloud machines that hold nothing worth stealing.

Security reports come from strangers. They may arrive through GitHub, HackerOne, a text file, or a system of your own. Some carry prompt injection, malicious proof-of-concept code, or a story built to steer your verdict. dr-hands normalizes each report through a report source, then gives the resulting run its own AWS machine, called a box. The box has a coding agent ([Pi](https://github.com/earendil-works/pi)), a locked-down network, and no report-source or GitHub credentials. For runtime work, a gravity machine puts an attacker framework and a target implementation together inside a stricter chamber. [ARTEX](https://github.com/BaaRai/ARTEX) and [RubyGems.org](https://github.com/rubygems/rubygems.org) are the first reference implementations of those roles. The agents are the hands. You stay the head: you read the evidence, run the failing test, and take every repository action yourself.

[SECURITY.md](SECURITY.md) explains the threat model. [VALUES.md](VALUES.md) explains the rules we design by. [GLOSSARY.md](GLOSSARY.md) defines report-source terms.

## How a triage goes

```sh
mise run add github GHSA-xxxx-xxxx-xxxx --repo owner/repo
mise run add text ./report.md --repo owner/repo
mise run add hackerone 123456 --repo owner/repo
```

`add` prints a run ID. The remaining commands take that ID, not the source's identifier.

1. A report source fetches or reads the report on your laptop and saves a normalized snapshot.
2. Read the scanner's findings, then work with the agent in your terminal. It writes `~/work/VERDICT.md` and a failing test.
3. Run the test yourself.
4. `mise run patch RUN` brings the fix to your laptop. Review every line and apply it in your own checkout.
5. `mise run rm RUN` destroys the box and its OpenRouter key.

Each box ends itself 12 hours after it boots.

## How a gravity run goes

```sh
mise run gravity artex rubygems.org
```

1. dr-hands creates a private chamber with the selected attacker framework on one AWS machine and the selected target implementation on another. In this reference run, those are ARTEX and a synthetic copy of RubyGems.org.
2. The attacker framework attacks only that target. Neither machine has general Internet access or a production credential.
3. `mise run gravity-results RUN` saves findings, traffic and evidence as opaque files on your laptop.
4. `mise run gravity-rm RUN` destroys the chamber and proves every remote resource and authority absent.

Guest root is expected. The boundary is AWS's hypervisor and managed network, outside both machines. [GRAVITY.md](GRAVITY.md) is the one-page acceptance contract and the starting point for its threat model, executable behavior, and formal verification.

## Models

Each box or gravity run gets its own [OpenRouter](https://openrouter.ai) key. The key has a dollar limit and dies with its compute. It lives in a dr-hands OpenRouter workspace, which code sets up for you. The workspace enforces these rules, so a hostile guest cannot change them:

- Only the models you list can answer.
- Every request uses zero data retention.
- OpenRouter's hosted tools, such as web search and web fetch, are off.

## Commands

`mise tasks` lists every command. Run `refresh RUN` after a report changes at its source. Run `image` after you change stacks, and `setup-openrouter` after you change models. `down` destroys every box and sweeps up leftovers.

## What you need

- macOS or Linux. On Windows, use WSL.
- [mise](https://mise.jdx.dev) and the GitHub CLI, signed in. mise installs everything else.
- A secret store that [fnox](https://fnox.jdx.dev) can read, such as 1Password
- An AWS account with Organizations. Setup creates a separate member account for boxes.
- A [Tailscale](https://tailscale.com) tailnet you administer
- An OpenRouter account with credits

dr-hands runs no persistent control plane of its own. Experiment-local services die with their machines. [docs/setup.md](docs/setup.md) walks through the one-time setup.

## Configure

Put your settings in `mise.local.toml`. Git ignores it.

```toml
[env]
DR_HANDS_STACKS = "python node"
DR_HANDS_MODELS = "anthropic/claude-opus-5.5"
DR_HANDS_REPORT_SOURCE_HACKERONE = "hackerone-dr-hands"
DR_HANDS_PROVISIONER = "aws"
```

GitHub and text are built-in report sources. A custom source is a trusted local executable configured as `DR_HANDS_REPORT_SOURCE_NAME`; the example makes `hackerone` available to `add`. Source credentials stay in your own secret store through fnox and never enter a box.

AWS is the built-in provisioner. Set `DR_HANDS_PROVISIONER` to an absolute executable to plug in another implementation without changing core commands.

List models by their OpenRouter IDs. The first one is the agent's default. The proposed stack layout is `stacks/`. [docs/configuration.md](docs/configuration.md) covers report sources, every setting, the per-report budget, and how to add a stack.

## Specifications and verification

[GRAVITY.md](GRAVITY.md), [SECURITY.md](SECURITY.md), and the [formal specifications](formal/README.md) describe the intended behavior and trust boundaries. The Alloy and TLA+ models remain; their execution harness and CI have been archived. Gherkin feature files are available only in the [archived design stack](docs/history.md). This checkout has no application, test runner, or deployment tooling.
