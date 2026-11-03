# dr-hands

The language for bringing hostile security reports into isolated triage runs.

## Language

**Report**:
A security claim and its supporting material, independent of where it was submitted.
_Avoid_: Advisory, ticket

**Report source**:
Trusted local code that fetches or reads a report and produces a normalized snapshot.
_Avoid_: Reporter, connector, provider

**Locator**:
A source-specific identifier for one report, such as a GHSA ID, HackerOne report number, or file path.
_Avoid_: Report ID

**Snapshot**:
The normalized, immutable local copy of a report used to create or refresh a run.
_Avoid_: Advisory copy

**Run**:
One report's local state, cloud box, inference authority, and evidence, identified independently of the report source.
_Avoid_: Report ID, advisory ID
