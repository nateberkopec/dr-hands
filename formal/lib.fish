function sha256_digest
    set output (shasum -a 256 -- $argv[1] 2>/dev/null)
    or return 1
    set digest (string split ' ' -- $output)[1]
    test -n "$digest"; or return 1
    string match -rq '^[0-9a-f]{64}$' -- "$digest"; or return 1
    printf '%s\n' "$digest"
end

function fetch_verified
    set url $argv[1]
    set path $argv[2]
    set expected $argv[3]
    if not test -f "$path"
        curl -fsSL "$url" -o "$path.tmp"; or return 1
        mv "$path.tmp" "$path"
    end
    set actual (sha256_digest "$path")
    or begin
        rm -f "$path"
        echo "could not verify checksum for $url" >&2
        return 1
    end
    if test "$actual" != "$expected"
        rm -f "$path"
        echo "checksum failed for $url" >&2
        return 1
    end
end
