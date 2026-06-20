Feature: Inventory and custom-list quality gates

  As an inventory user
  I want reliable item management, filtering, sorting, and auto-list behavior
  So that I can trust the system in daily usage

  Background:
    Given the application starts with an empty local database

  Scenario: Add and retrieve an inventory item
    When I add an item with barcode "012345", name "Whole Milk", category "Dairy", quantity 2, price 3.49
    Then I should see "Whole Milk" in the home inventory list
    And the item details should show barcode "012345"

  Scenario: Search and category filter are case-insensitive
    Given inventory contains items:
      | name          | category | barcode |
      | Whole Milk    | Dairy    | 111     |
      | Almond Milk   | Alt      | 222     |
      | Apple Juice   | Drink    | 333     |
    When I search for "milk"
    And I apply category filter "DAIRY"
    Then only "Whole Milk" should be visible

  Scenario: Custom list auto-add by category rule
    Given a custom list named "Dairy List" exists
    And it has a rule "Category equals" with value "dairy"
    When I add an item named "Cheddar" with category "Dairy"
    Then "Cheddar" should appear in "Dairy List"

  Scenario: Custom list auto-add by name contains and starts with
    Given a custom list named "Milk Keywords" exists
    And it has a rule "Name contains" with value "milk"
    And it has a rule "Name starts with" with value "organic"
    When I add an item named "Organic Whole Milk"
    Then "Organic Whole Milk" should appear in "Milk Keywords"

  Scenario: Rule no-match does not create membership
    Given a custom list named "Bread List" exists
    And it has a rule "Category equals" with value "bread"
    When I add an item named "Orange Juice" with category "Drink"
    Then "Orange Juice" should not appear in "Bread List"

  Scenario: Resource stability under repeated operations
    Given the app is running on a test device
    When I repeat scanner open and close 50 times
    And I navigate into and out of custom list detail 50 times
    Then the app should remain responsive
    And no memory-leak alert should be reported by configured tooling
