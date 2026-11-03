# Provisioner protocol

[PROVISIONERS.md](../PROVISIONERS.md) is the short acceptance contract. This document defines the plug-in surface a third-party implementation must satisfy.

## Boundary

The core owns report intake, Run identity, lifecycle decisions, inference grants, evidence, and user interaction. A provisioner owns infrastructure images, resources, network policy, and management transport. It is trusted local code: it runs as the operator and may use infrastructure credentials. Guest input remains hostile before and after crossing this boundary.

Core never reads Terraform state or interprets a resource identifier. [ADR 0001](adr/0001-provisioners-are-executables.md) records why the contract is an executable rather than a Terraform module. The provisioner never reads a report, mints inference authority, decides whether a report is valid, or changes the Run deadline.

## Selection

`DR_HANDS_PROVISIONER` selects `aws` by default. `aws` resolves to the bundled implementation. Another name resolves through a matching executable setting. The setting suffix uppercases the name and replaces `-` with `_`:

```toml
[env]
DR_HANDS_PROVISIONER = "example"
DR_HANDS_PROVISIONER_EXAMPLE = "/absolute/path/to/dr-hands-provisioner-example"
```

The executable path must be absolute. Before creating infrastructure, dr-hands records the provisioner name, absolute path, protocol version, implementation version, and executable digest. Existing Runs keep that recorded name and path even if current configuration selects another provisioner. A changed implementation version or digest reruns `doctor` and appears in evidence; an incompatible protocol version is refused.

## Invocation

The executable receives one command, fixed flag names, and no shell-evaluated string:

```text
drh-provisioner describe --output FILE
drh-provisioner doctor --output FILE
drh-provisioner image fingerprint --request FILE --output FILE
drh-provisioner image build --request FILE --state DIRECTORY --output FILE
drh-provisioner create --request FILE --state DIRECTORY --output FILE
drh-provisioner inspect --request FILE --state DIRECTORY --output FILE
drh-provisioner exec --request FILE --state DIRECTORY --role ROLE -- COMMAND...
drh-provisioner observe --request FILE --output FILE
drh-provisioner destroy --request FILE --state DIRECTORY --output FILE
drh-provisioner verify-absent --request FILE --output FILE
drh-provisioner sweep --request FILE --output FILE
```

Core creates request and output paths with mode `0600`. Output must be one JSON object written atomically to the exact path. Standard output and standard error are captured as diagnostic evidence and never interpreted as instructions. The executable must not write outside its supplied state directory and output file except through the infrastructure control plane.

`describe` and `doctor` are read-only. `observe` and `verify-absent` do not receive local state: they must query an external read-only view. `exec` is the only command whose trailing arguments are passed to a guest, and core passes them as an argument vector rather than a shell string.

## Description

`describe` returns the compatibility and trust declaration before credentials or infrastructure are used:

```json
{
  "protocolVersion": 1,
  "name": "aws",
  "implementationVersion": "1.0.0",
  "modes": ["box", "gravity"],
  "commands": ["doctor", "image", "create", "inspect", "exec", "observe", "destroy", "verify-absent", "sweep"],
  "trustRoles": {
    "controlPlane": ["AWS IAM", "EC2 API"],
    "computeBoundary": ["EC2 isolation"],
    "networkBoundary": ["VPC", "Route 53 Resolver DNS Firewall", "AWS Network Firewall"],
    "managementIngress": ["EC2 Instance Connect"]
  }
}
```

All fields are required. Every provisioner must declare all four trust roles. Its compute boundary must be remote from the operator workstation. Names are review material, not executable configuration. The machine-readable form is [`description.schema.json`](../provisioners/contract/v1/description.schema.json).

## Run request

Every mutating and observational command receives the same immutable Run identity and desired policy:

```json
{
  "protocolVersion": 1,
  "operationId": "01J...",
  "run": {
    "id": "01J...",
    "generation": 2,
    "mode": "gravity",
    "expiresAt": "2026-11-03T20:00:00Z"
  },
  "roles": [
    {"name": "attacker", "image": "opaque:image-reference"},
    {"name": "target", "image": "opaque:image-reference"}
  ],
  "paths": [
    {"from": "management", "to": "attacker", "service": "ssh"},
    {"from": "attacker", "to": "target", "service": "target"},
    {"from": "attacker", "to": "openrouter", "service": "https"}
  ],
  "managementPublicKey": "ssh-ed25519 ..."
}
```

