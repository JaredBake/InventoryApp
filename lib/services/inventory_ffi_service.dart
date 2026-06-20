import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../models/item.dart';
import '../models/custom_list_model.dart';

// ── C struct field sizes (must match cpp/include/item.h) ────────────────────

const int _kIdLen      = 64;
const int _kBarcodeLen = 64;
const int _kNameLen    = 256;
const int _kCatLen     = 128;
const int _kDescLen    = 512;

// ── Dart FFI struct mirrors ──────────────────────────────────────────────────

/// Mirrors the packed CItem struct in cpp/include/item.h.
final class CItem extends Struct {
  @Array(_kIdLen)
  external Array<Char> id;

  @Array(_kBarcodeLen)
  external Array<Char> barcode;

  @Array(_kNameLen)
  external Array<Char> name;

  @Array(_kCatLen)
  external Array<Char> category;

  @Array(_kDescLen)
  external Array<Char> description;

  @Double()
  external double price;

  @Int64()
  external int dateAdded;

  @Int32()
  external int quantity;

  @Int32()
  // ignore: unused_field
  external int pad;
}

/// Mirrors the packed CRule struct in cpp/include/item.h.
final class CRule extends Struct {
  @Array(_kIdLen)
  external Array<Char> listId;

  @Array(_kNameLen)
  external Array<Char> value;

  @Int32()
  external int matchType;

  @Int32()
  // ignore: unused_field
  external int pad;
}

// ── Native function typedefs ─────────────────────────────────────────────────

typedef _SortItemsNative = Void Function(
    Pointer<CItem>, Int32, Int32, Int32);
typedef _SortItemsDart = void Function(
    Pointer<CItem>, int, int, int);

typedef _FilterItemsNative = Int32 Function(
    Pointer<CItem>, Int32, Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32>);
typedef _FilterItemsDart = int Function(
    Pointer<CItem>, int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32>);

typedef _MatchListsNative = Int32 Function(
    Pointer<CItem>, Pointer<CRule>, Int32, Pointer<Uint8>);
typedef _MatchListsDart = int Function(
    Pointer<CItem>, Pointer<CRule>, int, Pointer<Uint8>);

typedef _VersionNative = Pointer<Utf8> Function();
typedef _VersionDart  = Pointer<Utf8> Function();

// ── Service ──────────────────────────────────────────────────────────────────

/// Thin wrapper around the compiled libinventory shared library.
///
/// All CPU-heavy sorting, filtering, and rule-matching is delegated to C++.
class InventoryFfiService {
  late final DynamicLibrary _lib;
  late final _SortItemsDart   _sortItems;
  late final _FilterItemsDart _filterItems;
  late final _MatchListsDart  _matchLists;
  late final _VersionDart     _version;

  bool _loaded = false;

  /// Load the shared library.  Call once at app start (e.g. in main()).
  void load() {
    if (_loaded) return;

    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libinventory.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      // Desktop / tests – look next to the executable.
      final libName = Platform.isWindows
          ? 'inventory.dll'
          : Platform.isMacOS
              ? 'libinventory.dylib'
              : 'libinventory.so';
      _lib = DynamicLibrary.open(libName);
    }

