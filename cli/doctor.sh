#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands doctor --workflow NAME

Resolve only the selected infrastructure/inference aliases through the exact
fnox file. Check authentication, immutable image availability, inference models,
and externally enforced policy support with non-mutating service APIs.
Never create resources, mint run credentials, build images, or make billed
inference requests. Do not print secret values or hostile service responses.
Report checks that read-only probes cannot establish instead of claiming success.
Missing, expired, or unsupported required capabilities block provisioning.
Credential authentication alone does not prove isolation, expiry, or cleanup.
HELP
