# Setup

You do this once. It takes about an hour, most of it waiting for the image to build.

## 1. Tools

Clone the repository, then install its tools and sign in:

```fish
mise install
gh auth login
op signin
```

## 2. AWS

dr-hands runs boxes in their own AWS member account. Its deploy key can manage EC2 in one region and nothing else. You never give dr-hands your root credentials.

Sign in as the root user of your AWS Organization's management account, then run the bootstrap in your own terminal:

```fish
aws login
mise run bootstrap-aws --email you+dr-hands@example.com
```

The bootstrap:

- creates a `dr-hands` member account
- creates a deploy user with the policy in `aws/deploy-policy.json`, limited to `DR_HANDS_REGION`
- saves the deploy key straight to 1Password as `Private/dr-hands-aws-deploy`, without printing it
- sets a monthly budget alert ($50 by default), default disk encryption, and metadata service defaults

Options: `--create-organization` if you don't have an Organization yet, `--budget`, `--alert-email`, and `--vault` for a different 1Password vault. If you change the vault, update `op.env` to match.

## 3. Tailscale

Add a tag for boxes, and grants that let boxes reach only the broker. Replace the broker and owner with your own:

```jsonc
"tagOwners": {
  "tag:ghsa": ["autogroup:admin"],
},
"grants": [
  { "src": ["tag:ghsa"],        "dst": ["tag:broker"], "ip": ["tcp:3460"] },
  { "src": ["you@example.com"], "dst": ["tag:ghsa"],   "ip": ["tcp:22"] },
],
"tests": [
  { "src": "tag:ghsa", "accept": ["tag:broker:3460"], "deny": ["tag:broker:22", "tag:broker:3461", "tag:ghsa:22"] },
],
```

Check that no broader grant covers `tag:ghsa`, such as one for `autogroup:tagged` or `*`.

Then create an OAuth client with the `devices:core` and `auth_keys` write scopes, limited to `tag:ghsa`. Save it in 1Password, with the client ID as `username` and the secret as `credential`. Then point the `TAILSCALE_OAUTH_*` lines in `op.env` at that item.

## 4. The broker

The broker runs in Docker on a machine on your tailnet. It needs:

- [Meridian](https://github.com/rynfar/meridian), reachable from the container, for Claude and ChatGPT subscriptions. For ChatGPT, run Meridian with `MERIDIAN_CHATGPT_CREDENTIALS=owned` and add a dedicated seat with `meridian profile add <name> --chatgpt --headless`.
- A Vercel AI Gateway key with a spending limit

Build the image from `src/broker` and configure it with these variables:

| Variable | Meaning |
|---|---|
| `ADMIN_TOKEN` | A long random secret for the admin port. Keep it in a file on the broker host. |
| `MERIDIAN_URL`, `MERIDIAN_API_KEY` | Meridian's address and API key |
| `VERCEL_API_KEY` | The Vercel AI Gateway key |
| `CLAUDE_MODELS`, `CHATGPT_MODELS`, `VERCEL_MODELS` | Comma-separated models each route allows |
| `MAX_TOKENS_PER_GRANT` | Token budget per report. The default is 20,000,000. |
| `MAX_CONCURRENCY` | Requests one report may run at once. The default is 6. |
| `BROKER_HOST`, `DATA_DIR` | Use `0.0.0.0` and a volume such as `/data` inside a container. |

A Compose service for it:

```yaml
services:
  broker:
    build: ./src/broker
    restart: unless-stopped
    ports: ["127.0.0.1:3460:3460", "127.0.0.1:3461:3461"]
    env_file: [admin.env, keys.env]
    environment:
      BROKER_HOST: 0.0.0.0
      DATA_DIR: /data
      MERIDIAN_URL: http://meridian:3456
      CLAUDE_MODELS: claude-opus-5-5
      CHATGPT_MODELS: gpt-6.1-sol
      VERCEL_MODELS: deepseek/deepseek-v4.1-flash-1017
    volumes: [data:/data]
    read_only: true
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    mem_limit: 512m
    pids_limit: 128
volumes:
  data:
```

The data volume must be writable by uid 1000. Publish only the inference port on the tailnet, and keep the admin port on localhost:

```fish
tailscale serve --bg --https=3460 http://127.0.0.1:3460
```

Your laptop must be able to SSH to this machine. `add` and `rm` run `curl` there against `127.0.0.1:3461`.

## 5. Settings

Point dr-hands at your broker and choose your languages in `mise.local.toml`:

```toml
[env]
AWS_REGION = "us-east-2"
DR_HANDS_REGION = "us-east-2"
DR_HANDS_STACKS = "ruby node"
DR_HANDS_BROKER_HOST = "broker.example.ts.net"
DR_HANDS_BROKER_IP = "100.100.100.100"
DR_HANDS_BROKER_SSH = "broker"
DR_HANDS_BROKER_TOKEN_FILE = "~/dr-hands-broker/admin.env"
```

[configuration.md](configuration.md) explains each setting.

## 6. The image

```fish
mise run image
```

This boots a builder, installs everything, and saves an image in your account. It takes 15 to 20 minutes. When it finishes, `state/image` holds the image ID.

## 7. Your first report

```fish
mise run add owner/repo GHSA-xxxx-xxxx-xxxx
```

A published advisory works as a harmless first test.
