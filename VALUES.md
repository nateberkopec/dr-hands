# Values

These are the rules we design dr-hands by. The feature files in `features/` say what it does. This file says why.

## Security first

Every report is hostile, and we treat the agent as the attacker. [SECURITY.md](SECURITY.md#what-we-assume) explains the threat model, [how dr-hands protects you](SECURITY.md#how-dr-hands-protects-you), and [the risks we accept](SECURITY.md#risks-we-accept). Two design rules follow from it:

- **Enforce rules where a hostile box cannot reach them.** A rule on the box holds only until the agent gets root. So the rules that matter live outside it: cloud firewalls, the tailnet policy, and the OpenRouter workspace.
- **Teardown proves itself.** Removing a box checks that nothing survived, and fails loudly when something did.

When we accept a new risk, we add it to SECURITY.md.

## Run no servers of our own

We don't run a gateway, a database, or an always-on machine. Managed services enforce the rules for us. You have nothing to patch between reports.

## Run anywhere

dr-hands works on macOS and Linux, from any shell and any terminal. It assumes only mise and a signed-in GitHub CLI. mise installs everything else.

## Everything is code

Cloud resources come from code, not clicks. A one-time manual step is fine when the docs spell it out.

## Keep you out of the repository

Personal settings live in `mise.local.toml`. Secrets live in your own secret store, through fnox. Neither goes into git.

## Done means proven

A feature is done when its scenarios pass against real services, and the evidence survives cleanup. A test on a stand-in, such as a container in place of a real Linux machine, lists what it did not cover.

## Build only what is needed

We add a feature when a real triage needs it. We remove code we no longer use, with no traces left.
