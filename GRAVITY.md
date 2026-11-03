# Gravity machine

A gravity machine lets ARTEX attack a disposable copy of a production-shaped service without giving either one a way out.

This page is the top of the acceptance pyramid. Read it first. If these eight claims describe the right system, follow them one layer down into the [threat model](SECURITY.md#gravity-machine), then into the [executable behavior](features/gravity.feature), and finally into the [formal models](formal/README.md). Each layer keeps the same claim IDs and adds detail.

## The system

One gravity run creates a chamber with two AWS machines:

```text
operator
   |
   | EC2 Instance Connect Endpoint
   v
ARTEX attacker ---- declared ports ----> RubyGems.org target
   |
   | forced AWS-managed TLS egress
   v
OpenRouter
```

ARTEX and its PostgreSQL run on the attacker. The RubyGems.org Rails application, PostgreSQL, Memcached, and OpenSearch run on the target from the upstream development setup. Both machines, both operating systems, every container, every dependency, the model, and every byte they produce are hostile. The chamber boundary is AWS's hypervisor and network, not Docker or a guest firewall.

The first version supports this one [RubyGems.org](https://github.com/rubygems/rubygems.org) target. It does not accept arbitrary Internet targets, production data, or a production credential.

## The eight claims

### G1. The chamber is useful

ARTEX reaches a real RubyGems.org Rails service, exercises a harmless test-only canary weakness, and leaves evidence that agrees with the application log. The canary belongs to the gravity fixture, not upstream RubyGems.org. A disconnected system does not pass.

### G2. Guest root is inside the boundary

Root on either machine is an initial condition, not a security failure. Replacing routes, DNS, firewalls, proxies, containers, and ARTEX policy cannot widen what the chamber can reach.

### G3. Only three paths cross trust boundaries

The operator can initiate SSH to the attacker through EC2 Instance Connect Endpoint. The attacker can reach the target on declared ports. The attacker can reach OpenRouter through AWS-managed filtering. The target can use declared callback ports. There is no other path.

### G4. Inference has a hard edge

Each run has one OpenRouter key with a model allowlist, no hosted tools, zero data retention, a dollar limit, and an expiry. AWS egress policy admits the exact OpenRouter TLS destination, not general HTTPS.

### G5. The chamber holds nothing valuable

Neither machine has AWS, GitHub, registry, production, or operator credentials. The target has synthetic data and fake integrations. The attacker's only secret is its own limited OpenRouter key.

### G6. Hostile output stays inert

The ARTEX web UI is not exposed. Status comes from trusted control-plane data. Evidence is copied to fixed local filenames as opaque bytes; it is not printed, extracted, rendered, or opened automatically.

### G7. Expiry removes authority before cleanup

At twelve hours, inference and management authority stop working even if deletion is delayed. Revoked authority cannot become live again through a retry or a stale operation.

### G8. Teardown proves absence

Removal is complete only after AWS and OpenRouter report every run-owned resource and capability absent. Partial provisioning converges on the same cleanup path. One run cannot remove another, and trusted local evidence survives.

## Trusted set

The trusted set is deliberately limited to:

- the operator workstation and OpenSSH client;
- AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall;
- OpenRouter's workspace, key, budget, and expiry enforcement.

ARTEX, RubyGems.org, PostgreSQL, Memcached, OpenSearch, guest Linux, Docker, package code, guest policy, target contents, and findings are not trusted. If a design needs another trusted component, it does not satisfy this proposal.

## Verify from here

1. Read the numbered assumptions and invariants in [Security](SECURITY.md#gravity-machine).
2. Read the real-service scenarios in [the gravity feature](features/gravity.feature).
3. Read the model guide, traceability table, and limits in [Formal verification](formal/README.md).
4. Run `mise run verify-formal` to check Alloy and TLA+.

The formal checks prove properties of bounded models under stated assumptions. The feature scenarios are what eventually prove that the implementation matches those models.
