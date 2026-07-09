import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../repositories/inventory_repository.dart';
import '../services/inventory_ffi_service.dart';

/// Holds the full inventory state and exposes mutating operations.
class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final InventoryFfiService _ffi;

  List<Item> _allItems    = [];
  List<Item> _displayItems = [];

  SortField  _sortField   = SortField.name;
  bool       _ascending   = true;
  String     _searchQuery = '';
  String     _filterCat   = '';

  List<String> _categories = [];

  InventoryProvider({
    required InventoryRepository repository,
    required InventoryFfiService ffi,
  })  : _repository = repository,
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
    _allItems   = await _repository.getAllItems();
    _categories = await _repository.getAllCategories();
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearItems() {
    _allItems = [];
    _displayItems = [];
    _categories = [];
    _sortField = SortField.name;
    _ascending = true;
    _searchQuery = '';
    _filterCat = '';
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addItem(Item item) async {
    await _repository.insertItem(item);
    _allItems.add(item);
    _syncCategoriesFromItems();
    _applyFiltersAndSort();
    notifyListeners();
  }

  Future<void> updateItem(Item item) async {
    await _repository.updateItem(item);
    final index = _allItems.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _allItems[index] = item;
    } else {
      _allItems.add(item);
    }
    _syncCategoriesFromItems();
    _applyFiltersAndSort();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItem(id);
    _allItems.removeWhere((item) => item.id == id);
    _syncCategoriesFromItems();
    _applyFiltersAndSort();
    notifyListeners();
  }

  Future<Item?> getItemByBarcode(String barcode) =>
      _repository.getItemByBarcode(barcode);

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

  void _syncCategoriesFromItems() {
    final categories = <String>{};
    for (final item in _allItems) {
      final category = item.category.trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
    _categories = categories.toList()..sort();
  }
}
