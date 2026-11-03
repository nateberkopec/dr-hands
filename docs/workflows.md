# Workflows

Triage and gravity are supplied workflows in one tool, not separate execution engines. Every workflow uses the same Run identity, provisioning lifecycle, authority limits, evidence handling, and verified removal path.

## Declarative manifest

A workflow is a versioned TOML manifest selected by the operator's configuration. It declares:

- named roles, immutable image identifiers, and guest command argument lists;
- required input types and their role destinations;
- operator-selected target roles, if any;
- permitted role-to-role service and callback ports;
- each role's network policy and inference requirements;
- named output files available for explicit export.

Commands run only inside the selected guest role. A manifest has no workstation commands, lifecycle scripts, local hooks, templating, or shell interpolation. The provisioner, not the workflow, creates networks, instances, authority, and cleanup operations. Reports and guest output cannot select or change a workflow.

Image identifiers must be immutable provider references or content digests. A valid manifest identifies what will run, not whether it is benign. Images, dependencies, model files, commands, agents, and targets are all treated as infected. Loading a malicious model or package inside a guest may execute arbitrary code; guest root is already assumed.

The controller rejects unknown fields, mutable image selections, undeclared inputs, invalid role references, unsupported network requirements, and any request to bypass mandatory isolation. A provider that cannot enforce a requested policy outside the guest must refuse the run rather than approximate it with a guest firewall.

## Supplied workflows

| Workflow | Roles | Public network access | Input and output |
| --- | --- | --- | --- |
| Triage | Investigating agent; disposable target when selected | Agent may follow public HTTP(S) links | Structured report; explicitly exported findings and patches |
| Gravity | Attacker framework and disposable target | No general Internet; bounded inference only | Operator-selected target and scope; explicitly exported findings and target logs |

ARTEX and RubyGems.org are reference role implementations for gravity, not privileged components or hardcoded engine types. Other workflows may compose roles under the same mandatory rules. Choosing a workflow with public-web access is an explicit operator decision, not something a report can request.

## Mandatory boundaries

All workflows isolate the workstation, private networks, provider metadata/control-plane endpoints, other runs, and production credentials. Management is operator-initiated. Guest root cannot widen routes, grant credentials, alter the expiry, or weaken externally enforced policy. An allowed public service does not give the guest cloud administration authority.

The triage public-web policy allows public HTTP and HTTPS, including redirects, while rejecting destinations in private, local, link-local, metadata, management, and other-run address ranges. Address checks must apply to actual connections and every redirect, including IPv6 and DNS rebinding; validating the first URL alone is insufficient. Enforcement must be outside the guest. The provider design must substantiate these properties before public-web triage can be considered supported.

Public HTTP(S) is bidirectional. A compromised triage agent can disclose its report or send hostile requests to reachable public services, including attacker-controlled websites. Teardown cannot retract those requests or destroy remote copies. This risk is accepted for triage, not silently inherited by gravity. No claim is made that public-web triage can affect only disposable systems.

Gravity retains its restricted network contract in [GRAVITY.md](../GRAVITY.md). The existing Alloy model covers that contract only. General workflows and public-web triage are not proved by that model.

## Evidence and removal

Before a run starts, its inventory identifies every guest-writable runtime resource and each run-scoped capability. Guests cannot write to persistent shared caches or operator-owned storage outside that inventory. Cleanup destroys the inventoried runtime resources, revokes authority, and verifies absence through external services; partial provisioning follows the same path.

Explicit exports are the exception to destruction. The controller saves guest-produced bytes under fixed local names without rendering, executing, or extracting them. Those files remain hostile and can survive cleanup alongside trusted control-plane metadata. Their storage is controlled by the operator, not mounted for guest writes. Neither a digest nor successful teardown certifies their safety.
