# Setup

You do this once. It takes about an hour, most of it waiting for the image to build.

## 1. Tools

Clone the repository, then install its tools and sign in:

```fish
mise install
gh auth login
op signin
```

## 2. Provisioner

AWS is the bundled provisioner. It runs boxes in their own AWS member account. Its deploy key can manage dr-hands resources in one region and nothing else. You never give dr-hands your root credentials.

Sign in as the root user of your AWS Organization's management account, then run the bootstrap in your own terminal:

```fish
aws login
mise run bootstrap-aws --email you+dr-hands@example.com
```

Add `--create-organization` if you don't have an Organization yet. The bootstrap saves the deploy key to 1Password as `Private/dr-hands-aws-deploy`; pass `--vault` to pick another vault. It also creates a read-only observer identity used to prove readiness and absence independently of Terraform state.

To use a third-party provisioner instead, follow its credential setup, then configure its absolute executable as described in [configuration.md](configuration.md#provisioners). It must pass protocol conformance and its own real-service checks; the fixture suite alone is insufficient.

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

Then create an OAuth client with the `devices:core` and `auth_keys` write scopes, limited to `tag:ghsa`. Save it in 1Password, with the client ID as `username` and the secret as `credential`. Then point dr-hands at both secrets, as shown in [configuration.md](configuration.md#secrets).

## 4. The broker

The broker runs in Docker on a machine on your tailnet. It needs:

- [Meridian](https://github.com/rynfar/meridian), reachable from the container, for Claude and ChatGPT subscriptions. For ChatGPT, run Meridian with `MERIDIAN_CHATGPT_CREDENTIALS=owned` and add a dedicated seat with `meridian profile add <name> --chatgpt --headless`.
- A Vercel AI Gateway key with a spending limit

A Compose service for it, with `ADMIN_TOKEN=<long random secret>` in `admin.env` and `MERIDIAN_API_KEY` and `VERCEL_API_KEY` in `keys.env`. `src/broker/server.ts` lists the other settings and their defaults.

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

Your laptop must be able to SSH to this machine and run `curl` there.

## 5. Settings

Point dr-hands at your broker and choose your languages in `mise.local.toml`:

```toml
[env]
DR_HANDS_PROVISIONER = "aws"
AWS_REGION = "us-east-2"
DR_HANDS_STACKS = "ruby node"
DR_HANDS_BROKER_HOST = "broker.example.ts.net"
DR_HANDS_BROKER_IP = "100.100.100.100"
DR_HANDS_BROKER_SSH = "broker"
DR_HANDS_BROKER_TOKEN_FILE = "~/dr-hands-broker/admin.env"
```

[configuration.md](configuration.md) explains each setting and how to select a custom provisioner.

## 6. The image

```fish
mise run image
```

It takes 15 to 20 minutes.

## 7. Your first report

Use the built-in text source for a harmless first test:

```fish
mise run add text ./report.md --repo owner/repo
```

Use the built-in GitHub source for a GitHub private vulnerability report:

```fish
mise run add github GHSA-xxxx-xxxx-xxxx --repo owner/repo
```

[configuration.md](configuration.md#report-sources) explains how to plug in HackerOne or another trusted local report source.
