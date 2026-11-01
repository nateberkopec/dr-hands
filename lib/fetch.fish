function fetch_advisory
    gh api repos/(string trim < $state/github-repo)/security-advisories/$report >$state/advisory.json.new
    or begin
        echo "could not fetch $report from "(string trim < $state/github-repo) >&2
        return 1
    end
    test (jq -r .ghsa_id $state/advisory.json.new) = $report
    or begin
        echo "GitHub returned a different advisory" >&2
        return 1
    end
    mv $state/advisory.json.new $state/advisory.json
    ruby $repo/lib/scan.rb $state/advisory.json $state/advisory.md >$state/findings.txt; or return 1
    cat $state/findings.txt
end

function push_advisory
    box_ssh 'mkdir -p ~/work && cat > ~/work/advisory.json' <$state/advisory.json
    and box_ssh 'cat > ~/work/advisory.md' <$state/advisory.md
end
