# Handoff

dr-hands hands off claims the operator can check, not fixes. Every run turns hostile input into two exports, and a verify run adds a third. The handoff is the least safe step in the workflow. It splits what leaves a run by reader: free-form attacker content goes only to the operator, never to an agent.

## What leaves a run

- **`verdict.md`:** prose for the operator, who uses it to judge whether a claim is real and how much it matters.
- **`findings.json`:** [typed claims](../schemas/findings.schema.json) with a fixed verdict list, CWE, CVSS base vector, `path:line` locations, an HTTP transcript, and captured canary names.
- **`verification.json`:** what a [verify run](../workflows/verify.ts) observed when it replayed one finding against a fresh target, with fresh canaries and credentials and no agent.

Tests, patches, and other code written in a run never leave it as something to apply or execute. Agents in a run are better at finding inputs than at writing fixes, and their code is hostile.

## Two channels

| Agent channel | Operator channel |
|---|---|
| Verified or not, decided by a verify run, never the guest | `verdict.md` and the report |
| Captured canary names, with their operator-written descriptions and classes | The full transcript, and the minimized one |
| Which identity captured each canary, as the replayer observed it | The side-effect report |
| CWE ID, CVSS base vector, HTTP methods, and, for `no-oracle`, the missing class | Anything else a guest wrote |
| Locations that exist in the operator's checkout | |

Every agent-channel value is written by the operator or dr-hands, or chosen by the attacker from a closed set the operator controls. The code at a location is the operator's own. "`tenant_a` captured `tenant_b_invoice`, CWE-639, at `app/controllers/invoices_controller.rb:14`" tells a defensive agent what is wrong without one attacker-written byte. Verified and unverified findings get the same fields, labeled differently.

The operator channel is shown escaped and never rendered or executed. dr-hands never forwards it. When the agent needs more, such as the framing bytes of a request-smuggling bug, the operator pastes it deliberately. The operator is harder to trick than an agent reading attacker text, but not impossible to trick.

## Rendering a prompt

`dr-hands handoff RUN_ID FINDING` writes a prompt for the operator's defensive coding agent. The controller:

1. validates `findings.json` and checks that each canary name exists in the source run's target;
2. checks each location in the operator's checkout at the commit the target configuration declares, never a commit a guest names;
3. fills a fixed dr-hands template with agent-channel fields only.

A finding is verified when a verify run captured at least one canary and every canary the finding claims. Minimizing a transcript makes it shorter for the operator to read. It does not make it safe for an agent.

## Checking the fix

The prompt asks for a regression test with benign inputs that show the same flaw. A test that sends a transcript can carry the attack out of the run, into the workstation or CI. To confirm a fix, build a target from the fixed commit and run `dr-hands verify RUN_ID FINDING --target NAME`. The fix holds when no canary is captured.

## Production

dr-hands never replays anything against production. An operator who chooses to reproduce a verified finding there does so outside dr-hands, with their own test identities, after reading the minimized transcript and its side effects. The side-effect report describes the synthetic target only.

## What remains

The attacker still chooses which of the operator's locations and which closed-set values reach the agent. Operator-channel content can still mislead the operator, and anything the operator pastes into an agent carries its full risk. Once merged, the agent's test and fix are the operator's code, and CI runs them with its own secrets. Reviewing that change is the last defense.
