#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands remove RUN

Cancel further work and revoke run-scoped inference/management authority first.
Destroy every inventoried guest-writable runtime resource, including storage and
network resources, then confirm absence through external provider observations.
Attempt runtime deletion even if revocation fails, accumulate all failures, and
never certify removal until both authority and resources are confirmed absent.
Use original provider/resource/generation identities, not today's default config.
Partial provisioning uses this same idempotent path. Do not wait for human approval.
Failures remain visible and resumable; never report removed because a request was
sent, a process exited, or a local record disappeared.
Opaque explicit exports and controller metadata survive. Previously transmitted
data cannot be recalled. A workflow handler is not the only cleanup mechanism:
externally enforced expiry and reconciliation cover controller loss.
HELP
