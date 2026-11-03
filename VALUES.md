# Values

These are the rules we design dr-hands by. The specifications describe the intended behavior. This file says why.

## Problems we solve

Investigating a security report can mean following hostile links, reading malicious instructions, and running attacker-supplied code. Doing that on an operator's workstation puts their credentials, network, and other work at risk. Testing an attacker framework against a live target can infect both the agent and the target.

dr-hands gives that work a disposable boundary. The operator can investigate a report and collect evidence without giving the agent access to their workstation or production systems. It cannot protect the operator's judgment from manipulation by what they read.

## Security first

Every report is infected. We assume the agent has root from the start and the target is infected too, because the agent may infect it at any time. [SECURITY.md](SECURITY.md#what-we-assume) explains the triage threat model, [the gravity threat model](SECURITY.md#gravity-machine), [how dr-hands protects you](SECURITY.md#how-dr-hands-protects-you), and [the risks we accept](SECURITY.md#risks-we-accept). The design rules follow from it:

- **Enforce rules outside the guest.** The agent already has root. Guest configuration is not a security boundary; the rules that matter live outside it: cloud networks, managed access policy, and the OpenRouter workspace.
- **Trust intake code, never intake content.** A report source runs as you and must be trusted. Every snapshot it produces remains hostile and gets the same scan and isolation, whatever its origin.
- **Teardown proves itself.** Removing a run checks that nothing survived, and fails loudly when something did.

When we accept a new risk, we add it to SECURITY.md.

## Run no persistent control plane of our own

Managed services enforce the rules. Experiment-local servers and databases are hostile workloads that die with their machines. You have nothing to patch between runs.

## Run anywhere

dr-hands works on macOS and Linux, from any shell and any terminal. It assumes only mise and a signed-in GitHub CLI. mise installs everything else.

## Everything is code

Cloud resources come from code, not clicks. A one-time manual step is fine when the docs spell it out.

## Keep you out of the repository

Personal settings live in `mise.local.toml`. Secrets live in your own secret store, through fnox. Neither goes into git.

