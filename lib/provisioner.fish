function resolve_provisioner --argument-names spec
    test -n "$spec"; or set spec aws
    if test "$spec" = aws
        set spec $repo/provisioners/aws/provisioner
    else
        string match -q '/*' -- "$spec"; or fail "DR_HANDS_PROVISIONER must be 'aws' or an absolute executable path"
    end
    set -l candidate $spec
    set spec (realpath $candidate 2>/dev/null); or fail "provisioner does not exist: $candidate"
    test -x $spec; or fail "provisioner is not executable: $spec"
    printf '%s\n' $spec
end

function configured_provisioner_spec
    set -l spec aws
    set -q DR_HANDS_PROVISIONER; and test -n "$DR_HANDS_PROVISIONER"; and set spec $DR_HANDS_PROVISIONER
    if test "$spec" = aws
        printf 'aws\n'
    else
        resolve_provisioner $spec >/dev/null; or return 1
        printf '%s\n' $spec
    end
end

function invoke_provisioner --argument-names spec
    set -e argv[1]
    set -l executable (resolve_provisioner $spec); or return 1
    set -lx DR_HANDS_REPO $repo
    command $executable $argv
end

function current_provisioner
    set -l spec (configured_provisioner_spec); or return 1
    invoke_provisioner $spec $argv
end

function run_provisioner
    set -l spec aws
    test -f $state/provisioner; and set spec (string trim < $state/provisioner)
    invoke_provisioner $spec $argv
end
