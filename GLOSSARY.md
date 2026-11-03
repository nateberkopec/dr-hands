# dr-hands

The language for investigating hostile material inside disposable boundaries.

## Language

**Report**:
A security claim and its supporting text, independent of where it was submitted. Its contents remain hostile even when its structure is valid.
_Avoid_: Advisory, ticket

**Report source**:
The place a report originated, such as GitHub or HackerOne. It is provenance, not a plugin that dr-hands executes.
_Avoid_: Connector, report provider

**Snapshot**:
An immutable copy of the input data and declarations selected for one run.
_Avoid_: Advisory copy

**Workflow**:
A declaration of the roles, inputs, permitted connections, and outputs needed for an investigation or experiment.
_Avoid_: Execution engine, local hook

**Role**:
One participant in a workflow, such as an investigating agent, attacker framework, or disposable target.
_Avoid_: Workflow, provisioner

**Run**:
One execution of a workflow, with its own identity, resources, bounded authority, and evidence.
_Avoid_: Report ID, advisory ID

**Chamber**:
The isolated collection of roles and resources belonging to one gravity run.
_Avoid_: Container, shared sandbox

**Provisioner**:
The integration responsible for creating and removing a run's infrastructure and enforcing its external boundaries.
_Avoid_: Report source, workflow

**Evidence**:
Material retained to assess a run's behavior or findings. Guest-produced evidence remains hostile after export and teardown.
_Avoid_: Trusted output, safe artifact
