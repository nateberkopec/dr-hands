#!/usr/bin/env bash

show_spec() {
    cat
    if [[ $# -eq 1 && ( "$1" == --help || "$1" == -h ) ]]; then
        return 0
    fi
    printf '%s\n' 'Documentation stub: no action performed.' >&2
    return 3
}
