Feature: A run's AI key can do little harm
  Each run's key lives in the dr-hands OpenRouter workspace. The workspace rules hold whatever the box sends.

  Background:
    Given setup-openrouter has run
    And a key made for a run

  Scenario: An allowed model answers
    When the key asks the first model in DR_HANDS_MODELS a question
    Then the model answers

  Scenario: A model outside the allowlist is refused
    When the key asks a model that is not in DR_HANDS_MODELS a question
    Then OpenRouter refuses the request

  Scenario Outline: Hosted tools are refused
    When the key sends a request that offers <tool>
    Then OpenRouter refuses the request

    Examples:
      | tool                                                 |
      | the openrouter:web_fetch server tool                 |
      | the openrouter:web_search server tool                |
      | the openrouter:shell server tool                     |
      | the deprecated web plugin                            |
      | Anthropic's web_search tool through the Messages API |

  Scenario: A key past its dollar limit is refused
    Given a key made for a run with a limit of 0 dollars
    When the key asks the first model in DR_HANDS_MODELS a question
    Then OpenRouter refuses the request

  Scenario: A removed run's key stops working
    Given I added the fixture report "plain" through its fixture source
    And I copied the run's key off the box
    When I remove the run
    Then the copied key is refused
