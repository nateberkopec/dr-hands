Feature: Bring a report from any trusted local source
  A report source fetches or reads hostile content on my laptop and produces one normalized snapshot. The source executable is trusted; its report is not.

  Background:
    Given the image is current
    And the fixture repository is "owner/repo"

  Scenario Outline: Built-in report sources create the same kind of run
    When I add a report with <command>
    Then add prints a run ID
    And the trusted local snapshot has report.json and report.md
    And the snapshot records source <source> and a stable source-local ID
    And the snapshot records repository "owner/repo"
    And one box for the run is ready
    And the box has report.json, report.md and a clone of "owner/repo"

    Examples:
      | source | command                                                   |
      | github | "github GHSA-xxxx-xxxx-xxxx --repo owner/repo"           |
      | text   | "text ./features/fixtures/plain.md --repo owner/repo"     |

  Scenario: Configure a HackerOne report source
    Given DR_HANDS_REPORT_SOURCE_HACKERONE is "fixture-hackerone-source"
    And fnox provides that source a fixture HackerOne credential
    When I add "hackerone 123456 --repo owner/repo"
    Then dr-hands invokes "fixture-hackerone-source fetch 123456" with an empty output directory
    And one box is ready from the normalized HackerOne snapshot
    And neither the snapshot nor the box contains the HackerOne credential

  Scenario: Configure another report source without changing dr-hands
    Given DR_HANDS_REPORT_SOURCE_ACME is "fixture-acme-source"
    When I add "acme CASE-42 --repo owner/repo"
    Then dr-hands invokes the configured executable
    And one box is ready from its normalized snapshot

  Scenario: A normalized snapshot has one contract
    Given a report source succeeds
    Then report.json has a protocol version, stable ID, title, body and comments
    And report.md contains the same human-readable report
    And dr-hands supplies the source name and repository when it stores the snapshot
    And no source-specific field is required by the box

  Scenario: Source identifiers do not become run identifiers
    Given GitHub has a report with source-local ID "42"
    And HackerOne has a report with source-local ID "42"
    When I add both reports for "owner/repo"
    Then add prints two different run IDs
    And each run retains its own source name, locator and stable ID

  Scenario: A source may provide the repository
    Given the configured source's snapshot names repository "owner/repo"
    When I add the report without --repo
    Then one box is ready with a clone of "owner/repo"

  Scenario: A report needs a repository
    Given the configured source's snapshot names no repository
    When I add the report without --repo
    Then add refuses and asks for --repo
    And no box, tailnet device or OpenRouter key is made

  Scenario: Malformed source output fails before provisioning
    Given the configured source omits each required snapshot field in turn
    When I add its report
    Then add refuses and names the invalid field
    And no box, tailnet device or OpenRouter key is made

  Scenario: A changed source identity is not a refresh
    Given I added a report from a configured source
    And the source returns a different stable ID or repository for the saved locator
    When I refresh the run
    Then refresh refuses the changed identity
    And the trusted snapshot and box still contain the previous report

  Scenario: Refresh uses the saved source and locator
    Given I added a report from a configured source
    And the report gains a new comment at that source
    When I refresh the run
    Then dr-hands invokes the same source and locator
    And the trusted local snapshot contains the new comment
    And report.md on the box matches the trusted snapshot

  Scenario: Source output is not terminal output
    Given a source writes control characters and report text to stdout and stderr
    When I add its report
    Then no source-controlled byte is printed to my terminal
    And add reports success or failure using fixed trusted text
    And the captured source log is stored as an untrusted file

  Scenario: Every source receives the same content scan
    Given reports from GitHub, text and a configured source contain the fixture tricks
    When I add each report
    Then each trusted snapshot has the same scanner findings
    And each box sees hidden characters as visible markers

  Scenario: A source can provide private code
    Given a configured source writes a valid code.bundle beside the snapshot
    And that bundle has a branch "poc"
    When I add its report
    Then the repository clone on the box has a branch "report/poc"
    And no credential used to fetch the bundle is on the box

  Scenario: Unexpected source files are not imported
    Given a configured source writes files other than report.json, report.md and code.bundle
    When I add its report
    Then add refuses and names the unexpected paths
    And no box, tailnet device or OpenRouter key is made
