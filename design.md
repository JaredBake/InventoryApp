# InventoryApp Design and Data Flow Reference

## Purpose
This document maps where the app UI is rendered, where item add/edit actions are handled, and where data is persisted to inventory and custom lists.

## 1) Visual Display: Where the UI is Defined

### App bootstrap and global visual setup
- App startup and dependency wiring: [lib/main.dart](lib/main.dart#L11)
- Desktop DB setup needed for Windows/Linux/macOS startup: [lib/main.dart](lib/main.dart#L17), [lib/main.dart](lib/main.dart#L18)
- Provider tree for app-wide state: [lib/main.dart](lib/main.dart#L28), [lib/main.dart](lib/main.dart#L30), [lib/main.dart](lib/main.dart#L33)
- Root Material app shell: [lib/main.dart](lib/main.dart#L47)
- Theme seed color and Material 3 style: [lib/main.dart](lib/main.dart#L51), [lib/main.dart](lib/main.dart#L52)
- Initial screen route (home): [lib/main.dart](lib/main.dart#L56)

### Home screen (main visual hub)
- Home screen class: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L15)
- Main scaffold and overall screen composition: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L44), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L45)
- Initial data load trigger for both inventory and lists: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L27), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L30), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L31)
- Filter chip row rendering: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L109)
- Item list rendering area: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L142)
- Add button UI and options modal: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L175), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L183)
- Sort bottom sheet open action: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L92), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L222)

### Add/Edit item screen (form UI)
- Screen class: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L10)
- Scaffold and form layout: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L49)
- Save button in UI: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L107)
- Shared form field renderer: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L117)

### Item detail screen (read-only details + quantity controls)
- Screen class: [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L10)
- Main detail scaffold: [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L23)
- Edit and delete actions in app bar: [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L27), [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L34)
- Quantity controls UI and +/- callbacks: [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L114), [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L122), [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L133)

### Scanner screen (camera UI)
- Screen class and build: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L11), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L29)
- Camera widget and detection callback: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L50), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L52)
- Torch/camera flip controls: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L38), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L43)

### Custom lists UI
- Custom lists master screen: [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L10), [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L15)
- Create-list dialog UI and action: [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L71), [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L107)
- Delete-list confirmation UI: [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L118)

### Custom list detail UI (items + rules tabs)
- Detail screen class and scaffold: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L10), [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L47)
- Tab content routing: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L69), [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L70)
- Items tab renderer: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L90)
- Rules tab renderer: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L113)
- Add-rule dialog and save action: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L141), [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L186)

### Reusable UI widgets
- Item card visual row and swipe actions: [lib/widgets/item_card.dart](lib/widgets/item_card.dart#L7), [lib/widgets/item_card.dart](lib/widgets/item_card.dart#L31), [lib/widgets/item_card.dart](lib/widgets/item_card.dart#L126), [lib/widgets/item_card.dart](lib/widgets/item_card.dart#L134)
- Sort bottom sheet options: [lib/widgets/sort_bottom_sheet.dart](lib/widgets/sort_bottom_sheet.dart#L8), [lib/widgets/sort_bottom_sheet.dart](lib/widgets/sort_bottom_sheet.dart#L44)
- Empty-state rendering component: [lib/widgets/empty_state.dart](lib/widgets/empty_state.dart#L4), [lib/widgets/empty_state.dart](lib/widgets/empty_state.dart#L15)

---

## 2) Item Add Flow (User Perspective)

### Path A: Manual add from Home
1. User taps Add item button on Home: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L175)
2. Add options modal opens: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L183)
3. User chooses Add manually, which opens EditItemScreen: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L204), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L213)
4. User fills form and taps save: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L107)
5. Save handler validates and creates item model: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L143)

### Path B: Scan barcode first
1. User chooses Scan barcode from Add options: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L196)
2. Scanner detects barcode: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L93)
3. Existing barcode -> opens item detail: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L106), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L112)
4. New barcode -> opens EditItemScreen prefilled with barcode: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L118), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L121)

---

## 3) Item Save Flow (Code Path to Database)

### Save orchestration in EditItemScreen
- Core save function: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L143)
- Edit path -> update item: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L168)
- Add path -> insert new item: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L170)
- After save, apply rules to custom lists: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L174)

