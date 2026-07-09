# InventoryApp Implementation Roadmap

## Goal
Build a mobile-first inventory app that works on iPhone, iPad, and Android, keeps C++ as the inventory/business-logic core, avoids web support, and stays manageable for a one-person team.

## Project Direction
- Frontend: Flutter + Dart
- Core logic: C++ via FFI
- Targets: iPhone, iPad, Android
- Non-goal: web support
- Secondary target: Windows desktop for local testing only, if useful during development

## Guiding Principles
1. Keep the UI simple and fast to use.
2. Keep native logic in C++ only when it clearly adds value.
3. Prefer stable, boring solutions over clever ones.
4. Build for one-person maintainability.
5. Add AI only after the app has enough real usage data.

## Phase 1: Lock the Platform Scope

### Step 1.1: Confirm supported platforms
- Keep Flutter and Dart for the frontend.
- Keep C++ for inventory logic and list matching.
- Remove any future work that assumes web support.
- Document iPhone, iPad, and Android as the only primary targets.

Status: completed.

Evidence from the repo:
- The app uses `dart:ffi`, which is the main reason web should remain out of scope.
- The repo has Android and iOS support paths, and Windows is currently only a local development helper.
- The app entry point is a standard Flutter `MaterialApp`, which fits the mobile-first direction.

Implemented artifacts:
- Supported platforms are documented explicitly in [README.md](README.md).
- The app remains mobile-first with desktop treated as a helper target only.

What to keep doing next:
- Avoid adding any web-specific dependencies or routes.
- Keep mobile UX decisions centered on touch, camera, and small-screen flows.
- Treat desktop as optional internal tooling only.

Done criteria:
- The target list is explicitly mobile-only.
- No new work assumes web deployment.
- Future feature decisions are checked against mobile-first scope.

### Step 1.2: Protect the FFI boundary
- Keep the Dart-to-C++ interface narrow.
- Make sure C++ structs and enums stay synchronized with Dart models.
- Avoid passing complex objects across FFI.
- Add tests around the native boundary before feature growth.

Status: completed.

Evidence from the repo:
- Dart defines `CItem` and `CRule` mirrors for the native structs.
- C++ uses packed POD structs and fixed-size fields to keep the ABI predictable.
- The FFI service has dedicated helpers for filling structs, reading output buffers, and freeing allocations.

Implemented artifacts:
- Shared native contract constants live in [lib/services/native_contract.dart](lib/services/native_contract.dart).
- The FFI service now uses those shared constants instead of local magic numbers.
- Native boundary tests now verify struct sizes and contract stability in [test/native_contract_test.dart](test/native_contract_test.dart).

What to keep doing next:
- Keep enum indexes aligned between Dart and C++.
- Keep field sizes and ordering aligned between Dart and C++.
- Keep the FFI API small and avoid pushing app-wide state through the native layer.
- Add regression tests any time a native struct or enum changes.

Done criteria:
- Dart/C++ struct layouts are confirmed to match.
- The FFI surface remains small and stable.
- Native boundary tests exist for sort, filter, rule matching, and buffer safety.

### Step 1.3: Separate UI from business logic
- UI should only gather input and display results.
- Providers should manage app state and call services.
- Database and native logic should stay in service classes.

Status: in progress.

What this means in this repo:
- Screens should stay focused on layout, navigation, dialogs, and form input.
- Providers should own state changes and user-facing workflows.
- Services should own SQL, FFI, and platform-specific behavior.

