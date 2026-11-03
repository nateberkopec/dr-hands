# Values

These are the rules we design dr-hands by. The feature files in `features/` say what it does. This file says why.

## Security first

Every report is hostile, and we treat every agent and experiment guest as the attacker. [SECURITY.md](SECURITY.md#what-we-assume) explains the triage threat model, [the gravity threat model](SECURITY.md#gravity-machine), [how dr-hands protects you](SECURITY.md#how-dr-hands-protects-you), and [the risks we accept](SECURITY.md#risks-we-accept). Three design rules follow from it:

- **Enforce rules where a hostile guest cannot reach them.** A rule on the guest holds only until the agent gets root. So the rules that matter live outside it: provisioner-declared network and management controls, infrastructure access policy, and the OpenRouter workspace.
- **Trust local extensions deliberately, never their claims alone.** Report sources and provisioners run as you and must be trusted. Every snapshot remains hostile, and provisioner state cannot prove its own cleanup.
- **Teardown proves itself.** Removing a run checks through an external read-only view that nothing survived, and fails loudly when something did.

When we accept a new risk, we add it to SECURITY.md.

## Run no persistent control plane of our own

Managed services enforce the rules. Experiment-local servers and databases are hostile workloads that die with their machines. You have nothing to patch between runs.

## Run anywhere

dr-hands works on macOS and Linux, from any shell and any terminal. It assumes only mise and a signed-in GitHub CLI. mise installs everything else.

## Everything is code

Cloud resources come from code, not clicks. A one-time manual step is fine when the docs spell it out.

## Keep you out of the repository

Personal settings live in `mise.local.toml`. Secrets live in your own secret store, through fnox. Neither goes into git.

## Done means proven

A feature is done when its scenarios pass against real services, and the evidence survives cleanup. Security architecture is also checked as an explicit model, with its assumptions and bounds beside it. A test on a stand-in, such as a container in place of a real Linux machine, lists what it did not cover.

## Build only what is needed

We add a feature when a real triage needs it. We remove code we no longer use, with no traces left.
