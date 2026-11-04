# Security

dr-hands isolates hostile investigations from the operator's workstation. Reports, guest images, targets, and evidence may be malicious. Guest root is an initial condition, not an escape.

Report security problems privately through [GitHub's vulnerability reporting](https://github.com/nateberkopec/dr-hands/security/advisories/new).

## Contracts

- [Threat model](security/threat-model.md): trusted authors, hostile guests, and upstream assumptions.
- [Data-flow policy](security/data-flow.md): sensitivity, recipients, and the lethal trifecta.
- [Run lifecycle](security/lifecycle.md): approval, preparation, authority, recovery, and verified removal.
- [Accepted risks](security/risks.md): disclosure, availability, and limits of technical containment.
- [Gravity workflow](workflows/gravity.ts): reference boundary, numbered assumptions, invariants, and acceptance claims.
- [Formal models](formal/README.md): bounded evidence, not proof of real-service correctness.

The ambition is that escape requires a CVSS 9+ zero-day in a named, mature upstream boundary. This is not a guarantee about an unknown vulnerability's score or novelty. Misconfiguration and chains of smaller bugs still matter.

Human cognitive security is outside scope. Hostile content can manipulate the person reviewing it; a disposable machine cannot protect human judgment.
