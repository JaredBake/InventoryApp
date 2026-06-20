# InventoryApp

A barcode-scanning grocery/product inventory app built with **Flutter** and a **C++** business-logic core.

---

## Features

| Feature | Details |
|---|---|
| 📷 Barcode scanning | Uses the device camera via `mobile_scanner` |
| 📋 Inventory management | Full CRUD – add, view, edit, delete items |
| 🔢 Quick quantity adjust | ± buttons on every item card |
| 🔍 Search | Real-time substring search across name, barcode, description |
| 🗂 Filter by category | Category chips auto-generated from your inventory |
| ↕️ Multi-field sorting | Sort by name, category, quantity, price, date, barcode (asc/desc) |
| 📑 Custom lists | User-defined lists with auto-add rules |
| ⚡ Auto-add rules | When an item is scanned/added it is automatically placed in matching lists |

---

## Architecture

```
lib/                        ← Flutter / Dart
  main.dart                 ← App entry-point, DI setup
  models/                   ← Item, CustomList, ListRule data classes
  services/
    database_service.dart   ← SQLite persistence (sqflite)
    inventory_ffi_service.dart ← Dart FFI bridge to C++ library
  providers/                ← ChangeNotifier state management
  screens/                  ← Home, Scanner, Item Detail/Edit, Custom Lists
  widgets/                  ← ItemCard, SortBottomSheet, EmptyState

cpp/                        ← C++ shared library (libinventory.so)
  include/
    item.h                  ← CItem / CRule POD structs + enums
    inventory_api.h         ← Exported C API
  src/
    inventory_api.cpp       ← Sorting, filtering, rule-matching algorithms
  tests/
    inventory_tests.cpp     ← Standalone C++ unit tests (no Flutter needed)
  CMakeLists.txt

android/
  app/
    CMakeLists.txt          ← Builds C++ → libinventory.so via NDK
    build.gradle            ← Android app config, NDK & CMake wiring
    src/main/
      AndroidManifest.xml   ← Camera permissions
      kotlin/.../MainActivity.kt
```

### Why C++?

All CPU-intensive operations are delegated to the C++ library via **dart:ffi**:
- **Sorting** – `std::sort` with a configurable comparator across 6 fields
- **Filtering** – case-insensitive substring / exact-match filtering
- **Custom-list rule matching** – evaluates each item against all list rules simultaneously

The Dart layer handles SQLite persistence, UI rendering, and camera access.

---

## Getting started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.19 |
| Android NDK | 25.2.9519653 (via Android Studio SDK Manager) |
| CMake | ≥ 3.10 |

### Run on Android

```bash
flutter pub get
flutter run
```

The Android Gradle build automatically compiles the C++ library via the NDK.

### C++ unit tests (no Flutter needed)

```bash
cd cpp
cmake -DBUILD_TESTS=ON -B build
cmake --build build
./build/inventory_tests
```

### Flutter/Dart unit tests

```bash
flutter test
```

---

## Custom-list auto-add rules

Navigate to **Menu → Custom Lists**, create a list, then add one or more rules:

| Rule type | Matches when… |
|---|---|
| Exact barcode | Item barcode is identical (case-insensitive) |
| Category equals | Item category matches the value |
| Name contains | Item name contains the keyword |
| Name starts with | Item name begins with the prefix |

Every time an item is added or edited, the app evaluates all rules (in C++) and updates membership automatically.

---

## iOS support

The C++ library is fully portable.  
Add the following to your Xcode target's **Build Phases → Compile Sources**:
- `cpp/src/inventory_api.cpp`

And add `cpp/include` to **Header Search Paths**.  
The `InventoryFfiService` already handles iOS via `DynamicLibrary.process()`.

