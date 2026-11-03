#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 1 && ( "$1" == --help || "$1" == -h ) ]]; then
    cat <<'HELP'
Usage: dr-hands lint-report FILE

Validate a report against schemas/report.schema.json without rendering or fetching
its contents. Enforce UTF-8, 1 MiB maximum, unique keys, and strict JSON values.
Exit 0 means valid structure, not safe content. Exit 1 means invalid input;
exit 2 means usage, dependency, or file-access failure.

Requires Python 3 and the dependency in requirements-lint.txt. Install it into
an isolated Python environment; this command does not install or fetch packages.
HELP
    exit 0
fi

exec python3 "${DR_HANDS_ROOT:?}/lib/lint-report.py" "$@"
