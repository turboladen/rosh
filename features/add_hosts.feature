Feature: Add hosts
  As a Rosh user, I want to be able to add hosts to the shell so that I can
  manage these other hosts from the shell.

  Scenario: Add a remote host
    Given there is a host at "192.168.33.102"
    When I add that host to the shell
    Then I can run commands on it:
    | Command |
    | pwd   |
    And get a response as a Ruby object

  Scenario: Update a remote host
    Given there is a host at "192.168.33.102"
    And I add that host to the shell
    When I set the "user" option to "vagrant"
    Then I can run commands on it:
      | Command |
      | pwd   |

  Scenario: Add a local host
    Given there is a host at "localhost"
    When I add that host to the shell
    Then I can run commands on it:
      | Command |
      | pwd   |
    And get a response as a Ruby object
