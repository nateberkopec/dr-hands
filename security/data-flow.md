# Data-flow policy

Evaluate private data, hostile content, and external communication together. Hostile content is always assumed. Count all images and inputs across the run, including roles that exchange data. A private target plus a public-network agent still combines all three legs.

## Sensitivity and recipients

Sensitivity and trust are separate. Public means permitted for public disclosure, not harmless. Private means potentially confidential. Missing sensitivity is private. Classification is an operator declaration, not proof that an image contains no secrets.

| Policy | Private data | External recipients |
| --- | --- | --- |
| Private analysis | Allowed and inventoried | Configured inference service and its serving providers |
| Public browsing | Forbidden in every image layer and input | Public HTTP(S) and configured inference |
| Reference gravity | Public/synthetic reference contents | Configured inference; role traffic stays inside the run |

Reject private or unclassified images/inputs combined with public-web access. There is no approval override. Reports, source, findings, URLs, and search queries may all be private. Source provenance cannot lower sensitivity or choose targets, images, paths, or recipients.

Typed relationships declare which role reads each input, reaches each role/port, or calls inference. Derive permissions from those relationships, not from observed agent behavior. Opaque guest images cannot reveal all their future behavior through static analysis.

## Separate runs

Use separate runs for public browsing and private analysis. Public results remain hostile when explicitly imported into private analysis. Private-to-public transfer and automatic declassification are not supported. A run's outputs inherit private sensitivity if any readable image/input was private.

No runtime input additions or network widening are allowed. A changed plan requires a fresh run. Deleting a file, changing a stage, or starting a new process does not erase hidden guest copies or memory.

## Accepted inference disclosure

A compromised guest can place any readable data in prompts. The configured inference service and its serving providers are accepted disclosure recipients and must be shown before approval. Disabled hosted tools, model restrictions, hard budgets, expiry, and zero retention constrain use but do not prevent disclosure.

The exception is for named recipients, not arbitrary inference endpoints or public web access. Production and operator credentials remain forbidden in images/inputs regardless of labels. Run-scoped inference authority is a separately bounded capability.

Public requests, prompt disclosure, and remote copies cannot be recalled by removal.
