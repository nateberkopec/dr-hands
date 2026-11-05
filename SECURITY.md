# Security

dr-hands isolates hostile investigations from the operator's workstation. Reports, guest images, targets, and evidence may be malicious. Guest root is an initial condition, not an escape.

Report security problems privately through [GitHub's vulnerability reporting](https://github.com/nateberkopec/dr-hands/security/advisories/new).

## Contracts

- [Threat model](security/threat-model.md): trusted authors, hostile guests, and upstream assumptions.
- [Data-flow policy](security/data-flow.md): sensitivity, recipients, and the lethal trifecta.
- [Run lifecycle](security/lifecycle.md): approval, preparation, authority, recovery, and verified removal.
- [Targets and canaries](security/canaries.md): synthetic targets, the canary catalog, and coverage.
- [Handoff](security/handoff.md): what leaves a run, and what may reach a coding agent.
- [Accepted risks](security/risks.md): disclosure, availability, and limits of technical containment.
- [Gravity Machine](workflows/gravity-machine.ts): reference boundary, numbered assumptions, invariants, and acceptance claims.
- [Formal models](formal/README.md): bounded evidence, not proof of real-service correctness.

The ambition is that escape requires a CVSS 9+ zero-day in a named, mature upstream boundary. This is not a guarantee about an unknown vulnerability's score or novelty. Misconfiguration and chains of smaller bugs still matter.

dr-hands aims to tell the operator only what they can check safely: a canary captured again by a verify run that never saw the report. The operator is part of this model. Free-form attacker content, such as prose and transcripts, reaches only the operator, who is harder to trick than an agent but not impossible to trick. Coding agents get only values the operator or dr-hands wrote, or that select from a closed set.
