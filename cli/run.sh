#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands run --workflow NAME [--report PATH]

Use the bundled deterministic lifecycle in workflows/lifecycle.yaml. Users
select images and declared inputs, not a graph, startup commands, entrypoint
overrides, or lifecycle hooks. Images are built outside the run and implement
fixed role interfaces; target services remain inside the hostile boundary.

Before provisioning, freeze and show an inventory: immutable image identities,
all image layers' sensitivity, input names/digests/destinations/sensitivity,
network policy, inference recipients, budget, and expiry. Inputs default private.
Reports use /run/dr-hands/inputs/report.json; source trees use
/run/dr-hands/inputs/source. No live host mounts or production credentials.

Show the three legs: private data, hostile content, and external communication.
Hostile content/root compromise is assumed for every run. Public-http plus
private data is forbidden, not approvable. Use separate public browsing and
private analysis runs. No private-to-public data transfer is supported.
Configured inference-provider disclosure is accepted and shown separately from
general web egress; zero retention does not mean no disclosure.

Require explicit approval of this exact inventory before creating resources.
Revalidate after approval; a material change requires a new inventory/approval.
Provision isolated roles, deliver declared inputs, start their image-defined
roles in the fixed lifecycle, and observe results through trusted status APIs.
Never run a user's local startup/pre-agent script or interpolate report text
into a command. Guest root can read all accessible inputs and start processes.

Exports require explicit operator action. Completion, failure, cancellation, or
expiry routes to removal without another approval. A controller crash may pause
orchestration while guest work continues; externally enforced expiry still holds.
Inference and cloud administration credentials never enter guests or engine logs.
HELP
