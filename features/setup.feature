Feature: One-time setup
  A new user sets up dr-hands once. Code creates every cloud resource.

  @manual
  Scenario: Make the AWS account for boxes
    Given I am signed in to AWS as the root user of my organization
    When I run bootstrap-aws with a new email address
    Then a "dr-hands" member account exists with a monthly budget alert
    And its deploy key can manage EC2 in my region and nothing else
    And the deploy key is printed once, for me to save in my secret store

  Scenario: The OpenRouter workspace locks down every key in it
    When I run setup-openrouter
    Then OpenRouter has a "dr-hands" workspace
    And its default guardrail allows only the models in DR_HANDS_MODELS
    And its default guardrail enforces zero data retention for every model group
    And every OpenRouter server tool is disabled in the workspace
    And prompt logging and the training-data discount are off in the workspace

  Scenario: Running setup again changes nothing
    Given setup-openrouter has run
    When I run setup-openrouter again
    Then it reports no changes

  Scenario: New models need no new image
    Given setup-openrouter has run
    And the image is current
    When I add a model to DR_HANDS_MODELS and run setup-openrouter
    Then the workspace guardrail allows the new model
    And the image is still current

  Scenario: Build the image
    When I run image
    Then one dr-hands image exists, built with the stacks in DR_HANDS_STACKS
    And older dr-hands images and their snapshots are gone

  Scenario: A stale image blocks a new box
    Given a stack file changed after the image was built
    When I add the fixture report "plain" through its fixture source
    Then add refuses and tells me to run image
    And no box, tailnet device or OpenRouter key was made
