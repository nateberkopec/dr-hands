#!/usr/bin/env bash
set -euo pipefail
source "${DR_HANDS_ROOT:?}/lib/cli-stub.sh"

show_spec "$@" <<'HELP'
Usage: dr-hands check

Validate the selected config, image/input declarations, local paths, and required
fnox alias declarations without resolving secret values or contacting services.
Use the report schema for report inputs. Reject unsupported fields/policies and
mutable image selections. Missing sensitivity is private, never public.
Reject every run combining any private image/input with public-http, even when
the data and network-enabled role are different guests. There is no override.
A valid schema or a public label is not a security certificate.
The examples contain image placeholders; those must be replaced with immutable
references. This command does not execute image contents or workflow graphs.
HELP
