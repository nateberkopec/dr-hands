# Architecture

dr-hands has four parts:

- **Your laptop** runs the `mise` tasks. It holds every credential, fetches reports, and is the only place GitHub actions happen.
- **Boxes**: one AWS instance per report, built from a prebuilt image. A box holds no credential except a short-lived broker key.
- **The broker**: a small HTTP service on a machine you control. It is the only AI endpoint a box can reach.
- **Your tailnet**: connects boxes to the broker and your laptop to boxes, and nothing else.

[SECURITY.md](../SECURITY.md) explains why it is built this way.

## The box

- Each box runs in a separate AWS member account, with no instance profile and an encrypted disk. Instances carry their report ID as a tag.
- The image pins its versions of Debian, mise, herdr, Tailscale, Node, Pi, and the stack toolchains. `bin/image` builds it on a temporary instance and records the image ID in `state/image`.
- The agent runs as the `agent` user, without sudo. Root is used only to set the box up.
- A systemd timer powers the box off after 12 hours. Shutdown terminates the instance.

## Network

The box firewall (nftables) limits only the `agent` user. The agent can reach:

- loopback, which includes the Squid proxy and any server it starts for a proof of concept
- the broker's tailnet address on port 3460

Everything else is refused, including DNS, the internet, the metadata service, and the rest of the tailnet. Replies on connections that are already open, such as your SSH session, are allowed.

Squid allows HTTPS `CONNECT` only to GitHub and the hosts listed by the chosen stacks. Only Squid and `tailscaled` reach the internet. The AWS security group allows outbound HTTPS and Tailscale's UDP ports, and nothing inbound.

Your tailnet policy must let `tag:ghsa` reach the broker's port 3460 and nothing else. It must let your own devices reach `tag:ghsa` on port 22. [docs/setup.md](setup.md) has an example.

## The broker

The broker lives in `src/broker/server.ts`. It is one Node file with no dependencies, and it listens on two ports:

- **3460, inference.** Published on the tailnet through Tailscale Serve.
- **3461, admin.** Bound to localhost. Your laptop reaches it over SSH with the admin token.

Each report gets its own key, minted by `add` and revoked by `rm`. A key expires after at most 12 hours.

For each request, the broker:

- allows only exact routes: `POST /claude/v1/messages`, `GET /claude/v1/models`, `POST /chatgpt/v1/responses` and `POST /vercel/v1/messages`
- allows only the models listed for that route
- limits each report to a few requests at a time, and to a token budget counted from upstream usage. Aborted streams still count.
- sets the session identity from the report ID and strips the client's own session fields. One report can never resume another's conversation.
- replaces client auth with its own upstream key
- on the Vercel route, forwards only known Messages fields and forces no prompt training and US-only inference

Claude and ChatGPT requests go to Meridian, which holds the subscription logins. Vercel requests go to Vercel AI Gateway with a budgeted key.

## Report data in

1. `gh api` on your laptop fetches the advisory and its comment thread.
2. `lib/scan.rb` checks every text field the box will receive. It flags:
   - hidden Unicode characters
   - words that mix Latin with Cyrillic or Greek letters
   - HTML comments, `<details>` blocks, and images
   - links, `curl | sh` commands, and long base64 runs
   - words aimed at an AI or at whoever triages the report

   It writes `advisory.md`, which shows hidden characters as visible markers. The scan is a tripwire, not a filter.
3. If the advisory has a temporary private fork, your laptop mirrors it with `git clone --mirror`. The mirror is never checked out there. The box receives it as a git bundle, and its branches appear as `fork/*` in the clone.
4. The box clones the public repository through Squid.

The agent can edit its copy of the report. The trusted copy and the scan stay on your laptop in `state/<report>/`, and `attach` prints the scan before it connects.

## Booting a box

`add` takes these steps in order. If any step fails, it removes what it created.

1. Create a single-use, ephemeral, pre-approved Tailscale key tagged `tag:ghsa`, valid for 10 minutes.
2. Terraform creates the security group and the instance. The tailnet key is the only secret in its user data.
3. Wait for the box to join the tailnet.
4. Read the SSH host key from the EC2 console and pin it.
5. Turn the metadata service off, and wait until AWS reports it off.
6. Only then send the broker key, the model routes, the report, the clone, and the fork.

## Results out

- You connect with `ssh -F /dev/null` and a pinned known-hosts file, with agent, X11, and port forwarding off.
- `attach` opens a separate Ghostty window with clipboard access, links, images, notifications, and title reports off.
- Tests and proofs of concept run only on the box.
- `mise run patch` saves the `fix` branch as `state/<report>/fix.patch`. It marks files that change tooling, dependencies, or build steps, using `lib/risky-files` and each stack's `risky-files`.
- You apply reviewed patches with `git am` in your own checkout and push them to the private fork yourself. Fixes reach no public branch before the advisory is published.

## Teardown

`rm` destroys the instance and security group, deletes the tailnet device, and revokes the broker key. It then checks that the device and key are gone. If any step fails, it keeps the local state, so you can run it again.

`down` does the same for every report it knows. Then it sweeps AWS, the tailnet, and the broker for anything left behind.

Everything also expires on its own: the instance after 12 hours, the broker key at its expiry, and the tailnet device once it goes idle.

## Acceptance tests

These end-to-end checks against a real box are planned, not yet written:

- The agent user can't resolve DNS. It can't reach the internet, the metadata service, the broker's other ports, or another box.
- The agent user can install a package through Squid, and Squid refuses other hosts.
- The broker refuses unknown routes, unlisted models, and keys that are revoked or expired.
- After `rm`, the instance is terminated, the device is gone, and the key is refused.
