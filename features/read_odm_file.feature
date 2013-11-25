Feature: Read ODM files
  In order to gather the basic configuration of a system,
  the application will need to read, parse, and organize ODM files.

  Scenario: Read CuDv file
    Given an CuDv file
    Given a db instance
    When fed to the parser
    Then its entries will be available.
