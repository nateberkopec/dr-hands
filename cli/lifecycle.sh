#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands lifecycle STAGE

Bundled stages: validate, approve, provision, deliver, start, observe,
               revoke, destroy, verify-removed.

validate: Freeze/validate inventory, classify the three legs, reject private+web.
approve: Obtain consent for the exact images, inputs, recipients, budget, expiry.
provision: Idempotently create isolated resources with immutable Run/generation IDs.
deliver: Copy only declared inputs to fixed paths after external policy is active.
start: Start image-defined roles through fixed interfaces, without local hooks.
observe: Read bounded control-plane status; guest output remains opaque.
revoke: Stop new work and invalidate run authority; never require approval.
destroy: Delete all inventoried runtime resources, including partial creations.
verify-removed: Confirm external absence and record success only when observed.

No stage executes here. The YAML is engine-native documentation, not a custom
user hook surface. Dagu is a standalone runner; its web UI, scheduler, distributed
workers, arbitrary command overrides, and automatic whole-run retries are not
part of dr-hands. Guest agents run inside images, never in the lifecycle engine.
The engine's exit handler cannot guarantee cleanup after SIGKILL or laptop loss.
An independent remove/resume path reconciles state and externally enforced expiry.
HELP
