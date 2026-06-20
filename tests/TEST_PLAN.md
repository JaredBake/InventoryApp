# InventoryApp Test Plan (No-Clone Baseline)

Date: 2026-06-20
Scope source: Remote repository metadata and code excerpts for JaredBake/InventoryApp
Constraint: Local workspace currently contains only README.md; no full repo checkout was performed.

## Quality goals

- Validate correctness across Dart models, Flutter providers/services, C++ algorithms, and FFI bridge.
- Cover both white-box and black-box perspectives.
- Detect C++ memory-safety regressions and resource misuse early.
- Establish a path from unit tests to acceptance tests.

## Test pyramid and ownership

- Unit tests (white-box + black-box):
  - C++: inventory_sort_items, inventory_filter_items, inventory_match_lists, inventory_version
  - Dart: Item, ListRule, CustomList, label extensions, FFI mapping helpers
- Integration tests:
  - Provider + database service behavior
  - Provider + FFI service rule-application behavior
  - DB persistence + custom-list membership workflow
- System tests:
  - End-to-end app flows from UI entry points (home, scanner, custom lists)
  - Native bridge behavior under realistic user flow
- Acceptance tests:
  - Business-level Given/When/Then scenarios aligned to feature table in README

## White-box coverage requirements

- C++ branch coverage:
  - all switch branches in inventory_sort_items and inventory_match_lists
  - has_query and has_category combinations in inventory_filter_items
  - null/empty guard branches
- C++ boundary coverage:
  - fixed-length char buffer truncation and null termination
  - count and rule_count edge values (0, 1, N)
  - sort determinism with equivalent keys
- Dart/FFI white-box checks:
  - proper allocation and release in matchingListIds and filter/sort bridge methods
  - behavior before load() versus after load()

## Black-box coverage requirements

- Search behavior is case-insensitive and matches name/barcode/description.
- Category filter applies exact case-insensitive matching.
- Rule matching behavior for:
  - Exact barcode
  - Category equals
  - Name contains
  - Name starts with
- CRUD outcomes visible in UI and persistence layer.

## Resource and memory-leak controls

- C++ test binaries must run with:
  - AddressSanitizer/UndefinedBehaviorSanitizer in debug CI
  - Leak checks (ASan leak detector or Valgrind on Linux CI)
- FFI tests must validate no growth trend in native allocations under repeated calls.
- System tests should include repeated navigation and scanner open/close cycles to catch controller/resource leaks.

## Required deliverables in this workspace

- Unit spec: tests/specs/unit_cpp_and_dart.md
- Integration spec: tests/specs/integration_workflows.md
- System spec: tests/specs/system_e2e.md
- Acceptance spec: tests/specs/acceptance_criteria.feature
- Leak-focused checklist: tests/specs/memory_and_resource_checks.md

## Execution sequence after repository sync

1. Run C++ unit tests with sanitizers enabled.
2. Run Flutter unit and integration tests.
3. Run system tests on Android emulator/device.
4. Run acceptance scenarios and collect traceability evidence.
5. Gate release only if all pass and no sanitizer/leak findings remain.
