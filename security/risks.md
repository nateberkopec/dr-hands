# Accepted risks

- A valid report can still exploit a parser or manipulate an agent or human reviewer. Validation is not sanitization.
- Public browsing permits disclosure of public inputs and potentially abusive public HTTP(S) requests. Misclassifying private material as public can expose it.
- Private analysis discloses readable material to configured inference recipients. Model instructions and zero retention do not eliminate disclosure.
- Guest root can corrupt the investigation, exhaust its resources, and spend its bounded inference budget. Useful results and availability are not guaranteed.
- Exported evidence can attack software or people that later open it. Fixed filenames and opaque transfer do not make content safe.
- A target compromised by a transcript can attack the replayer or sink and forge a verification. Verification is evidence, not proof.
- Minimized transcripts in a handoff still carry attacker-chosen paths, header values, and bytes the bug needs. A regression test built from them can still exercise the bug outside a run.
- An operator who replays a transcript against production does so outside dr-hands. Its side-effect report describes the synthetic target only.
- A finding's class is chosen by the guest. A code-execution finding labeled `confidentiality` gets its transcript attached.
- Missing canaries leave bug classes unproven. `no-oracle` marks the gap; it never means safe.
- Races, business-logic bugs, non-HTTP libraries, and real third-party services are outside the canary catalog.
- A scheduler the operator adds to repeat runs holds dr-hands' credential aliases. Scheduling is outside dr-hands.
- Report exporters and their credentials are outside dr-hands. Operators select those tools separately.
- Cloud services, inference services, SSH, cryptography, and trusted controller dependencies can have vulnerabilities. Reputation does not prove a deployment safe.
- A lost controller can leave runtime resources until reconciliation returns. External authority still expires; resource deletion is not guaranteed while providers or the controller remain unavailable.
- Formal checks can be wrong or incomplete because of their assumptions, abstraction, finite bounds, or mismatch with infrastructure. They do not assign a score to future exploits.
