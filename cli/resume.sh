#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands resume RUN

Read the frozen, non-secret inventory and durable local lifecycle state.
Reconcile provider resources, generation, deadline, and revoked authority before
resuming any operation. Never blindly replay a create/start operation or extend
the original expiry. If authority expired or cleanup started, resume removal only.
Changing config or images cannot change an existing run's identity or permissions.
A missing state record is not proof that no cloud resources remain.

Local orchestration can pause while the laptop is absent; guest work may continue.
No daemon is required. Recovery resumes from observed state, not just a runner's
last successful step. If the state cannot be recovered, use provider-scoped
reconciliation and verified removal rather than recreating the run.
HELP
