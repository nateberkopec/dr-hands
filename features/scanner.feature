Feature: The scanner flags tricks in a report
  The scanner is a tripwire, not a filter. It warns me before I read a report or start the agent.

  Scenario Outline: Tricks are flagged
    When I add the fixture report "tricks"
    Then the findings flag <trick>

    Examples:
      | trick                                       |
      | hidden Unicode tag text, shown decoded      |
      | invisible or bidirectional characters       |
      | words that mix Latin and Cyrillic letters   |
      | words aimed at an AI                        |
      | a command that fetches and runs a script    |
      | a long base64-like run                      |
      | the hosts the report links to               |
      | an HTML comment and a details block         |
      | an image                                    |

  Scenario: Findings put no control characters in my terminal
    When I add the fixture report "tricks"
    Then the findings printed to my terminal are plain printable ASCII

  Scenario: The agent sees hidden characters as markers
    When I add the fixture report "tricks"
    Then advisory.md on the box shows each hidden character as a visible marker
    And the trusted copy on my laptop matches advisory.md on the box

  Scenario: A plain report has no findings
    When I add the fixture report "plain"
    Then the findings say there is nothing to flag
