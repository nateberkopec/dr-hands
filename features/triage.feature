Feature: Triage a report on its own box
  Each report gets a fresh box with the report, a clone of the repository, and an agent.

  Background:
    Given the image is current
    And the fixture repository has a draft report "plain"

  Scenario: Add a report
    When I add the fixture report "plain"
    Then I see the scanner's findings for it
    And one box for the report is running and on my tailnet
    And the box holds the report as advisory.md and advisory.json
    And the box has a clone of the fixture repository
    And the box has an OpenRouter key for the report that expires within 12 hours
    And the box's metadata service is off

  Scenario: A report with a private fork
    Given the fixture report "forked" has a private fork with a branch "poc"
    When I add the fixture report "forked"
    Then the clone on the box has a branch "fork/poc"

  Scenario: Add the same report twice
    Given I added the fixture report "plain"
    When I add the fixture report "plain" again
    Then add refuses and points me to attach and rm
    And the report still has exactly one box

  Scenario: A failed add cleans up after itself
    Given the box for the fixture report "plain" will fail to boot
    When I add the fixture report "plain"
    Then add fails and says why
    And no box, tailnet device or OpenRouter key remains for the report

  @interactive
  Scenario: Work with the agent
    Given I added the fixture report "plain"
    When I attach to the report
    Then my terminal shows the scanner's findings and where the trusted copy is
    And Pi starts on the box
    And Pi answers a question using the first model in DR_HANDS_MODELS

  @interactive @macos
  Scenario: The hardened Ghostty window
    Given DR_HANDS_TERMINAL is "ghostty"
    And I added the fixture report "plain"
    When I attach to the report
    Then a new Ghostty window opens on the session
    And text from the box cannot change my clipboard

  Scenario: Refresh after the report changes
    Given I added the fixture report "plain"
    And the fixture report "plain" has a new sentence in its description
    When I refresh the report
    Then advisory.md on the box contains the new sentence

  Scenario: Bring the fix back to my laptop
    Given I added the fixture report "plain"
    And the agent committed a fix on branch "fix" that changes "lib/fixture.rb" and "Gemfile"
    When I run patch for the report
    Then the fix is saved as fix.patch on my laptop
    And "Gemfile" is flagged as risky
    And "lib/fixture.rb" is not flagged

  Scenario: Patch with no fix
    Given I added the fixture report "plain"
    And the agent has not committed a fix
    When I run patch for the report
    Then patch refuses and says branch "fix" has no commits

  Scenario: The box ends itself
    When I add the fixture report "plain"
    Then the box will power off 12 hours after it boots
    And powering off deletes the box

  Scenario: Remove a report
    Given I added the fixture report "plain"
    When I remove the report
    Then no box, tailnet device or OpenRouter key remains for the report
    And the report's folder in state/ is gone

  Scenario: Remove a report that has no box
    When I remove a report that was never added
    Then rm succeeds
    And nothing else changed

  Scenario: Down sweeps up leftovers
    Given a running instance tagged as a dr-hands box that Terraform does not know about
    And a tailnet device tagged as a dr-hands box with no instance behind it
    And a dr-hands OpenRouter key with no box
    When I run down
    Then all three are gone

  Scenario: Down with nothing running
    Given no report has a box
    When I run down
    Then down succeeds
