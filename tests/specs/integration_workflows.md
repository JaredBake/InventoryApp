# Integration Test Specification

## Scope

Validate interactions among:
- DatabaseService (SQLite)
- InventoryFfiService (Dart FFI bridge)
- InventoryProvider / CustomListsProvider
- Core model objects

## Integration suite A: Provider + DB

1. Add item flow persists and reloads
- Given empty database
- When add item is invoked through provider
- Then item exists in provider state and backing DB query

2. Edit item flow updates persistence
- Given existing item
- When update is invoked
- Then updated fields are visible in both provider and DB

3. Delete item flow cascades list membership
- Given item belongs to one or more custom lists
- When item is deleted
- Then list_items entries are removed and list retrieval excludes item

## Integration suite B: Provider + FFI rule application

1. applyRulesToItem creates memberships
- Given custom lists with rules
- When item matching one or multiple rules is added/updated
- Then list_items contains expected list/item mappings

2. applyRulesToItem removes stale memberships
- Given item previously matched but now no longer matches
- When item changes category/name/barcode
- Then stale list memberships are removed

3. Multiple lists, mixed match types
- Given exact barcode, category, contains, starts-with rules across lists
- When one item is evaluated
- Then all and only expected lists are returned by FFI and persisted

## Integration suite C: DB + rule schema consistency

1. list_rules foreign key integrity
- Deleting custom list cascades to rules and list_items

2. Unique list_items primary key behavior
- Duplicate addItemToList calls are idempotent (ConflictAlgorithm.ignore)

## White-box integration checks

- Verify provider methods call loadLists at expected mutation points.
- Verify applyRulesToItem path handles empty rule collection without native calls.
- Verify FFI output slot parsing logic reads ITEM_ID_LEN boundaries correctly.

## Black-box integration checks

- User-visible resulting list membership reflects business rules regardless of internal storage details.
- Search and category filter combined behavior matches expected list in UI/provider outputs.
