# Values

These are the rules we design dr-hands by. The specifications describe the intended behavior. This file says why.

## Problems we solve

Investigating a security report can mean following hostile links, reading malicious instructions, and running attacker-supplied code. Doing that on an operator's workstation puts their credentials, network, and other work at risk. Testing an attacker framework against a live target can infect both the agent and the target.

dr-hands gives that work a disposable boundary. The operator can investigate a report and collect evidence without giving the agent access to their workstation or production systems. It cannot protect the operator's judgment from manipulation by what they read.

## Security first

Every report is infected. We assume the agent has root from the start and the target is infected too, because the agent may infect it at any time. [SECURITY.md](SECURITY.md#what-we-assume) explains the triage threat model, [the gravity threat model](SECURITY.md#gravity-machine), [how dr-hands protects you](SECURITY.md#how-dr-hands-protects-you), and [the risks we accept](SECURITY.md#risks-we-accept). The design rules follow from it:

- **Enforce rules outside the guest.** The agent already has root. Guest configuration is not a security boundary; the rules that matter live outside it: cloud networks, managed access policy, and the OpenRouter workspace.
- **Treat every input as infected.** Report intake accepts structured text, not executable source plugins. A valid report or manifest describes what enters the run; it does not certify safety.
- **Destroy every infected runtime surface.** Draw a clear boundary around all guest-writable resources and run authority. Removal destroys those resources, revokes authority, and confirms absence. Explicitly exported evidence may survive as opaque, still-hostile files. Public-web requests cannot be undone by teardown.

When we accept a new risk, we add it to SECURITY.md.

## Minimize the trusted boundary

The ambition is that escaping dr-hands requires a CVSS 9+ zero-day in battle-tested upstream software or services, such as a provider hypervisor or OpenRouter. This is not a promise about the score or novelty of an unknown exploit. The concrete requirement is that every escape path must cross a named upstream security boundary, and we minimize how many boundaries we assume correct.

Managed services enforce the rules; we do not add a persistent custom control plane. Experiment-local servers and databases are hostile workloads that die with their machines. Misconfiguration and chains of smaller bugs still matter; provider reputation does not prove a deployment secure.

## Run anywhere

dr-hands targets macOS and Linux, from any shell and any terminal. Obtaining reports is separate from running them; the core does not require a GitHub login or a particular report source.

## Everything is code

Cloud resources come from code, not clicks. A one-time manual step is fine when the docs spell it out.

## Keep you out of the repository

Personal settings live in ignored `config.toml`, beside tracked `config.example.toml`. Secrets live in your own secret store, through fnox; settings name aliases, not secret values.

Replace infrastructure through provisioners and experiments through declarative workflows, without editing core. Report sources integrate by producing the documented text format, not by running local plugins.
