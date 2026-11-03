Feature: Triage a normalized report on its own box
  Each run gets a fresh box with a trusted local snapshot, a clone of one repository, and an agent.

  Background:
    Given the image is current
    And the fixture report source has a report "plain" for repository "owner/repo"

  Scenario: Add a report
    When I add the fixture report "plain"
    Then add prints a run ID
    And I see the scanner's findings for it
    And one box for the run is running and on my tailnet
    And the trusted local snapshot has report.md and report.json
    And the box has the same report.md and report.json
    And the box has a clone of "owner/repo"
    And the box has an OpenRouter key for the run that expires within 12 hours
    And the box's metadata service is off

  Scenario: A report with private code
    Given the fixture report "with-code" includes a code bundle with a branch "poc"
    When I add the fixture report "with-code"
    Then the repository clone on the box has a branch "report/poc"

  Scenario: Add the same sourced report twice
    Given I added the fixture report "plain"
    When I add the fixture report "plain" again
    Then add refuses and points me to attach and rm
    And the run still has exactly one box

  Scenario: A failed add cleans up after itself
    Given the box for the fixture report "plain" will fail to boot
    When I add the fixture report "plain"
    Then add fails and says why
    And no box, tailnet device or OpenRouter key remains for the run

  @interactive
  Scenario: Work with the agent
    Given I added the fixture report "plain"
    When I attach to the run
    Then my terminal shows the scanner's findings and where the trusted snapshot is
    And Pi starts on the box
    And Pi answers a question using the first model in DR_HANDS_MODELS

  @interactive @macos
  Scenario: The hardened Ghostty window
    Given DR_HANDS_TERMINAL is "ghostty"
    And I added the fixture report "plain"
    When I attach to the run
    Then a new Ghostty window opens on the session
    And text from the box cannot change my clipboard

  Scenario: Bring the fix back to my laptop
    Given I added the fixture report "plain"
    And the agent committed a fix on branch "fix" that changes "lib/fixture.rb" and "Gemfile"
    When I run patch for the run
    Then the fix is saved as fix.patch on my laptop
    And "Gemfile" is flagged as risky
    And "lib/fixture.rb" is not flagged

  Scenario: Patch with no fix
    Given I added the fixture report "plain"
    And the agent has not committed a fix
    When I run patch for the run
    Then patch refuses and says branch "fix" has no commits

  Scenario: The box ends itself
    When I add the fixture report "plain"
    Then the box will power off 12 hours after it boots
    And powering off deletes the box

  Scenario: Remove a run
    Given I added the fixture report "plain"
    When I remove the run
    Then no box, tailnet device or OpenRouter key remains for the run
    And the run's live-state folder is gone
    And its trusted snapshot and evidence remain in the local archive

  Scenario: Remove a run that has no box
    When I remove a run that was never added
    Then rm succeeds
    And nothing else changed

  Scenario: Down sweeps up leftovers
    Given a running instance tagged as a dr-hands box that local state does not know about
    And a tailnet device tagged as a dr-hands box with no instance behind it
    And a dr-hands OpenRouter key with no box
    When I run down
    Then all three are gone

  Scenario: Down with nothing running
    Given no run has a box
    When I run down
    Then down succeeds
