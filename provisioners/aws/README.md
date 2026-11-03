# AWS provisioner

AWS is the only provisioner bundled with dr-hands. It implements protocol version 1 for box and Gravity Runs. Terraform is an implementation detail inside this package; core orchestration sees only normalized requests, results, and management commands.

## Trust-role mapping

| Provisioner trust role | AWS implementation |
|---|---|
| Control plane | AWS IAM and service APIs |
| Compute boundary | EC2 isolation and encrypted EBS |
| Network boundary | VPC routing and security controls; DNS Firewall and Network Firewall for Gravity |
| Management ingress | Tailscale for boxes during migration; EC2 Instance Connect for Gravity |

The box transport remains narrower than guest cloud authority: its Tailscale key is single-use and short-lived, and provider credentials never enter the guest. Gravity does not install Tailscale in either hostile role.

## Package shape

```text
provisioners/aws/
├── provisioner          # protocol executable
├── terraform/
│   ├── box/             # one-role triage infrastructure
│   └── gravity/         # attacker and target chamber
└── image/               # provider image build and fingerprint
```

The runtime implementation will move the existing AWS Terraform and image code behind this boundary without changing the protocol. No core command may address a Terraform resource, workspace, state file, AMI, instance, VPC, subnet, route, security group, or firewall directly.

## Command mapping

- `describe` returns the trust-role declaration and supports `box` and `gravity`.
- `doctor` checks the caller identity, configured region, quotas, Terraform, image access, an external read-only observer identity, and the AWS services required by the requested mode.
- `image fingerprint` covers image files, selected stacks, AWS architecture, and bootstrap settings.
- `image build` produces an immutable AMI reference and records its fingerprint.
- `create` applies isolated Terraform state for one Run generation and tags every created resource.
- `inspect` reads Terraform output plus normal AWS control APIs and normalizes them.
- `exec` uses the mode's management ingress without placing AWS credentials in a guest.
- `observe` uses the read-only observer identity and service APIs, not Terraform state.
- `destroy` applies Terraform destruction, then discovers and removes labeled stragglers.
- `verify-absent` queries each supported AWS resource class through the read-only identity.
- `sweep` discovers expired deadline tags and removes each generation independently.

## Identity and labels

The mutating identity may create and remove only dr-hands resources in the configured account and region. The observer identity has list, describe, and tag-reading permissions only. Evidence records both AWS account IDs and role ARNs.

Every resource supports these logical labels, encoded as AWS tags where the service permits:

| Label | Meaning |
|---|---|
| `dr-hands:run-id` | Stable provider-neutral Run ID |
| `dr-hands:generation` | Immutable Run generation |
| `dr-hands:expires-at` | Cleanup deadline |
| `dr-hands:role` | `box`, `attacker`, `target`, or an enclosing chamber resource |
| `dr-hands:managed` | Fixed ownership marker |

A resource class that cannot carry tags must be discoverable through a tagged parent and included in that parent's normalized observation. Unsupported or unobservable resource classes cannot be used.

## External observation

The normalized resource set includes compute, volumes, network interfaces, addresses, VPCs, subnets, routes, gateways, endpoints, security controls, firewall resources, and provider-side management grants created for the Run. Observation uses fresh paginated API calls and fails closed on throttling, truncation, access denial, or an unknown resource type.

Terraform success is never cleanup proof. The final absence receipt comes from the read-only observer after all service-specific deletion states disappear.

## Real-service evidence

AWS conformance uses disposable accounts or an isolated test account, unique Run IDs, bounded deadlines, and a sweeper installed before creation. Tests inject failure after each provisioning operation, delete local state, retry operations, create an externally visible straggler, and interleave two Runs. Evidence retains the request, normalized results, redacted command logs, observer identity, timestamps, and the final empty observation.

The deterministic fixture exercises the same core protocol but is not listed as a provisioner and cannot satisfy these AWS checks.

## Limits

This mapping assumes AWS behaves according to the services named in [SECURITY.md](../../SECURITY.md). It does not prove AWS correct, make another cloud equivalent, or let a custom provisioner inherit AWS evidence.
