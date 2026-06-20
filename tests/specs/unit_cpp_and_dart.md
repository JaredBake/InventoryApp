# Unit Test Specification (White-box and Black-box)

## C++ unit tests (inventory_api)

Target files in remote repo:
- cpp/include/item.h
- cpp/include/inventory_api.h
- cpp/src/inventory_api.cpp
- cpp/tests/inventory_tests.cpp (existing baseline)

### Black-box scenarios

1. Sorting by each supported field
- Given an unsorted item array
- When inventory_sort_items is called for each sort field asc and desc
- Then output order matches expected contract

2. Filtering by query only
- Given mixed inventory rows
- When query is milk and category is empty
- Then only rows containing milk in name/barcode/description are returned

3. Filtering by category only
- Given mixed categories
- When query is empty and category is dairy
- Then only dairy rows are returned, case-insensitive

4. Rule matching behavior
- Given one item and a rule set
- When inventory_match_lists is called
- Then matching list IDs are returned in fixed ITEM_ID_LEN slots

5. Version API
- Given no input
- When inventory_version is called
- Then non-empty semantic-ish string is returned

### White-box scenarios

1. Guard branches
- inventory_filter_items returns 0 for null items or out_indices
- inventory_match_lists returns 0 for null item/rules/out buffer or rule_count <= 0

2. Branch combinations in filter
- has_query false / has_category false
- has_query true / has_category false
- has_query false / has_category true
- has_query true / has_category true

3. MatchType switch coverage
- MATCH_EXACT_BARCODE
- MATCH_CATEGORY
- MATCH_NAME_CONTAINS
- MATCH_NAME_STARTS_WITH
- default branch for invalid enum value

4. Buffer safety checks
- list_id and rule.value at exactly max length - 1
- overlength input truncation preserves trailing null byte
- out_list_ids slot math: matched * ITEM_ID_LEN does not overwrite neighbor slots

5. Determinism and stability expectations
- repeated sort invocations produce deterministic output for identical input

## Dart unit tests

Target files in remote repo:
- test/inventory_test.dart (existing baseline)
- lib/models/item.dart
- lib/models/custom_list_model.dart
- lib/services/inventory_ffi_service.dart

### Black-box scenarios

1. Item model map round-trip and copyWith semantics
2. ListRule and CustomList map round-trip
3. Label extensions return non-empty user-readable labels

### White-box scenarios

1. FFI service state guard
- methods requiring native symbols must throw/assert before load()

2. FFI marshaling bounds
- UTF-8 strings copied into C struct fields must truncate safely
- no malformed output when strings are near struct field limits

3. Repeated native calls
- calling sort/filter/matching in loops does not leave stale state in Dart layer

## Additional unit tests to add beyond existing baseline

- Invalid sort field value behavior (no crash, deterministic fallback)
- Empty inventory input across all APIs
- Non-ASCII edge input handling policy (document expected behavior)
- Extremely large quantity/price/date values within representable ranges