Where to watch this:
- UI entry points: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L44), [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L49)
- State orchestration: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L40), [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L25)
- Service boundaries: [lib/services/database_service.dart](lib/services/database_service.dart#L19), [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L101)

Done criteria:
- Screens do not contain SQL or FFI logic.
- Providers do not directly manage low-level native or database details.
- Services stay reusable and small.

## Phase 2: Make the App Easy to Use

### Step 2.1: Simplify item workflows
- Reduce the number of taps needed to add an item.
- Keep the add/edit screen focused and short.
- Make validation messages easy to understand.
- Add sensible default values where possible.

Status: completed.

What to do next:
- Review the add flow from [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L175) into [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L49).
- Identify fields that are required versus optional.
- Remove any UI clutter that does not help the user add or edit an item quickly.

Good first improvements:
- Keep the barcode prefill path strong from scanner to form.
- Make quantity and price input forgiving but valid.
- Make labels and placeholders more specific and less technical.

Implemented artifacts:
- The add/edit form now groups optional fields into a collapsed section in [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart).
- New items now default to quantity 1 instead of 0.
- Field labels and placeholders are more user-facing and less technical.

Done criteria:
- Adding a basic item takes as few steps as practical.
- Validation errors are clear and actionable.
- The form does not feel overloaded.

### Step 2.2: Improve empty states and guidance
- Show users what to do when the inventory is empty.
- Explain how to add an item, scan a barcode, or create a list.
- Make list/detail screens tell the user how to get started.

Status: completed.

What to do next:
- Review the empty-state component at [lib/widgets/empty_state.dart](lib/widgets/empty_state.dart#L4).
- Review where it is used in the home screen, custom lists, and custom list detail screens.
- Make sure each empty screen tells the user the next action that actually matters.

Good first improvements:
- Empty inventory should point to Add item or Scan barcode.
- Empty custom lists should point to Create list.
- Empty list detail should explain that rules populate items automatically.

Implemented artifacts:
- The reusable empty-state widget now supports an action button in [lib/widgets/empty_state.dart](lib/widgets/empty_state.dart).
- Home empty inventory now offers a direct Add item action in [lib/screens/home_screen.dart](lib/screens/home_screen.dart).
- Custom lists and custom list detail empty states now provide next-step actions.

Done criteria:
- Every empty screen gives a next step.
- The language is simple and user-friendly.
- The app never leaves the user wondering what to do next.

### Step 2.3: Add safe delete behavior
- Confirm destructive actions.
- Add undo if practical.
- Keep quantity adjustments clamped at zero.

Status: completed.

What is already there:
- Delete confirmations exist for items and custom lists.
- Quantity clamping already happens in the provider layer.

What to review next:
- Confirm delete flows are consistent across item detail, home, and custom lists.
- Decide whether any delete should support undo.
- Make sure destructive actions are visually obvious.

Good first improvements:
- Use the same confirmation pattern everywhere.
- Prevent accidental deletes by keeping the confirmation copy specific.
- Preserve zero-floor quantity behavior in all flows.

Implemented artifacts:
- A shared delete confirmation helper lives in [lib/widgets/confirm_delete_dialog.dart](lib/widgets/confirm_delete_dialog.dart).
- Home, item detail, and custom list delete flows now use the same confirmation pattern.
- Quantity clamping already remains in [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart).

Done criteria:
- Destructive actions are never one mis-tap away.
- Quantity cannot go below zero.
- Delete behavior is consistent across the app.

## Phase 3: Make Camera Support Reliable

### Step 3.1: Treat camera as a separate subsystem
- Move camera capability checks into a service or abstraction.
- Detect when the camera is unavailable.
- Provide a manual barcode fallback every time.

Status: completed.

What to do next:
- Review the current camera entry point in [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L29).
- Decide what the app should do when a device has no usable camera.
- Add a fallback route for manual entry so scanning is never the only way forward.

Good first improvements:
- Put camera availability checks behind a service or helper.
- Show a simple error state instead of failing silently.
- Keep the scan screen focused on scanning only.

Implemented artifacts:
- Camera support checks now live in [lib/services/scanner_camera_service.dart](lib/services/scanner_camera_service.dart).
- The scan screen now offers manual barcode entry even when live scanning is unavailable in [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart).
- Barcode handling is centralized so scan and manual entry follow the same item lookup flow.

Done criteria:
- Camera logic is isolated from general screen logic.
- The user always has a way to continue without scanning.
- Failure states are visible and understandable.

### Step 3.2: Improve device compatibility
- Test camera behavior on more than one device.
- Check permission handling and error messaging.
- Avoid assuming the same camera behavior across iPhone, iPad, and Android.

Status: not started.

What to do next:
- Test on at least one iPhone and one Android device when available.
- Review permission prompts and denied-permission behavior.
- Check what happens when a device rotates, sleeps, or resumes.

Good first improvements:
- Make camera startup predictable.
- Keep permission instructions short.
- Handle failure with a retry or fallback instead of a dead end.

Done criteria:
- Camera flow behaves acceptably on the target devices.
- Permission failure is handled gracefully.
- The app does not assume identical hardware support.

### Step 3.3: Make scanning less fragile
- Handle failed scans gracefully.
- Allow retry without restarting the whole app.
- Make scan-to-item lookup deterministic and predictable.

Status: in progress.

What to do next:
- Review the detection path in [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L93).
- Make sure duplicate detections do not trigger multiple navigation events.
- Make sure a failed or partial scan does not trap the user.

Good first improvements:
- Add explicit retry behavior.
- Prevent duplicate scan handling while a scan is already being processed.
- Keep lookup behavior based on a single known barcode value.

Current progress:
- Duplicate detection is centralized in a single barcode-processing path.
- Manual barcode entry uses the same lookup flow as live scans.

Done criteria:
- A failed scan can be retried cleanly.
- Duplicate detections do not create confusing results.
- The scan flow is predictable and debuggable.

## Phase 4: Strengthen Inventory and List Logic

### Step 4.1: Solidify item CRUD
- Ensure add, edit, delete, and quantity change flows remain reliable.
- Keep item identity based on the item ID.
- Preserve persistence across restarts.

### Step 4.2: Keep custom lists trustworthy
- Keep rule creation and rule matching clear.
- Ensure membership updates are automatic after item changes.
- Make list deletion clean up related records correctly.

### Step 4.3: Plan batch inventory actions
- Add the ability to subtract a list from total inventory later.
- Decide whether subtraction also clears list membership.
- Treat this as a transactional operation.

## Phase 5: Prepare for Future AI Features

### Step 5.1: Collect useful usage signals
- Track item additions and edits.
- Track quantity reductions and recurring patterns.
- Track list usage frequency.

### Step 5.2: Start with simple heuristics before AI
- Suggest items based on recency and frequency first.
- Recommend likely restocks using basic rules before ML.
- Validate usefulness before investing in a model.

### Step 5.3: Add AI only when data is sufficient
- Confirm the app has enough usage history.
- Decide what predictions are actually useful.
- Keep AI as an assistive feature, not a dependency.

## Phase 6: Keep the Project Maintainable for One Person

### Step 6.1: Keep scope tight
- Focus on mobile features that users need most.
- Avoid building low-value features early.
- Prefer improvements that reduce future support work.

### Step 6.2: Add tests around the risky parts
- Test the C++ algorithms.
- Test the provider-to-database flows.
- Test the FFI edge cases.
- Test the camera fallback path.

### Step 6.3: Keep documentation current
- Update the architecture notes when behavior changes.
- Document platform constraints.
- Record where key flows live in code.

## First Concrete Work Items
These are the best next steps to start with.

### First Work Item 1: Lock the mobile-only target
- Confirm iPhone, iPad, and Android are the only primary targets.
- Stop planning around web support.
- Keep desktop only as a development/testing helper if needed.

Current status: completed.

### First Work Item 2: Define a camera fallback strategy
- Decide what happens when the camera is unavailable.
- Add manual barcode entry as a guaranteed backup.
- Define clear user-facing error states.

Current status: not started.

### First Work Item 3: Make the FFI boundary explicit
- Verify Dart models and C++ structs match.
- Keep the native interface stable.
- Add or review tests for conversions and rule matching.

Current status: completed.

### First Work Item 4: Simplify the item add flow
- Review how many taps it takes to add an item.
- Identify the shortest path for manual entry.
- Reduce unnecessary friction in the add/edit screens.

Current status: not started.

## Implementation Order Recommendation
1. Lock platform scope.
2. Stabilize camera and barcode fallback behavior.
3. Tighten add/edit item flow.
4. Strengthen custom list workflows.
5. Add batch inventory subtraction.
6. Only then consider AI-based suggestions.

## Notes for a Solo Developer
- Prefer incremental changes.
- Keep each feature small enough to test in one session.
- Avoid parallel feature branches unless necessary.
- Do not add AI until the core workflows feel reliable and easy to use.
