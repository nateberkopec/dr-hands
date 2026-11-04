# Accepted risks

- A valid report can still exploit a parser or manipulate an agent or human reviewer. Validation is not sanitization.
- Public browsing permits disclosure of public inputs and potentially abusive public HTTP(S) requests. Misclassifying private material as public can expose it.
- Private analysis discloses readable material to configured inference recipients. Model instructions and zero retention do not eliminate disclosure.
- Guest root can corrupt the investigation, exhaust its resources, and spend its bounded inference budget. Useful results and availability are not guaranteed.
- Exported evidence can attack software or people that later open it. Fixed filenames and opaque transfer do not make content safe.
- Report exporters and their credentials are outside dr-hands. Operators select those tools separately.
- Cloud services, inference services, SSH, cryptography, and trusted controller dependencies can have vulnerabilities. Reputation does not prove a deployment safe.
- A lost controller can leave runtime resources until reconciliation returns. External authority still expires; resource deletion is not guaranteed while providers or the controller remain unavailable.
- Formal checks can be wrong or incomplete because of their assumptions, abstraction, finite bounds, or mismatch with infrastructure. They do not assign a score to future exploits.
