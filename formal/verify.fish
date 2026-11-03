#!/usr/bin/env fish

set root (cd (status dirname)/..; and pwd)
source $root/formal/lib.fish
set tools $root/tmp/formal/tools
set evidence_root $root/tmp/verify/formal
set alloy $tools/alloy-6.2.0.jar
set tla $tools/tla2tools-1.7.4.jar

function require_command
    type -q $argv[1]
    or begin
        echo "$argv[1] is required" >&2
        return 1
    end
end

function doctor
    for command in java curl shasum ruby git
        require_command $command; or return 1
    end
    for model in \
        $root/formal/alloy/gravity.als \
        $root/formal/tla/GravityLifecycle.tla \
        $root/formal/tla/GravityLifecycleMutations.tla
        test -f $model; or begin
            echo "missing $model" >&2
            return 1
        end
    end
    if test -f $alloy
        set digest (sha256_digest $alloy); or return 1
        test "$digest" = 6037cbeee0e8423c1c468447ed10f5fcf2f2743a2ffc39cb1c81f2905c0fdb9d; or return 1
    end
    if test -f $tla
        set digest (sha256_digest $tla); or return 1
        test "$digest" = 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88; or return 1
    end
    echo "formal verification doctor passed"
end

if test (count $argv) -gt 0
    test "$argv[1]" = doctor; or begin
        echo "usage: formal/verify.fish [doctor]" >&2
        exit 2
    end
    doctor
    exit $status
end

doctor; or exit 1
$root/formal/test-verify.fish; or exit 1
mkdir -p $tools $evidence_root
fetch_verified https://repo1.maven.org/maven2/org/alloytools/org.alloytools.alloy.dist/6.2.0/org.alloytools.alloy.dist-6.2.0.jar $alloy 6037cbeee0e8423c1c468447ed10f5fcf2f2743a2ffc39cb1c81f2905c0fdb9d; or exit 1
fetch_verified https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar $tla 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88; or exit 1
doctor; or exit 1

set run_id $DR_HANDS_VERIFY_RUN
if test -z "$run_id"
    set run_id (date -u +%Y%m%dT%H%M%SZ)-$fish_pid
end
string match -rq '^[A-Za-z0-9._-]+$' -- "$run_id"; or begin
    echo "DR_HANDS_VERIFY_RUN contains unsafe characters" >&2
    exit 2
end
set output $evidence_root/$run_id
test ! -e $output; or begin
    echo "formal evidence already exists: $output" >&2
    exit 2
end
mkdir -p $output/alloy
set scratch (mktemp -d /tmp/dr-hands-formal-states.XXXXXX); or exit 1
function cleanup --on-event fish_exit
    rm -rf "$scratch"
end
function cleanup_signal --on-signal INT --on-signal TERM
    rm -rf "$scratch"
    exit 130
end

set sha (git -C $root rev-parse HEAD); or exit 1
set -gx DR_HANDS_VERIFY_SHA $sha
printf '%s\n' $sha >$output/git-sha

java -jar $alloy exec --command '*' --solver sat4j --force --output $output/alloy $root/formal/alloy/gravity.als >$output/alloy.log 2>&1
or begin
    cat $output/alloy.log
    echo "formal evidence retained: $output" >&2
    exit 1
end
cat $output/alloy.log

function run_tlc
    set name $argv[1]
    set config $argv[2]
    set module $argv[3]
    pushd $root/formal/tla >/dev/null
    java -XX:+UseParallelGC -jar $tla -config $config -workers auto -coverage 1 -metadir $scratch/$name $module >$output/$name.log 2>&1
    set result $status
    popd >/dev/null
    if test $result -ne 0
        cat $output/$name.log
        echo "formal evidence retained: $output" >&2
        return $result
    end
    cat $output/$name.log
end

function run_tlc_mutation
    set name $argv[1]
    set config $argv[2]
    pushd $root/formal/tla >/dev/null
    java -XX:+UseParallelGC -jar $tla -config $config -workers auto -metadir $scratch/$name GravityLifecycleMutations.tla >$output/$name.log 2>&1
    set result $status
    popd >/dev/null
    if test $result -eq 0
        cat $output/$name.log
        echo "negative control unexpectedly passed: $name" >&2
        return 1
    end
end

run_tlc tla-lifecycle GravityLifecycle.cfg GravityLifecycle.tla; or exit 1
run_tlc tla-generation GravityGeneration.cfg GravityLifecycle.tla; or exit 1
run_tlc tla-isolation GravityIsolation.cfg GravityLifecycle.tla; or exit 1
run_tlc tla-crash GravityCrash.cfg GravityLifecycle.tla; or exit 1
run_tlc_mutation mutation-premature-removal MutationPrematureRemoval.cfg; or exit 1
run_tlc_mutation mutation-wrong-run-delete MutationWrongRun.cfg; or exit 1
run_tlc_mutation mutation-stale-grant MutationStaleGrant.cfg; or exit 1

ruby $root/formal/check_evidence.rb $output; or begin
    echo "formal evidence retained: $output" >&2
    exit 1
end
cat $output/SUMMARY.md
