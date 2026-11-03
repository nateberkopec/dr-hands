Feature: Replace infrastructure without changing dr-hands
  A provisioner is trusted local code behind a versioned, provider-neutral protocol.
  AWS is the only bundled implementation. A fixture proves dispatch, not cloud isolation.

  Rule: Selection does not change core orchestration

    Scenario: AWS is the default provisioner
      Given I did not select a provisioner
      When dr-hands resolves infrastructure for a new Run
      Then it selects the bundled "aws" provisioner
      And it records the provisioner name, version and executable digest

    Scenario: Select a custom provisioner
      Given "fixture" names an absolute executable in my local configuration
      When I select the "fixture" provisioner
      Then core invokes that executable through protocol version 1
      And no core source file or Terraform file changes

    Scenario: Refuse a relative custom executable
      Given "fixture" resolves to a relative executable path
      When I select the "fixture" provisioner
      Then provisioning fails before credentials are used
      And no infrastructure operation is attempted

    Scenario: Refuse an unsupported protocol
      Given the selected provisioner declares protocol version 2
      And core implements only protocol version 1
      When I start a Run
      Then the Run fails before credentials are used
      And core does not negotiate down

    Scenario: Keep the recorded provisioner for an existing Run
      Given a Run was created by provisioner "fixture" at an absolute path
      When current configuration selects provisioner "aws"
      Then the existing Run still resolves its recorded "fixture" path
      And a new Run resolves the "aws" provisioner

    Scenario: Record a compatible provisioner upgrade
      Given an existing Run records provisioner protocol version 1
      When its executable changes implementation version and digest but still declares protocol version 1
      Then dr-hands reruns the provisioner doctor
      And the new implementation version and digest appear in evidence

  Rule: Description and requests are provider-neutral

    Scenario: A Gravity provisioner declares every trust role
      Given the fixture provisioner supports Gravity
      When core reads its description
      Then it declares a control plane, compute boundary, network boundary and management ingress
      And none of those trust roles is enforced by a guest
      And its compute boundary is not the operator workstation

    Scenario: Refuse a missing trust role
      Given a provisioner supports Gravity but omits its network boundary
      When core validates its description
      Then provisioning fails before credentials are used
      And the missing trust role appears in evidence

    Scenario: A box request contains no provider vocabulary
      Given a normalized box Run
      When core writes its provisioner request
      Then the request names its Run, generation, deadline, role, image, management key and paths
      But it names no region, instance type, VPC, subnet, security group or cloud identity

    Scenario: A Gravity request uses stable roles
      Given a normalized Gravity Run
      When core writes its provisioner request
      Then the roles are "attacker" and "target"
      And replacing the provisioner does not change either role contract

    Scenario: Refuse an undeclared path
      Given a provisioner result adds a network path absent from the request
      When core validates the result
      Then the Run never becomes ready
      And removal starts

    Scenario: Refuse an output for another Run
      Given the fixture provisioner returns a result naming another Run
      When core validates the result
      Then the current Run is unchanged
      And the wrong-Run result appears in evidence

    Scenario: Refuse an output for a stale generation
      Given generation 2 is current for a Run
      When a provisioner completes an operation for generation 1
      Then the completion cannot attach a resource or path to generation 2
      And the stale completion appears in evidence

    Scenario: Refuse secret-shaped output
      Given a provisioner result contains an infrastructure credential
      When core validates the result
      Then the Run never becomes ready
      And evidence records the rejected field without recording its value

  Rule: The lifecycle survives retries and interruption

    Scenario: Repeat an operation idempotently
      Given a create operation was accepted but its result was lost
      When core retries the identical operation identity and request
      Then the provisioner continues the same generation with the same resource identities
      And it does not create a duplicate resource set

    Scenario: Refuse operation identity reuse
      Given an operation identity was used for one request
      When it is reused with different input
      Then the provisioner refuses it
      And neither request gains another resource

    Scenario: Partial creation enters cleanup
      Given the provisioner creates some resources and then fails
      When core receives a failed create result
      Then the Run never becomes ready
      And core invokes destroy for the same Run generation

    Scenario: Provider rejection can be retried
      Given a provider rejects an operation without applying it
      When core retries with a new operation identity for the same Run generation
      Then the provisioner may continue toward the requested state
      And only one resource set exists

    Scenario: Destroy is idempotent
      Given destroy was accepted but its result was lost
      When core invokes destroy again for the same Run generation
      Then the provisioner continues removal
      And an already absent resource is not an error

    Scenario: Local state is lost before destroy
      Given a Run still has provider resources
      But its provisioner state directory is missing
      When core invokes destroy
      Then the provisioner discovers the Run resources externally
      And it removes them by immutable Run and generation labels

    Scenario: A sweep works without local Runs
      Given local Run directories are unavailable
      And the provider reports one expired generation and one unexpired generation
      When the provisioner sweeps
      Then it attempts removal of the expired generation
      But it does not mutate the unexpired generation

    Scenario: One bad Run does not stop a sweep
      Given three generations are expired
      And the second generation cannot be deleted
      When the provisioner sweeps
      Then it attempts all three generations
      And it reports the second generation as blocked

  Rule: Observation comes from outside provisioner state

    Scenario: Readiness needs two agreeing views
      Given inspect reports a Run ready from local provisioner state
      But the external observer finds a missing role
      When core evaluates readiness
      Then the Run remains provisioning
      And the disagreement appears in evidence

    Scenario: An extra resource blocks readiness
      Given inspect reports exactly the requested resources
      But the external observer finds an extra Run resource
      When core evaluates readiness
      Then the Run never becomes ready
      And removal starts

    Scenario: Accepted deletion is not absence
      Given destroy reports that deletion was accepted
      But the external observer still finds one Run resource
      When core verifies absence
      Then the Run remains removing
      And it is not marked removed

    Scenario: External absence completes removal
      Given destroy has run for a generation
      And a fresh read-only observation finds no resource with that Run and generation
      When core verifies absence
      Then the Run may become removed
      And the observer identity and time appear in evidence

    Scenario: Fixture self-report cannot prove absence
      Given the fixture's local state says a generation is absent
      But its read-only view still contains a resource
      When the fixture runs verify-absent
      Then the contract test fails

  Rule: Management stays behind the provisioner boundary

    Scenario: Execute without exposing provider authority
      Given a ready Run role supports management
      When core executes an argument vector in that role
      Then the provisioner owns the management transport
      And the guest receives no durable provider credential

    Scenario: Do not evaluate a management shell string locally
      Given a management argument contains shell metacharacters
      When core executes it in a role
      Then core passes the literal argument vector to the provisioner
      And the operator workstation does not evaluate it

    Scenario: Refuse an undeclared role
      Given a box Run declares only the "box" role
      When core asks the provisioner to execute in "target"
      Then the provisioner refuses before opening a management path

  Rule: AWS is the bundled real-service implementation

    @aws @costs-money
    Scenario: AWS box resources match the normalized observation
      Given valid AWS box credentials and separate read-only observer credentials
      When the AWS provisioner creates a box Run
      Then inspect and external observation report the same Run resources
      And every resource carries its Run, generation and deadline labels

    @aws @costs-money
    Scenario: AWS Gravity paths match the request
      Given valid AWS Gravity credentials and separate read-only observer credentials
      When the AWS provisioner creates a Gravity Run
      Then only its requested management, attacker-to-target and attacker-to-OpenRouter paths exist
      And both guest roles remain outside the enforcing boundary

    @aws @costs-money
    Scenario: AWS cleanup survives lost Terraform state
      Given the AWS provisioner created a disposable Run
      And its Terraform state directory is lost
      When the AWS provisioner destroys and verifies that Run
      Then a fresh read-only AWS query finds no labeled resource

    @aws @costs-money
    Scenario: AWS failure injection leaves no resource
      Given AWS creation fails after each individual provisioning operation in turn
      When the AWS provisioner destroys and verifies each failed Run
      Then a fresh read-only AWS query finds no labeled resource for any failed Run

    Scenario: The fixture is not another infrastructure implementation
      Given the deterministic fixture passes every protocol scenario
      When conformance evidence is summarized
      Then it claims compatibility with protocol version 1
      But it makes no claim about cloud isolation or real infrastructure
