# Targets and canaries

A target is a synthetic copy of the operator's HTTP service. A canary is a secret value planted in it. A finding counts only when its transcript captures a canary, and a [verify run](../workflows/verify.ts) that never saw the report captures it again.

## Target

The operator declares each target in `config.toml`: pinned images, the source commit they were built from, entry ports, a health request, identities, and canaries. Each canary has an operator-written `description`, which is what a coding agent reads about it in a [handoff](handoff.md). An optional front proxy sits before the service, so request smuggling can reach a route the proxy forbids. Never use production data or credentials.

An identity names one header that authenticates it. The controller generates fresh credentials and canary values for every run. The target receives all of them at `/run/dr-hands/inputs/seed.json` and seeds them. Clients receive credentials, addresses, and canary names, never canary values. A verify run's replayer receives credentials and canary values to check captures. A transcript that carries values or credentials from one run captures nothing in the next.

Roles reach each other by stable run-local names, such as `target.run` and `sink.run`, so a transcript that names the sink still works in a verify run. A target that resets to its seed lets the replayer minimize transcripts.

## Catalog

| Class | Planted by | Captured when |
|---|---|---|
| `confidentiality` | Operator: a value only its `readers` may see | It appears in a response to any other identity |
| `integrity` | Operator: a value stored in a record, with `writers` and a `check` request | The check stops returning it after a transcript with no request from its writers |
| `file` | dr-hands: a value in the seed file itself | It appears in a response or reaches the sink |
| `callback` | dr-hands: the run's sink | The target connects to it |
| `availability` | dr-hands: the health request | The target stops answering it in time |

Two tenants and an admin, each holding a confidentiality canary, cover broken access control and privilege escalation. The dr-hands canaries cover file reads, server-side request forgery, code execution that reads or calls out, and denial of service, with no operator work.

## Coverage

`dr-hands lint` reports which classes a target covers. A finding whose class has no canary gets the verdict `no-oracle`: a gap in the target, not evidence either way. Repeated `no-oracle` results for one class mean that target needs another canary.

An agent may name a class and a location for a missing canary. It never supplies canary contents, seed data, identities, or credentials. The operator writes those.

## Drafting a target

The operator's own coding agent can draft identities and canaries from the application's SECURITY.md and permission model. That input is trusted, so this step needs no run. A useful prompt: "Read SECURITY.md and the authorization code. List each identity class and the data only it may read or change. Propose identities and one canary per boundary in the dr-hands target format."

## Not covered yet

- Cross-site scripting needs a victim browser role that visits a URL as an identity. It is the next planned class.
- Races, business-logic bugs without a natural canary, and libraries without an HTTP interface.
- Real third-party services. Twins of them, such as a mail sink or a payment fake, can run as target roles with their own canaries.
