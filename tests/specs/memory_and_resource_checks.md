# Memory and Resource Check Specification

## Objectives

- Catch native memory leaks and buffer misuse in C++ logic.
- Catch Dart-side resource leaks around controllers, pointers, and repeated flows.
- Prevent regressions before release.

## C++ leak/safety checks

1. AddressSanitizer + UBSan build profile
- Compile C++ targets with:
  - -fsanitize=address,undefined
  - -fno-omit-frame-pointer
- Run inventory C++ unit tests in sanitizer mode.

2. Leak detection
- Linux CI: run tests with ASAN_OPTIONS=detect_leaks=1 or Valgrind memcheck.
- Fail pipeline on any definitely-lost or invalid read/write findings.

3. Boundary stress tests
- Repeatedly call inventory_filter_items and inventory_match_lists over randomized data.
- Include max-length strings for id/barcode/name/category/description and rule values.

## Dart/Flutter resource checks

1. FFI pointer lifecycle
- Assert all calloc allocations are paired with free in finally blocks.
- Add stress tests invoking matchingListIds repeatedly and monitor heap trend.

2. Widget/controller lifecycle
- Scanner controller and TabController are disposed exactly once per lifecycle.
- Repeated navigation does not accumulate active controllers/listeners.

3. Database lifecycle
- Ensure test databases are closed and cleaned between tests.

## Suggested CI quality gates

- Gate A: C++ unit tests pass under sanitizers.
- Gate B: Flutter unit and integration tests pass.
- Gate C: System stress scenario shows no crash and no leak alerts.
- Gate D: Acceptance suite passes.

## Evidence to retain

- Sanitizer logs
- Leak-check logs
- Test run summaries
- Device/emulator system-test traces
