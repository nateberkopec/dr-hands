#!/usr/bin/env fish

set root (cd (status dirname)/..; and pwd)
source $root/formal/lib.fish
set scratch (mktemp -d /tmp/dr-hands-formal-harness.XXXXXX); or exit 1
function cleanup --on-event fish_exit
    rm -rf "$scratch"
end

printf 'known bytes\n' >$scratch/source
set expected (sha256_digest $scratch/source); or exit 1
cp $scratch/source $scratch/valid
fetch_verified unused $scratch/valid $expected; or exit 1

cp $scratch/source $scratch/mismatch
fetch_verified unused $scratch/mismatch 0000000000000000000000000000000000000000000000000000000000000000 >/dev/null 2>&1
and exit 1
test ! -e $scratch/mismatch; or exit 1

printf 'unverified\n' >$scratch/failure
function shasum
    return 7
end
fetch_verified unused $scratch/failure $expected >/dev/null 2>&1
and exit 1
functions -e shasum
test ! -e $scratch/failure; or exit 1

printf 'formal harness self-test passed\n'
