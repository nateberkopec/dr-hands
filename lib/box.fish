set -g repo (realpath (status dirname)/..)
set -g ssh_key ~/.ssh/dr-hands_ed25519

function fail
    echo dr-hands: $argv >&2
    exit 1
end

source $repo/lib/provisioner.fish

for setting in DR_HANDS_STACKS DR_HANDS_BROKER_HOST DR_HANDS_BROKER_IP DR_HANDS_BROKER_SSH DR_HANDS_BROKER_TOKEN_FILE
    set -q $setting; or fail "$setting is not set; see docs/configuration.md"
end

function parse_report --argument-names id
    string match -rq '^ghsa(-[a-z0-9]{4}){3}$' -- (string lower -- $id)
    or fail "$id is not a GHSA ID"
    set -g report (string upper -- (string sub -l 4 -- $id))(string lower -- (string sub -s 5 -- $id))
    set -g box (string lower -- $id)
    set -g state $repo/state/$box
end

function box_ssh
    set -l tty -T
    if test "$argv[1]" = -t
        set tty -t
        set -e argv[1]
    end
    ssh $tty -F /dev/null \
        -o User=agent -o IdentityFile=$ssh_key -o IdentitiesOnly=yes -o IdentityAgent=none \
        -o UserKnownHostsFile=$state/known_hosts -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes -o UpdateHostKeys=no \
        -o ForwardAgent=no -o ForwardX11=no -o ClearAllForwardings=yes -o PermitLocalCommand=no \
        -o ControlMaster=no -o ControlPath=none -o ServerAliveInterval=30 -o ConnectTimeout=10 \
        (string trim < $state/ip) -- $argv
end

function broker --argument-names method path body
    set -l script 'f=$4; T=$(sed -n "s/^ADMIN_TOKEN=//p" "${f/#\~/$HOME}")
curl -sf -X "$1" "http://127.0.0.1:3461$2" -H "authorization: Bearer $T" ${3:+-d "$3"}'
    printf '%s\n' $script | ssh $DR_HANDS_BROKER_SSH bash -s -- (string escape -- $method $path "$body" $DR_HANDS_BROKER_TOKEN_FILE)
end

function image_settings
    string match -rq '^[a-z0-9_-]+( [a-z0-9_-]+)*$' -- "$DR_HANDS_STACKS"; or fail "DR_HANDS_STACKS must be stack names separated by spaces"
    for stack in (string split ' ' -- $DR_HANDS_STACKS)
        test -d $repo/stacks/$stack; or fail "there is no stack named $stack in stacks/"
    end
    string match -rq '^[A-Za-z0-9.-]+$' -- "$DR_HANDS_BROKER_HOST"; or fail "DR_HANDS_BROKER_HOST must be a host name"
    string match -rq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' -- "$DR_HANDS_BROKER_IP"; or fail "DR_HANDS_BROKER_IP must be an IPv4 address"
    printf "DR_HANDS_STACKS='%s'\nDR_HANDS_BROKER_HOST='%s'\nDR_HANDS_BROKER_IP='%s'\n" $DR_HANDS_STACKS $DR_HANDS_BROKER_HOST $DR_HANDS_BROKER_IP
end

function image_inputs
    printf '%s\n' $repo/image/build.sh $repo/image/files/*
    for stack in (string split ' ' -- $DR_HANDS_STACKS)
        printf '%s\n' $repo/stacks/$stack/*
    end
end

function tailscale_token
    test -n "$tailscale_access_token"; and return
    set -g tailscale_access_token (curl -sf -d "client_id=$TAILSCALE_OAUTH_CLIENT_ID" --data-urlencode "client_secret=$TAILSCALE_OAUTH_CLIENT_SECRET" https://api.tailscale.com/api/v2/oauth/token | jq -r .access_token)
    test -n "$tailscale_access_token"; or fail "could not get a Tailscale API token"
end

function tailscale_api --argument-names method path
    tailscale_token
    curl -sf -X $method -H "Authorization: Bearer $tailscale_access_token" -H 'Content-Type: application/json' https://api.tailscale.com/api/v2$path $argv[3..]
end

function tailnet_devices --argument-names prefix
    set -l devices (tailscale_api GET '/tailnet/-/devices'); or return 1
    printf '%s\n' $devices | jq -c --arg prefix "$prefix" '.devices[] | select((.tags // []) | index("tag:ghsa")) | select(.name | startswith($prefix))'
end

function box_workspaces
    current_provisioner init; or return 1
    current_provisioner list
end

function remove_box
    set -l failed
    set -lx DR_HANDS_RUN $box
    if test -f $state/provisioner-resource
        set -lx DR_HANDS_RESOURCE (string trim < $state/provisioner-resource)
    end
    run_provisioner init >/dev/null
    or set failed $failed "provisioner initialization"
    run_provisioner destroy >/dev/null
    or set failed $failed "provisioner destroy"
    set -l devices (tailnet_devices $box.); or set failed $failed "list tailnet devices"
    for device in $devices
        tailscale_api DELETE /device/(echo $device | jq -r .id) >/dev/null
        or set failed $failed "tailnet device $(echo $device | jq -r .name)"
    end
    broker DELETE /grants/$box >/dev/null
    or set failed $failed "broker key"

    set -l left (tailnet_devices $box.); or set failed $failed "recheck tailnet devices"
    test -z "$left"; or set failed $failed "tailnet device still present"
    set -l grants (broker GET /grants); or set failed $failed "recheck broker keys"
    printf '%s\n' $grants | jq -e --arg r $box 'any(.[]; .report == $r) | not' >/dev/null
    or set failed $failed "broker key still present"

    if test -n "$failed"
        echo "$report: could not remove: "(string join ', ' $failed) >&2
        return 1
    end
    rm -rf $state
    echo "$report: removed"
end
