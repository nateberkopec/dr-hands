# dr-hands

Isolated machines for triaging private GitHub Security Advisory reports with coding agents. Each report gets its own disposable box with no GitHub or provider credentials; the agents are the hands, and every GitHub action stays with me. [PLAN.md](PLAN.md) is the design.

```fish
mise run add puma/puma GHSA-xxxx-xxxx-xxxx   # boot a box, load the report, open a locked-down terminal
mise run attach GHSA-xxxx-xxxx-xxxx          # reopen the terminal
mise run refresh GHSA-xxxx-xxxx-xxxx         # push the advisory, comments and private fork again after a reply
mise run rm GHSA-xxxx-xxxx-xxxx              # destroy one box
mise run down                                # destroy every box and sweep leftovers
mise run image                               # rebuild the box image
```

`add` fetches the advisory with `gh`, prints what the scanner flags, and opens herdr on the box. The agent there starts from `~/.pi/agent/AGENTS.md` and writes `~/work/VERDICT.md`. Boxes power off and terminate after 12 hours, and their broker keys expire with them.

Secrets come from 1Password through `op run`: the AWS deploy key, the Tailscale OAuth client, and, on broker, the broker. The inference broker is deployed by homelab's `its broker playbook`.
