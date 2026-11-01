function fetch_advisory
    set -l github_repo (string trim < $state/github-repo)
    gh api repos/$github_repo/security-advisories/$report >$state/advisory.json.new
    and gh api --paginate repos/$github_repo/security-advisories/$report/comments --jq '.[]' >$state/comments.json.new
    or begin
        echo "could not fetch $report from $github_repo" >&2
        return 1
    end
    test (jq -r .ghsa_id $state/advisory.json.new) = $report
    or begin
        echo "GitHub returned a different advisory" >&2
        return 1
    end
    jq --slurpfile comments $state/comments.json.new '.thread = ($comments | map({author: .user.login, author_association, created_at, body}))' $state/advisory.json.new >$state/advisory.json
    or return 1
    rm $state/advisory.json.new $state/comments.json.new
    ruby $repo/lib/scan.rb $state/advisory.json $state/advisory.md >$state/findings.txt; or return 1
    cat $state/findings.txt
    fetch_fork
end

function fetch_fork
    set -l fork (jq -r '.private_fork.full_name // empty' $state/advisory.json)
    if test -z "$fork"
        rm -rf $state/fork.git $state/fork.bundle
        return 0
    end
    string match -rq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -- $fork
    or begin
        echo "unexpected private fork name $fork" >&2
        return 1
    end
    set -lx GIT_TERMINAL_PROMPT 0
    set -l git git -c credential.helper= -c 'credential.helper=!gh auth git-credential' -c core.hooksPath=/dev/null
    if test -d $state/fork.git
        $git -C $state/fork.git remote update --prune >/dev/null
    else
        $git clone --quiet --mirror https://github.com/$fork.git $state/fork.git
    end
    and $git -C $state/fork.git bundle create $state/fork.bundle --all 2>/dev/null
    or begin
        echo "could not mirror the private fork $fork" >&2
        return 1
    end
    echo "  private fork $fork mirrored; its branches will be fork/* on the box"
end

function push_advisory
    box_ssh 'mkdir -p ~/work && cat > ~/work/advisory.json' <$state/advisory.json
    and box_ssh 'cat > ~/work/advisory.md' <$state/advisory.md
end

function push_fork
    test -f $state/fork.bundle; or return 0
    set -l name (string split / -- (string trim < $state/github-repo))[2]
    box_ssh 'cat > ~/work/fork.bundle' <$state/fork.bundle
    and box_ssh "git -C ~/work/$name fetch --quiet --prune ~/work/fork.bundle '+refs/heads/*:refs/remotes/fork/*'"
end
