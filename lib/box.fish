set -g repo (realpath (status dirname)/..)
set -g ssh_key ~/.ssh/dr-hands_ed25519
set -g broker_host broker

function fail
    echo (status basename): $argv >&2
    exit 1
end

function parse_report --argument-names id
    string match -rq '^GHSA(-[a-z0-9]{4}){3}$' -- (string lower -- $id)
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
    set -l script 'T=$(sed -n "s/^ADMIN_TOKEN=//p" ~/dr-hands-broker/admin.env)
curl -sf -X "$1" "http://127.0.0.1:3461$2" -H "authorization: Bearer $T" ${3:+-d "$3"}'
    printf '%s\n' $script | ssh $broker_host bash -s -- (string escape -- $method $path $body)
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
    tailscale_api GET '/tailnet/-/devices' | jq -c --arg prefix "$prefix" '.devices[] | select((.tags // []) | index("tag:ghsa")) | select(.name | startswith($prefix))'
end

function terraform_box
    terraform -chdir=$repo/box $argv
end

function remove_box
    set -l failed
    if terraform_box workspace list | string trim -c ' *' | string match -q -- $box
        terraform_box workspace select $box >/dev/null
        TF_VAR_tailnet_auth_key=unused terraform_box destroy -auto-approve -input=false \
            -var report=$box -var ami=unused -var ssh_public_key=unused >/dev/null
        or set failed $failed "terraform destroy"
        terraform_box workspace select default >/dev/null
        test -z "$failed"; and terraform_box workspace delete $box >/dev/null
    end
    for device in (tailnet_devices $box.)
        tailscale_api DELETE /device/(echo $device | jq -r .id) >/dev/null
        or set failed $failed "tailnet device $(echo $device | jq -r .name)"
    end
    broker DELETE /grants/$box >/dev/null
    or set failed $failed "broker key"
    if test -n "$failed"
        echo "$report: could not remove: "(string join ', ' $failed) >&2
        return 1
    end
    rm -rf $state
    echo "$report: removed"
end