A box request has one role named `box`. A Gravity request has `attacker` and `target`. Role names, path endpoints, and services come from the protocol vocabulary; arbitrary network destinations are rejected. Images are opaque references returned by the same provisioner. The request contains no provider-specific region, instance, network, or identity concept. [`request.schema.json`](../provisioners/contract/v1/request.schema.json) defines its closed shape and mode-specific roles; path rules receive additional semantic validation.

`operationId` identifies one attempt. `run.id` and `run.generation` identify what that attempt may mutate. A completion for an older generation is recorded and ignored. Repeating an operation with the same identity is idempotent. Reusing an operation identity with different input fails.

## Results

Lifecycle commands return a normalized result:

```json
{
  "protocolVersion": 1,
  "run": {"id": "01J...", "generation": 2},
  "status": "ready",
  "resources": [
    {"id": "opaque:resource-reference", "kind": "compute", "role": "attacker"}
  ],
  "roles": [
    {"name": "attacker", "management": "provisioner-exec"}
  ],
  "observedAt": "2026-11-03T08:01:00Z",
  "observer": {"identity": "opaque:read-only-identity"}
}
```

Allowed statuses are `absent`, `provisioning`, `ready`, `removing`, and `failed`. A failed result also supplies a stable failure code and inert diagnostic message. [`result.schema.json`](../provisioners/contract/v1/result.schema.json) defines the closed result shape. Resource IDs are opaque and may appear only in evidence or later requests to the same provisioner. Results cannot add roles, paths, authority, or time. Unknown fields, wrong Run identity, wrong generation, duplicate resource IDs, absolute local paths, and secret-shaped values fail validation and enter cleanup.

`inspect` reports through the implementation's normal control path and may use local state. `observe` reports provider-visible resources without local state. Core compares their normalized resource sets. A Run becomes ready only after both agree with the request.

## Required behavior

### Doctor and images

`doctor` checks credentials, external observer access, region or placement configuration, quotas, management ingress, and the ability to apply the requested path policy. It makes no resource. `image fingerprint` deterministically covers every image input and provisioner setting. `image build` returns an opaque immutable reference carrying that fingerprint.

### Create and inspect

`create` converges on the requested generation and labels every resource with Run ID, generation, and deadline. Partial creation returns `failed` with the resources known so far. Core immediately calls `destroy`; it does not retry creation in place after an ambiguous result. A later generation may reuse the Run ID only after external absence was verified.

`inspect` is read-only and returns quickly. `ready` means every requested role and path exists, management is possible, no extra path exists, and the external observation agrees.

### Management

`exec` targets one declared role. The provisioner owns the transport and ephemeral provider authorization. It does not expose a durable management credential to a guest. Exit status and byte streams pass through unchanged but are never parsed as protocol output. They remain hostile: control commands capture them, verification retains them as evidence, and only an explicit guarded interactive session may display them.

### Destruction and absence

`destroy` is idempotent and asks the provider to remove every resource belonging to the Run generation, including resources missing from local state. It returns `removing` until provider deletion is externally visible.

`verify-absent` succeeds only when a fresh read-only control-plane query finds no resource for that Run generation. A missing state directory, successful Terraform exit, empty cached result, or accepted deletion request is insufficient.

### Sweep

`sweep` queries deadline labels externally, removes every expired generation, and reports each Run independently. It needs no local Run directory. One malformed or undeletable Run cannot prevent attempts for the others. A sweep never acts on an unexpired generation.

## AWS implementation

[AWS](../provisioners/aws/README.md) is the sole bundled implementation. Its Terraform and image code are private implementation details behind this protocol. Core acceptance tests may not assert Terraform resource addresses or AWS identifiers. AWS acceptance tests additionally use read-only AWS credentials to prove the normalized result against the real control plane.

## Conformance

A provisioner is compatible only when:

1. the deterministic fixture passes every protocol and lifecycle scenario without a core patch;
2. its own real-service suite proves every declared mode and trust role;
3. create, destroy, and sweep survive process interruption and lost local state;
4. an external observer detects an extra or surviving resource;
5. stale and wrong-Run operation mutations are rejected;
6. its evidence names skipped or blocked checks rather than silently omitting them.

Passing fixture tests proves protocol compatibility, not infrastructure isolation. That claim belongs to the implementation's real-service evidence and threat model.

## Protocol evolution

A provisioner declares exactly one integer protocol version. Additive implementation metadata does not change the protocol. New commands, statuses, role semantics, or request fields require a new version. Core rejects a version it does not implement; it does not guess or negotiate down.
