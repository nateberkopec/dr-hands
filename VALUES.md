# Values

These are the rules we design dr-hands by. The feature files in `features/` say what it does. This file says why.

## Every report is hostile

Strangers write security reports. Some will try to trick the agent, or you. So we treat the agent as the attacker. It gets a shell, but nothing worth stealing.

## The agent is the hands. You are the head.

The agent finds the code path, writes a failing test, and drafts a fix. You read the verdict, run the test, and review every line. You take every GitHub action yourself.

## Enforce rules where a hostile box cannot reach them

A rule on the box holds only until the agent gets root. So the rules that matter live outside the box: cloud firewalls, the tailnet policy, and the OpenRouter workspace. Rules on the box are a second layer.

## Hold nothing worth stealing

A box gets only what one report needs. Its one secret is its own AI key. That key is capped in dollars, limited to allowed models, and dies with the box.

## One box per report, then gone

Each report gets a fresh machine. Removing it leaves nothing behind. Teardown checks its own work and fails loudly when something survives.

## Run no servers of our own

We don't run a gateway, a database, or an always-on machine. Managed services enforce the rules for us. You have nothing to patch between reports.

## Run anywhere

dr-hands works on macOS and Linux, from any shell and any terminal. It assumes only mise and a signed-in GitHub CLI. mise installs everything else.

## Everything is code

Cloud resources come from code, not clicks. A one-time manual step is fine when the docs spell it out.

## Keep you out of the repository

Personal settings live in `mise.local.toml`. Secrets live in your own secret store, through fnox. Neither goes into git.

## Write down the risks we accept

No setup is perfectly safe. When we accept a risk, `SECURITY.md` names it.

## Done means proven

A feature is done when its scenarios pass against real services, and the evidence survives cleanup. A test on a stand-in, such as a container in place of a real Linux machine, lists what it did not cover.

## Build only what is needed

We add a feature when a real triage needs it. We remove code we no longer use, with no traces left.