### Provider layer (inventory state + refresh)
- Inventory provider class: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L9)
- addItem entry point: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L49)
- updateItem entry point: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L54)
- deleteItem entry point: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L59)
- adjustQuantity helper: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L68)
- read/refresh inventory and categories: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L40)

### Database layer (inventory persistence)
- DB service class: [lib/services/database_service.dart](lib/services/database_service.dart#L8)
- DB open/init: [lib/services/database_service.dart](lib/services/database_service.dart#L19), [lib/services/database_service.dart](lib/services/database_service.dart#L28)
- Insert inventory row: [lib/services/database_service.dart](lib/services/database_service.dart#L79)
- Update inventory row: [lib/services/database_service.dart](lib/services/database_service.dart#L85)
- Delete inventory row: [lib/services/database_service.dart](lib/services/database_service.dart#L91)
- Fetch all items for display: [lib/services/database_service.dart](lib/services/database_service.dart#L104)
- Fetch categories for filter chips: [lib/services/database_service.dart](lib/services/database_service.dart#L110)

### Item model serialization boundary
- Item model class: [lib/models/item.dart](lib/models/item.dart#L32)
- toMap for DB writes: [lib/models/item.dart](lib/models/item.dart#L74)
- fromMap for DB reads: [lib/models/item.dart](lib/models/item.dart#L87)

---

## 4) How Items Are Saved to Lists (Custom List Membership)

### Rule definition and list creation
- MatchType enum (rule types): [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L3)
- ListRule model + persistence map: [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L26), [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L39), [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L48)
- CustomList model + map: [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L60), [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L74), [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L82)
- Manual list creation flow from UI: [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L71), [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L107)
- Manual rule creation flow from UI: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L141), [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L186)

### Rule application after item save
- Trigger after add/edit: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L174)
- Provider rule application method: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L66)
- Native matching call through FFI: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L74)
- Add item to matching list: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L80)
- Remove item from non-matching list: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L82)

### FFI rule-matching engine
- FFI service class: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L91)
- Native library load: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L101)
- Rule match function bridge: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L192)

### List membership persistence tables and methods
- list_rules table schema: [lib/services/database_service.dart](lib/services/database_service.dart#L51)
- list_items join table schema: [lib/services/database_service.dart](lib/services/database_service.dart#L61)
- Cascading delete relationships: [lib/services/database_service.dart](lib/services/database_service.dart#L56), [lib/services/database_service.dart](lib/services/database_service.dart#L65), [lib/services/database_service.dart](lib/services/database_service.dart#L66)
- Add membership row: [lib/services/database_service.dart](lib/services/database_service.dart#L169)
- Remove membership row: [lib/services/database_service.dart](lib/services/database_service.dart#L175)
- Query items in one list: [lib/services/database_service.dart](lib/services/database_service.dart#L182)

---

## 5) Data Display Refresh Loop (How UI updates after save)

### Home inventory refresh
- Home triggers load on first frame: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L30), [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L31)
- Inventory provider reloads from DB and computes display set: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L40), [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L105)
- Filtering + sorting pipeline in provider: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L86), [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L92), [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L75)

### Custom list detail refresh
- Detail screen initially pulls list items: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L36)
- UI watches CustomListsProvider for rule/list changes: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L50)
- List of rules and items tabs are rebuilt from provider + local list state: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L69), [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L70)

---

## 6) Requested Future Features Not Yet Created

### A) Auto-generating a list from previous lists created
Current state:
- Lists are manually created through dialog input only: [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L71), [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L107)
- No code currently mines prior list patterns, duplicates, naming similarities, or historical rule combinations.

Where implementation would fit:
- Add a suggestion service layer (new file likely under lib/services) that analyzes existing records from [lib/services/database_service.dart](lib/services/database_service.dart#L140)
- Expose suggested lists through provider state in [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L9)
- Add UI section in [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L15) to accept suggested templates.

### B) Subtracting list contents from total inventory after sold/used
Current state:
- list_items membership is tracked independently from inventory quantity: [lib/services/database_service.dart](lib/services/database_service.dart#L61)
- No batch operation currently decrements item quantities based on a selected list.
- Inventory quantity changes are currently single-item actions: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L68)

Where implementation would fit:
- Add DB transaction method to decrement quantities for all items in a given list and optionally clear list membership afterward in [lib/services/database_service.dart](lib/services/database_service.dart#L182)
- Add provider API to invoke this operation from UI in [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L9)
- Add a confirmation action/button in [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L47)

### C) Better camera integration and cross-device reliability
Current state:
- Camera uses mobile_scanner directly in scanner screen: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L50)
- On desktop (especially Windows), camera support can vary by driver/hardware/plugin behavior.
- No camera abstraction/fallback strategy exists today; camera logic is directly bound to one widget/controller: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L18), [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L93)

Where implementation would fit:
- Introduce a scanner service abstraction under lib/services for capability checks and fallback modes (manual barcode entry, image import scan)
- Add platform capability detection before showing scanner route in [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L196)
- Improve error and permission handling paths in [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L93)

---

## 7) Quick Index by Concern

### Visual look and layout
- [lib/main.dart](lib/main.dart#L47)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L44)
- [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L49)
- [lib/screens/item_detail_screen.dart](lib/screens/item_detail_screen.dart#L23)
- [lib/screens/custom_lists_screen.dart](lib/screens/custom_lists_screen.dart#L15)
- [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L47)

### Adding/editing item data
- [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L143)
- [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L49)
- [lib/services/database_service.dart](lib/services/database_service.dart#L79)

### Saving items to lists
- [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L174)
- [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L66)
- [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L192)
- [lib/services/database_service.dart](lib/services/database_service.dart#L169)
- [lib/services/database_service.dart](lib/services/database_service.dart#L175)

---

## 8) Feature Development Guardrails

### Keep this layering intact
- UI/screens and widgets should only gather input and trigger provider actions: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L183), [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L143)
- Providers should orchestrate state transitions and call services, but avoid SQL/FFI details directly: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L49), [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L66)
- Services own persistence and native interop details: [lib/services/database_service.dart](lib/services/database_service.dart#L79), [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L101)

### Data model invariants to preserve
- Item identity is `id`, and equality uses only `id`: [lib/models/item.dart](lib/models/item.dart#L103)
- Quantity should never go below zero in user workflows: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L68)
- Rule matching types must stay in sync between Dart and C++ enum indexes: [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L3), [cpp/include/item.h](cpp/include/item.h#L21)
- FFI struct field sizes must remain synchronized between Dart and C++: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L11), [cpp/include/item.h](cpp/include/item.h#L8)

### Database invariants to preserve
- `list_items` is a many-to-many bridge table with composite primary key: [lib/services/database_service.dart](lib/services/database_service.dart#L61)
- Cascade deletes are relied on for list and item cleanup: [lib/services/database_service.dart](lib/services/database_service.dart#L56), [lib/services/database_service.dart](lib/services/database_service.dart#L65), [lib/services/database_service.dart](lib/services/database_service.dart#L66)
- Insert semantics differ by operation (`replace` vs `ignore`) and are intentional: [lib/services/database_service.dart](lib/services/database_service.dart#L82), [lib/services/database_service.dart](lib/services/database_service.dart#L172)

---

## 9) Debugging Hotspots and What They Usually Mean

### App starts but crashes early
- Check desktop SQLite initialization first: [lib/main.dart](lib/main.dart#L17), [lib/main.dart](lib/main.dart#L18)
- Then check DB open path and schema create: [lib/services/database_service.dart](lib/services/database_service.dart#L19), [lib/services/database_service.dart](lib/services/database_service.dart#L28)

### App launches but list membership seems wrong
- Verify rules are loaded and flattened before matching: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L68)
- Verify FFI match return path and parsing: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L192)
- Verify membership add/remove branch logic: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L80), [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L82)

### Scanner behavior inconsistent by machine
- Camera plugin entry point is platform-dependent and currently direct: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L50)
- Barcode workflow decision tree lives here: [lib/screens/scanner_screen.dart](lib/screens/scanner_screen.dart#L93)

### Sorting/filtering behavior inconsistent
- Verify provider filtering/sorting pipeline order: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L105)
- Verify native filter/sort implementation used by provider: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L141), [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L158)

---

## 10) Feature Implementation Template (Recommended)

Use this sequence for each new feature to reduce regressions:

1. Define user-visible behavior and edge cases in UI terms.
2. Add or update model fields and mapping methods if needed: [lib/models/item.dart](lib/models/item.dart#L74), [lib/models/custom_list_model.dart](lib/models/custom_list_model.dart#L39)
3. Add service-level persistence or native logic changes first.
4. Expose provider methods that call those service changes.
5. Wire UI actions to provider methods.
6. Run quick manual checks and then automated tests.

Suggested pull request checklist for each feature:
- Data schema impact reviewed and migration strategy decided.
- Provider state refresh path verified.
- Empty state and loading state reviewed for each screen.
- Regression pass for add/edit/delete, filter, sort, and custom list rules.

---

## 11) Platform Constraints and Build Notes

### Current platform reality
- Android is configured in repo: [android/app/build.gradle](android/app/build.gradle)
- iOS folder exists but still requires macOS/Xcode to build and run: [ios/InventoryLib.podspec](ios/InventoryLib.podspec)
- Web is not viable for current architecture because core logic relies on `dart:ffi`: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L1)

### Windows desktop specifics
- Windows scaffolding and runner build are in: [windows/CMakeLists.txt](windows/CMakeLists.txt), [windows/runner/CMakeLists.txt](windows/runner/CMakeLists.txt)
- Native C++ DLL/source of truth remains in `cpp/`: [cpp/src/inventory_api.cpp](cpp/src/inventory_api.cpp), [cpp/include/inventory_api.h](cpp/include/inventory_api.h)

### Desktop DB specifics
- Desktop path requires `sqflite_common_ffi` initialization before first DB call: [lib/main.dart](lib/main.dart#L17)

---

## 12) Test Focus Map by Feature Area

### Inventory CRUD
- UI/form behavior: [lib/screens/edit_item_screen.dart](lib/screens/edit_item_screen.dart#L49)
- Provider behavior: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L49)
- Persistence behavior: [lib/services/database_service.dart](lib/services/database_service.dart#L79)

### Search/filter/sort
- UI controls: [lib/screens/home_screen.dart](lib/screens/home_screen.dart#L109), [lib/widgets/sort_bottom_sheet.dart](lib/widgets/sort_bottom_sheet.dart#L44)
- Provider pipeline: [lib/providers/inventory_provider.dart](lib/providers/inventory_provider.dart#L105)
- Native implementation path: [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L141), [lib/services/inventory_ffi_service.dart](lib/services/inventory_ffi_service.dart#L158)

### Custom list rules and membership
- Rule creation UI: [lib/screens/custom_list_detail_screen.dart](lib/screens/custom_list_detail_screen.dart#L141)
- Provider rule application: [lib/providers/custom_lists_provider.dart](lib/providers/custom_lists_provider.dart#L66)
- Membership persistence: [lib/services/database_service.dart](lib/services/database_service.dart#L169)

### Native C++ behavior
- Native API contracts: [cpp/include/inventory_api.h](cpp/include/inventory_api.h)
- Core native logic: [cpp/src/inventory_api.cpp](cpp/src/inventory_api.cpp)
- Native tests: [cpp/tests/inventory_tests.cpp](cpp/tests/inventory_tests.cpp)

---

## 13) Suggested Next Feature Order

If you want the most value with lowest risk first:

1. Camera fallback flow (manual barcode fallback and clear diagnostics) in scanner screen.
2. Batch inventory decrement from a selected custom list (transactional update + confirmation UI).
3. Auto-generated list suggestions from historical rules and names.

This order first stabilizes data capture, then inventory accounting, then recommendation intelligence.

---

## 14) Git Bash Quick Commands (Build and Run)

Use these in Git Bash from the project root.

### Set environment variables (per shell)
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="/c/Users/18jab/AppData/Local/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PURO="/c/Users/18jab/AppData/Local/Microsoft/WinGet/Packages/pingbird.Puro_Microsoft.Winget.Source_8wekyb3d8bbwe/puro.exe"

### Basic setup and dependency install
cd /c/Users/18jab/Projects/InventoryApp/InventoryApp
"$PURO" flutter --version
"$PURO" flutter doctor -v
"$PURO" flutter pub get

### Run on Windows desktop
"$PURO" flutter run -d windows

### Rebuild from clean state (if needed)
"$PURO" flutter clean
"$PURO" flutter pub get
"$PURO" flutter run -d windows

### Helpful run-time shortcuts
- Press `r` in the running terminal for hot reload.
- Press `R` for hot restart.
- Press `q` to quit the app.

---

## 15) App Store Compliance Design Requirements

This section updates the architecture and release workflow so the app remains compliant with Apple Developer Program terms, TestFlight restrictions, and App Store review expectations.

### 15.1 Distribution and Product Scope

- Default distribution path remains App Store + TestFlight only.
- TestFlight builds are for beta evaluation only and cannot be used as long-term production distribution.
- Current release model is free app distribution unless and until Schedule 2 (paid apps / paid digital content) is completed.
- If paid digital content is introduced later, release must be blocked until payment/legal onboarding is complete.

### 15.2 Privacy, Data, and User Consent Requirements

- A public privacy policy must exist and match actual app behavior for camera, account, and analytics-related data handling.
- Any analytics or diagnostic data must be used only for quality and performance improvements.
- App behavior must avoid attempts to de-anonymize users from aggregate diagnostics.
- TestFlight invite/contact handling must allow immediate stop-contact compliance on user request.

### 15.3 Compatibility and Maintenance Requirements

- Each iOS release cycle must include a compatibility test pass before submission.
- The app must stay compatible with currently shipping iOS versions while listed on the App Store.
- Release checklist must include simulator + physical-device smoke tests for scanner, auth, inventory CRUD, and custom lists.

### 15.4 TestFlight Constraints (Design-Time Rules)

- External TestFlight builds must pass Apple beta review before distribution.
- TestFlight builds cannot charge beta testers and cannot provide paid digital purchases.
- TestFlight should not be used to circumvent App Store release rules (e.g., perpetual demo distribution).
- If app is intended primarily for children, beta tester age-of-majority verification must be enforced in release operations.

### 15.5 In-App Purchase Guardrails (Future)

- Digital goods or premium features must use Apple in-app purchase flows when required by policy.
- No architecture decisions should assume external digital payment rails inside the iOS app UI.
- Any future premium feature spec must include:
  - product type (consumable / non-consumable / subscription),
  - App Store Connect product IDs,
  - entitlement unlock logic,
  - restore-purchase behavior,
  - refund and receipt-validation handling.

### 15.6 Security and Certificate/Signing Resilience

- Signing keys, certificates, and provisioning profiles are treated as critical secrets and stored only in approved secret managers.
- CI/CD must support emergency certificate rotation without code changes.
- If certificate revocation occurs, release and update pipelines must halt until credentials are re-issued and verified.

### 15.7 Submission and Review Transparency

- App submissions must not hide functionality or gate reviewer access behind undisclosed flows.
- Hardware-linked features (barcode scanner/camera behavior) must remain reproducible for review.
- Metadata, screenshots, and app description must accurately represent current build behavior.

### 15.8 Export/Regulatory and Regional Controls

- Release process must include an export-compliance declaration check before App Store submission.
- Regional availability decisions should be tracked in release notes/config and reflected in App Store Connect settings.

### 15.9 Operational Release Gates (Must-Pass)

Before promoting any iOS build beyond internal testing:

1. Legal/Program Gate
	- Active Apple Developer membership and accepted current agreements.
	- Correct agreement schedule status for free vs paid distribution model.

2. Security/Secrets Gate
	- Valid signing certificate + provisioning profile + API key.
	- Secrets present in CI and validated by dry-run workflow.

3. Product/Policy Gate
	- Privacy policy URL and support URL are active.
	- App metadata and age rating are complete.
	- No prohibited payment path or beta misuse pattern.

4. Technical Gate
	- Latest compatibility test pass complete.
	- Critical flow regression pass complete: sign in, add/edit/delete, scanner, custom lists.
	- Crash/ANR threshold acceptable for release.

### 15.10 Repository-Level Compliance Artifacts

The following artifacts are part of the required release baseline:

- `.github/workflows/ios-validation.yml`
- `.github/workflows/ios-app-store.yml`
- `.github/workflows/ios-app-store-submit.yml`
- `docs/github-actions-app-store.md`
- `docs/apple_license_document.md`

Any change to distribution, payments, identity, or data collection must update this design section and the release checklist before merge.
