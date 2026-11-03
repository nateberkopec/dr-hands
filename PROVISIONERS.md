# Provisioners

A provisioner is trusted local code that turns a provider-neutral Run request into disposable infrastructure. dr-hands ships one provisioner, AWS. A third party can replace it without changing report intake, orchestration, inference authority, evidence, or lifecycle policy.

This page is the acceptance contract. The linked layers add detail.

## P1. One narrow plug-in boundary

Core orchestration invokes a versioned executable protocol. It does not import Terraform, an AWS SDK, or provisioner code. A custom provisioner is selected by configuration, not a core patch.

## P2. Provider-neutral requests

Requests name a Run, generation, deadline, role graph, image references, management key, and network policy. They never contain regions, instance types, VPCs, security groups, or another provider's vocabulary.

## P3. Opaque implementation

A provisioner may use Terraform, another infrastructure tool, or direct APIs. Its state stays under the Run's provisioner directory. Its resource identifiers and image references are opaque to core orchestration.

## P4. Stable lifecycle

Every provisioner validates, resolves images, creates, inspects, executes management commands, observes resources externally, destroys, verifies absence, and sweeps expired Runs. Create and destroy are idempotent. Every operation is scoped to one Run generation.

## P5. Independent observation

A provisioner cannot prove cleanup by reading its own state. `observe` and `verify-absent` query the infrastructure control plane through a read-only view. Local state may be missing or wrong.

## P6. The boundary stays outside guests

A provisioner declares the external compute, network, management, and control-plane mechanisms that enforce isolation. Guest software and the operator workstation cannot be the compute boundary. Replacing AWS may change the named services, but not Gravity's trust roles or invariants.

## P7. Failure becomes cleanup

Malformed output, stale operations, partial creation, lost local state, timeouts, and provider rejection enter the same removal path. Tagged deadlines and an external sweep let cleanup finish after the original controller disappears.

## P8. One implementation, one contract

AWS is the only bundled provisioner and the only implementation tested against a real infrastructure service. A deterministic fixture proves protocol dispatch and contract behavior; it is not presented as a second provisioner.

## Review path

1. Read [the detailed protocol](docs/provisioners.md).
2. Read [the executable scenarios](features/provisioners.feature).
3. Read [the AWS mapping](provisioners/aws/README.md).
4. Read [the security model](SECURITY.md) and [formal traceability](formal/README.md).

## Non-goals

This specification does not make untrusted provisioners safe, certify a third-party cloud, hide infrastructure cost, or claim that one provider's controls are equivalent to another's. It does not add a second bundled implementation.
