# System Test Specification (End-to-End)

## Environment

- Android emulator or device with camera simulation/input
- App built with native C++ library enabled
- Fresh local DB per scenario

## Critical user journeys

1. Inventory lifecycle
- Launch app
- Add item manually
- Edit fields
- Adjust quantity via plus/minus
- Delete item
- Verify UI and persistence consistency at each step

2. Scan-to-inventory journey
- Open scanner screen
- Simulate barcode detection
- Confirm item creation path and dedup behavior (if implemented)
- Verify scanner controller lifecycle does not leak resources on open/close cycles

3. Search/filter/sort journey
- Seed multiple items
- Use search query and category chip combinations
- Switch sort fields asc/desc
- Validate result ordering and filtering

4. Custom list management journey
- Create custom list
- Add rules for each MatchType
- Add/update items that should match and should not match
- Verify custom list detail screen items tab and rules tab
- Delete rule and list, verify cascades

## White-box system probes

- Instrument memory snapshots around repeated scanner and list-detail navigation.
- Trace native library load path by platform and ensure load occurs once per app lifecycle.

## Black-box system assertions

- Functional outcomes only: item visibility, list membership, expected labels/messages, and action success.
- No internal implementation assumptions in assertions for these tests.

## Exit criteria

- No crashes or hangs in any journey.
- No persistent growth in memory over repeated stress loops beyond acceptable threshold.
- All journey assertions pass on at least one CI emulator target.
