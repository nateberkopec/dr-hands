# Gravity machine

A gravity machine lets an attacker framework attack a disposable target implementation without giving either one a way out.

This page is the top of the acceptance pyramid. Read it first. If these eight claims describe the right system, follow them one layer down into the [threat model](SECURITY.md#gravity-machine), then into the [executable behavior](https://github.com/nateberkopec/dr-hands/blob/archive/design-stack-before-spec-only/features/gravity.feature), and finally into the [formal models](formal/README.md). Each layer keeps the same claim IDs and adds detail.

## The system

One gravity run creates a chamber with two AWS machines:

```text
operator
   |
   | EC2 Instance Connect Endpoint
   v
attacker framework ---- declared ports ----> target service
  example: ARTEX                         example: RubyGems.org
   |
   | forced AWS-managed TLS egress
   v
OpenRouter
```

The attacker role runs one framework and its private state. The target role runs one production-shaped service and its dependencies. Both machines, both operating systems, every container, every dependency, the model, and every byte they produce are hostile. The chamber boundary is AWS's hypervisor and network, not Docker or a guest firewall.

The first reference pair is [ARTEX](https://github.com/BaaRai/ARTEX) as the attacker framework and [RubyGems.org](https://github.com/rubygems/rubygems.org) as the target. RubyGems.org runs with its Rails application, PostgreSQL, Memcached, and OpenSearch. These are replaceable implementations of stable roles, not fixed chamber components. The first version does not accept arbitrary Internet targets, production data, or a production credential.

## The eight claims

### G1. The chamber is useful

The attacker framework reaches its target, exercises a harmless test-only canary weakness, and leaves evidence that agrees with the target log. The reference check uses ARTEX and RubyGems.org; its canary belongs to the gravity fixture, not upstream RubyGems.org. A disconnected system does not pass.

### G2. Guest root is inside the boundary

Root on either machine is an initial condition, not a security failure. Replacing routes, DNS, firewalls, proxies, containers, and attacker-framework policy cannot widen what the chamber can reach.

### G3. Only three paths cross trust boundaries

The operator can initiate SSH to the attacker through EC2 Instance Connect Endpoint. The attacker can reach the target on declared ports. The attacker can reach OpenRouter through AWS-managed filtering. The target can use declared callback ports. There is no other path.

### G4. Inference has a hard edge

Each run has one OpenRouter key with a model allowlist, no hosted tools, zero data retention, a dollar limit, and an expiry. AWS egress policy admits the exact OpenRouter TLS destination, not general HTTPS.

### G5. The chamber holds nothing valuable

Neither machine has AWS, GitHub, registry, production, or operator credentials. The target has synthetic data and fake integrations. The attacker's only secret is its own limited OpenRouter key.

### G6. Hostile output stays inert

An attacker framework's web UI is not exposed. Status comes from trusted control-plane data. Evidence is copied to fixed local filenames as opaque bytes; it is not printed, extracted, rendered, or opened automatically.

### G7. Expiry removes authority before cleanup

At twelve hours, inference and management authority stop working even if deletion is delayed. Revoked authority cannot become live again through a retry or a stale operation.

### G8. Teardown proves absence

Removal is complete only after AWS and OpenRouter report every run-owned resource and capability absent. Partial provisioning converges on the same cleanup path. One run cannot remove another, and trusted local evidence survives.

## Trusted set

The trusted set is deliberately limited to:

- the operator workstation and OpenSSH client;
- AWS IAM, EC2 isolation, VPC enforcement, Instance Connect, DNS Firewall, and Network Firewall;
- OpenRouter's workspace, key, budget, and expiry enforcement.

Attacker and target implementations—including ARTEX, RubyGems.org, and their dependencies—guest Linux, Docker, package code, guest policy, target contents, and findings are not trusted. If a design needs another trusted component, it does not satisfy this proposal.

## Verify from here

1. Read the numbered assumptions and invariants in [Security](SECURITY.md#gravity-machine).
2. Read the real-service scenarios in [the gravity feature](https://github.com/nateberkopec/dr-hands/blob/archive/design-stack-before-spec-only/features/gravity.feature).
3. Read the model guide, traceability table, and limits in [Formal verification](formal/README.md).
4. Run `mise run verify-formal` to check Alloy and TLA+.

The formal checks prove properties of bounded models under stated assumptions. The feature scenarios are what eventually prove that the implementation matches those models.
