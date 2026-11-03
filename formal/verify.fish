#!/usr/bin/env fish

set root (cd (status dirname)/..; and pwd)
set tools $root/tmp/formal/tools
set output $root/tmp/verify/formal
mkdir -p $tools $output

function fetch_verified
    set url $argv[1]
    set path $argv[2]
    set expected $argv[3]
    if not test -f $path
        curl -fsSL $url -o $path.tmp; or return 1
        mv $path.tmp $path
    end
    set actual (shasum -a 256 $path | string split ' ')[1]
    if test $actual != $expected
        rm -f $path
        echo "checksum failed for $url" >&2
        return 1
    end
end

set alloy $tools/alloy-6.2.0.jar
set tla $tools/tla2tools-1.7.4.jar
fetch_verified https://repo1.maven.org/maven2/org/alloytools/org.alloytools.alloy.dist/6.2.0/org.alloytools.alloy.dist-6.2.0.jar $alloy 6037cbeee0e8423c1c468447ed10f5fcf2f2743a2ffc39cb1c81f2905c0fdb9d; or exit 1
fetch_verified https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar $tla 936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88; or exit 1

rm -rf $output/alloy $output/tlc-lifecycle-states $output/tlc-isolation-states $output/tlc-crash-states
mkdir -p $output/alloy $output/tlc-lifecycle-states $output/tlc-isolation-states $output/tlc-crash-states

java -jar $alloy exec --command '*' --solver sat4j --force --output $output/alloy $root/formal/alloy/gravity.als >$output/alloy.log 2>&1
or begin
    cat $output/alloy.log
    exit 1
end
cat $output/alloy.log

java -XX:+UseParallelGC -jar $tla -config $root/formal/tla/GravityLifecycle.cfg -workers auto -coverage 1 -metadir $output/tlc-lifecycle-states $root/formal/tla/GravityLifecycle.tla >$output/tla-lifecycle.log 2>&1
or begin
    cat $output/tla-lifecycle.log
    exit 1
end
cat $output/tla-lifecycle.log

java -XX:+UseParallelGC -jar $tla -config $root/formal/tla/GravityIsolation.cfg -workers auto -coverage 1 -metadir $output/tlc-isolation-states $root/formal/tla/GravityLifecycle.tla >$output/tla-isolation.log 2>&1
or begin
    cat $output/tla-isolation.log
    exit 1
end
cat $output/tla-isolation.log

java -XX:+UseParallelGC -jar $tla -config $root/formal/tla/GravityCrash.cfg -workers auto -coverage 1 -metadir $output/tlc-crash-states $root/formal/tla/GravityLifecycle.tla >$output/tla-crash.log 2>&1
or begin
    cat $output/tla-crash.log
    exit 1
end
cat $output/tla-crash.log
