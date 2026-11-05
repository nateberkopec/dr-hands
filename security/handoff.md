# Handoff

dr-hands hands off claims the operator can check, not fixes. Every run turns hostile input into two exports, and a verify run adds a third. The handoff is the least safe step in the workflow, so it carries as little attacker-chosen content as possible.

## What leaves a run

- **`verdict.md`:** prose for the operator, who uses it to judge whether a claim is real and how much it matters. Never forward it to an agent.
- **`findings.json`:** [typed claims](../schemas/findings.schema.json) with a fixed verdict list, CWE, CVSS base vector, `path:line` locations, an HTTP transcript, and captured canary names. It has no free-text fields.
- **`verification.json`:** what a [verify run](../workflows/verify.ts) observed when it replayed one finding against a fresh target, with fresh canaries and credentials and no agent.

Tests, patches, and other code written in a run never leave it as something to apply or execute. Agents in a run are better at finding inputs than at writing fixes, and their code is hostile.

## Rendering a prompt

`dr-hands handoff RUN_ID FINDING` writes a prompt for the operator's defensive coding agent. The controller:

1. validates `findings.json` and checks that each canary name exists in the source run's target;
2. checks each location in the operator's checkout at the commit the target configuration declares, never a commit a guest names;
3. fills a fixed dr-hands template with only those checked fields;
4. for a verified finding of class `confidentiality`, `integrity`, or `availability`, attaches the minimized transcript as a separate file.

A finding is verified when a verify run captured at least one canary and every canary the finding claims. Minimizing against a fresh target removes every byte not needed for the capture, so what remains is shaped by the bug rather than by the attacker. An unverified or unminimized finding gets a prompt labeled unverified with locations and classification only. Class `file` and `callback` findings imply code execution or outbound requests, so their transcripts never reach the agent. The prompt never quotes `verdict.md` or the report.

## Checking the fix

A test that sends a transcript can carry the attack out of the run, into the workstation or CI. The prompt asks for a regression test with benign inputs that show the same flaw, such as the same request shape or framing bytes with a harmless marker in place of any payload. It never asks the agent to replay the transcript against a running service. That is an instruction, not a boundary. To confirm a fix, build a target from the fixed commit and run `dr-hands verify RUN_ID FINDING --target NAME`. The fix holds when no canary is captured.

## Production

dr-hands never replays anything against production. An operator who chooses to reproduce a verified finding there does so outside dr-hands, with their own test identities, after reading the minimized transcript and its side effects. The side-effect report describes the synthetic target only.

## What remains

Minimized transcripts still carry some attacker-chosen content, such as paths, header values, and bytes the bug needs. A small channel is not a closed one. Prose still shapes the operator's judgment of severity and urgency. Once merged, the defensive agent's test and fix are the operator's code, and CI runs them with its own secrets. Reviewing that change is the last defense.
