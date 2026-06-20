import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/custom_list_model.dart';
import '../services/database_service.dart';
import '../services/inventory_ffi_service.dart';

/// Holds the full inventory state and exposes mutating operations.
class InventoryProvider extends ChangeNotifier {
  final DatabaseService    _db;
  final InventoryFfiService _ffi;

  List<Item> _allItems    = [];
  List<Item> _displayItems = [];

  SortField  _sortField   = SortField.name;
  bool       _ascending   = true;
  String     _searchQuery = '';
  String     _filterCat   = '';

  List<String> _categories = [];

  InventoryProvider({
    required DatabaseService    db,
    required InventoryFfiService ffi,
  })  : _db  = db,
        _ffi = ffi;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Item>   get items      => _displayItems;
  List<String> get categories => _categories;
  SortField    get sortField  => _sortField;
  bool         get ascending  => _ascending;
  String       get searchQuery => _searchQuery;
  String       get filterCat  => _filterCat;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> loadItems() async {
    _allItems   = await _db.getAllItems();
    _categories = await _db.getAllCategories();
    _applyFiltersAndSort();
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addItem(Item item) async {
    await _db.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
    await loadItems();
  }

  Future<Item?> getItemByBarcode(String barcode) =>
      _db.getItemByBarcode(barcode);

  /// Increment the quantity of an existing item by [delta] (default 1).
  Future<void> adjustQuantity(Item item, int delta) async {
    final updated = item.copyWith(quantity: (item.quantity + delta).clamp(0, 99999));
    await updateItem(updated);
  }

  // ── Sort / filter ──────────────────────────────────────────────────────────

  void setSortField(SortField field, {bool? ascending}) {
    if (_sortField == field) {
      _ascending = ascending ?? !_ascending;
    } else {
      _sortField = field;
      _ascending = ascending ?? true;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCat = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCat   = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    var result = List<Item>.from(_allItems);

    // 1. Filter via C++ (if there is a query or category selected)
    if (_searchQuery.isNotEmpty || _filterCat.isNotEmpty) {
      result = _ffi.filterItems(result,
          query: _searchQuery, category: _filterCat);
    }

    // 2. Sort via C++
    result = _ffi.sortItems(result, _sortField, ascending: _ascending);

    _displayItems = result;
  }
}
