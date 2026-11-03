#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands export RUN

Explicitly retrieve declared outputs under fixed local filenames as opaque bytes.
Never render, execute, extract, or interpret guest-supplied paths. No guest-writable
host mounts are exposed. All exported bytes remain hostile after teardown.
If any input/image was private, derived outputs remain private. Export does not
declassify them and cannot feed a public-web run automatically.
Export does not delay expiry or block cancellation/removal. Trusted control-plane
metadata and completed exports survive; runtime resources do not.
HELP
