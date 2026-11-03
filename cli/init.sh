#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands init

Copy config.example.toml to adjacent config.toml and fnox.example.toml to
fnox.local.toml. Preflight both destinations; refuse to overwrite either.
Do not resolve credentials, log in, install tools, contact services, or provision.
The examples are tracked; personal files are ignored. Edit their documented
fields, choose immutable images, and classify every image/input before checking.
HELP
