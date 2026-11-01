Feature: The agent cannot get out
  The agent runs as the user "agent" on its box. We treat it as the attacker.

  Background:
    Given I added the fixture report "plain"

  Scenario Outline: The agent cannot reach what it should not
    When the agent tries to reach <target>
    Then the attempt fails

    Examples:
      | target                                       |
      | a public DNS server                          |
      | example.com on port 443, without the proxy   |
      | the cloud metadata service                   |
      | my laptop over the tailnet                   |
      | another report's box                         |
      | example.com through the proxy                |
      | github.com on port 22                        |

  Scenario Outline: The agent can reach what triage needs
    When the agent <action> through the proxy
    Then it succeeds

    Examples:
      | action                                     |
      | clones a public repository from github.com |
      | installs a gem from rubygems.org           |
      | installs a package from npmjs.org          |
      | calls the OpenRouter API                   |

  Scenario: Only I can connect to a box
    Then the box's cloud firewall allows no inbound traffic
    And on the tailnet only I can reach the box, and only on port 22
    And the box can start no connection to any tailnet device

  Scenario: The box holds nothing worth stealing
    Then the box has no AWS credentials, GitHub token or Tailscale key
    And the box's only secret is its own report's OpenRouter key
