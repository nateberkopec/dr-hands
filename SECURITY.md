# Security

dr-hands runs coding agents on private security reports. Strangers write those reports, and some will try to trick the agent. This page explains what dr-hands protects and how.

## Report a problem

Report security problems in dr-hands privately through [GitHub's private vulnerability reporting](https://github.com/nateberkopec/dr-hands/security/advisories/new). Don't open a public issue.

## What we assume

Every report is hostile, regardless of its source. Its author may control:

- the report text, comments, and attachments, including hidden text aimed at AI
- proof-of-concept code and the packages it pulls in
- source-local metadata that becomes filenames, identifiers, or error text
- the agent itself, through prompt injection

A report source is different from a report. Source executables run as you on your laptop and are trusted code. GitHub and text are built in; you are responsible for every custom source you configure.

So we treat the agent as the attacker. It gets a shell, but nothing worth stealing.

The report is not the secret. Its author already has it. We protect:

- your laptop, its keys, and your logins
- credentials for GitHub, HackerOne, or any other report source
- your home network and tailnet
- your money and AI quota
- your judgment about the report

## How dr-hands protects you

**One cloud box per run.** Each normalized report snapshot gets a fresh AWS machine. It holds no report-source, GitHub, cloud, or AI provider keys. It deletes itself after 12 hours.

**No network by default.** The agent can reach two things: a proxy that allows GitHub and your package hosts, and the AI broker. A firewall on the box blocks the rest, including DNS and the cloud metadata service.

**A broker for AI.** Boxes never see a real AI key. Each box gets its own short-lived broker key. The broker allows only listed models, caps tokens per report, and keeps each report's sessions apart.

**A locked-down tailnet.** Boxes can reach the broker's port and nothing else, not even other boxes or your laptop.

**A trusted local intake boundary.** A report source finishes before cloud provisioning. dr-hands accepts only fixed snapshot filenames, captures source output, and keeps source credentials out of the snapshot and run state.

**A scanner, as a tripwire.** Your laptop scans every normalized snapshot for hidden text, lookalike letters, and words aimed at AI. Plain-English tricks still get through.

**A guarded terminal.** You connect in a separate terminal window that blocks clipboard access, links, and images.

**You stay in charge.** You take every report-source and repository action yourself. Fixes come back as patch files, and dr-hands flags changes to build files and dependencies. Read every line before you apply one.

## Why not a local VM

A local VM or container runs on the machine that holds your keys. If the agent breaks out, it lands there. A container shares its host's kernel, so one kernel bug is enough. A break-out from a cloud box lands on a host with nothing of yours, off your network. That costs about a dollar per report.

## Risks we accept

- A custom report source is trusted code running as you. A malicious or vulnerable source can compromise your laptop before a box exists.
- Report-source APIs can return hostile metadata as well as hostile prose. Capturing and normalizing output reduces terminal risk but cannot make a trusted source executable safe.
- An agent that gets root on its box can remove the firewall. It still holds only that report's broker key, which expires.
- Allowed hosts work both ways. The agent could send data to GitHub or a package host, or pull in an attacker's package.
- The agent can reach any server it starts on its own box.
- Text from the box reaches your terminal and SSH client.
- The attacker shapes the verdict and the fix. The failing test and your review are the defense.
