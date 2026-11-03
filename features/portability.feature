Feature: Run dr-hands from macOS or Linux
  dr-hands assumes only mise and a signed-in GitHub CLI. It works from any shell and any terminal.

  Scenario Outline: A fresh machine has everything after mise install
    Given a fresh <platform> machine with only mise, git, ssh and a signed-in GitHub CLI
    When I run mise install in the dr-hands checkout
    Then every dr-hands task starts and prints its usage

    Examples:
      | platform |
      | macOS    |
      | Linux    |

  Scenario Outline: A full triage works from each platform
    Given I work from a <platform> machine
    When I add the fixture report "plain" through its fixture source, attach to the run, and remove it
    Then each step succeeds

    Examples:
      | platform |
      | macOS    |
      | Linux    |