    _sortItems = _lib
        .lookupFunction<_SortItemsNative, _SortItemsDart>(
            'inventory_sort_items');
    _filterItems = _lib
        .lookupFunction<_FilterItemsNative, _FilterItemsDart>(
            'inventory_filter_items');
    _matchLists = _lib
        .lookupFunction<_MatchListsNative, _MatchListsDart>(
            'inventory_match_lists');
    _version = _lib
        .lookupFunction<_VersionNative, _VersionDart>(
            'inventory_version');
    _loaded = true;
  }

  String get version {
    _assertLoaded();
    return _version().toDartString();
  }

  // ── Sorting ────────────────────────────────────────────────────────────────

  /// Return a new sorted list; the original is not modified.
  List<Item> sortItems(List<Item> items, SortField field,
      {bool ascending = true}) {
    _assertLoaded();
    if (items.isEmpty) return [];

    final ptr = _allocItems(items);
    try {
      _sortItems(ptr, items.length, field.index, ascending ? 1 : 0);
      return _readItems(ptr, items.length);
    } finally {
      calloc.free(ptr);
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  /// Return the subset of [items] that match [query] and/or [category].
  List<Item> filterItems(List<Item> items,
      {String query = '', String category = ''}) {
    _assertLoaded();
    if (items.isEmpty) return [];

    final ptr         = _allocItems(items);
    final indicesPtr  = calloc<Int32>(items.length);
    // Use calloc so every allocation in this method is freed with calloc.free.
    final queryPtr    = query.isEmpty    ? nullptr : query.toNativeUtf8(allocator: calloc);
    final categoryPtr = category.isEmpty ? nullptr : category.toNativeUtf8(allocator: calloc);
    try {
      final count = _filterItems(
          ptr, items.length,
          queryPtr,
          categoryPtr,
          indicesPtr);

      final result = <Item>[];
      for (var i = 0; i < count; i++) {
        final idx = indicesPtr[i];
        result.add(_itemFromCItem(ptr.elementAt(idx).ref));
      }
      return result;
    } finally {
      calloc.free(ptr);
      calloc.free(indicesPtr);
      if (query.isNotEmpty)    calloc.free(queryPtr);
      if (category.isNotEmpty) calloc.free(categoryPtr);
    }
  }

  // ── Custom-list matching ───────────────────────────────────────────────────

  /// Return the list IDs of every [CustomList] whose rules match [item].
  List<String> matchingListIds(Item item, List<ListRule> rules) {
    _assertLoaded();
    if (rules.isEmpty) return [];

    final itemPtr = calloc<CItem>();
    final rulesPtr = calloc<CRule>(rules.length);
    // Each slot in out_list_ids is ITEM_ID_LEN bytes wide.
    final outPtr = calloc<Uint8>(rules.length * _kIdLen);
    try {
      _fillCItem(itemPtr.ref, item);
      for (var i = 0; i < rules.length; i++) {
        _fillCRule(rulesPtr.elementAt(i).ref, rules[i]);
      }

      final count = _matchLists(itemPtr, rulesPtr, rules.length, outPtr);

      final result = <String>[];
      for (var i = 0; i < count; i++) {
        final bytes = <int>[];
        for (var j = 0; j < _kIdLen; j++) {
          final b = outPtr[i * _kIdLen + j];
          if (b == 0) break;
          bytes.add(b);
        }
        result.add(String.fromCharCodes(bytes));
      }
      return result;
    } finally {
      calloc.free(itemPtr);
      calloc.free(rulesPtr);
      calloc.free(outPtr);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _assertLoaded() {
    if (!_loaded) throw StateError('InventoryFfiService not loaded. Call load() first.');
  }

  Pointer<CItem> _allocItems(List<Item> items) {
    final ptr = calloc<CItem>(items.length);
    for (var i = 0; i < items.length; i++) {
      _fillCItem(ptr.elementAt(i).ref, items[i]);
    }
    return ptr;
  }

  List<Item> _readItems(Pointer<CItem> ptr, int count) {
    return [
      for (var i = 0; i < count; i++) _itemFromCItem(ptr.elementAt(i).ref)
    ];
  }

  void _fillCItem(CItem c, Item item) {
    _copyStr(c.id, item.id, _kIdLen);
    _copyStr(c.barcode, item.barcode, _kBarcodeLen);
    _copyStr(c.name, item.name, _kNameLen);
    _copyStr(c.category, item.category, _kCatLen);
    _copyStr(c.description, item.description, _kDescLen);
    c.price     = item.price;
    c.dateAdded = item.dateAdded.millisecondsSinceEpoch;
    c.quantity  = item.quantity;
    c.pad       = 0;
  }

  Item _itemFromCItem(CItem c) {
    return Item(
      id:          _readStr(c.id,          _kIdLen),
      barcode:     _readStr(c.barcode,     _kBarcodeLen),
      name:        _readStr(c.name,        _kNameLen),
      category:    _readStr(c.category,    _kCatLen),
      description: _readStr(c.description, _kDescLen),
      price:       c.price,
      quantity:    c.quantity,
      dateAdded:   DateTime.fromMillisecondsSinceEpoch(c.dateAdded),
    );
  }

  void _fillCRule(CRule c, ListRule rule) {
    _copyStr(c.listId, rule.listId, _kIdLen);
    _copyStr(c.value,  rule.value,  _kNameLen);
    c.matchType = rule.matchType.index;
    c.pad       = 0;
  }

  static void _copyStr(Array<Char> array, String str, int maxLen) {
    final bytes = str.codeUnits;
    final len   = bytes.length < maxLen - 1 ? bytes.length : maxLen - 1;
    for (var i = 0; i < len; i++) {
      array[i] = bytes[i];
    }
    array[len] = 0;
  }

  static String _readStr(Array<Char> array, int maxLen) {
    final bytes = <int>[];
    for (var i = 0; i < maxLen; i++) {
      final b = array[i];
      if (b == 0) break;
      bytes.add(b);
    }
    return String.fromCharCodes(bytes);
  }
}
