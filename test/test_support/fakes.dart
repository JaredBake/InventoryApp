import 'dart:collection';

import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/services/database_service.dart';
import 'package:inventory_app/services/inventory_ffi_service.dart';

class FakeDatabaseService extends DatabaseService {
  final Map<String, Item> _items = <String, Item>{};
  final Map<String, CustomList> _lists = <String, CustomList>{};
  final Map<String, ListRule> _rules = <String, ListRule>{};
  final Map<String, Set<String>> _listItems = <String, Set<String>>{};

  void seedItems(Iterable<Item> items) {
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  void seedLists(Iterable<CustomList> lists) {
    for (final list in lists) {
      _lists[list.id] = CustomList(
        id: list.id,
        name: list.name,
        description: list.description,
        rules: List<ListRule>.from(list.rules),
      );
      for (final rule in list.rules) {
        _rules[rule.id] = rule;
      }
    }
  }

  bool listContainsItem(String listId, String itemId) {
    return _listItems[listId]?.contains(itemId) ?? false;
  }

  int membershipCount(String listId) {
    return _listItems[listId]?.length ?? 0;
  }

  @override
  Future<void> insertItem(Item item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> updateItem(Item item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.remove(id);
    for (final set in _listItems.values) {
      set.remove(id);
    }
  }

  @override
  Future<Item?> getItemByBarcode(String barcode) async {
    for (final item in _items.values) {
      if (item.barcode == barcode) return item;
    }
    return null;
  }

  @override
  Future<List<Item>> getAllItems() async {
    final items = _items.values.toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  @override
  Future<List<String>> getAllCategories() async {
    final categories = SplayTreeSet<String>(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    for (final item in _items.values) {
      if (item.category.isNotEmpty) categories.add(item.category);
    }
    return categories.toList();
  }

  @override
  Future<void> insertCustomList(CustomList list) async {
    _lists[list.id] = CustomList(
      id: list.id,
      name: list.name,
      description: list.description,
      rules: List<ListRule>.from(list.rules),
    );
    for (final rule in list.rules) {
      _rules[rule.id] = rule;
    }
  }

  @override
  Future<void> updateCustomList(CustomList list) async {
    final existing = _lists[list.id];
    if (existing == null) return;
    existing.name = list.name;
    existing.description = list.description;
  }

  @override
  Future<void> deleteCustomList(String id) async {
    _lists.remove(id);
    _listItems.remove(id);
    _rules.removeWhere((_, rule) => rule.listId == id);
  }

  @override
  Future<List<CustomList>> getAllCustomLists() async {
    final lists = _lists.values
        .map(
          (list) => CustomList(
            id: list.id,
            name: list.name,
            description: list.description,
            rules: _rules.values
                .where((r) => r.listId == list.id)
                .map(
                  (r) => ListRule(
                    id: r.id,
                    listId: r.listId,
                    matchType: r.matchType,
                    value: r.value,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return lists;
  }

  @override
  Future<void> insertRule(ListRule rule) async {
    _rules[rule.id] = rule;
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    _rules.remove(ruleId);
  }

  @override
  Future<void> addItemToList(String listId, String itemId) async {
    final set = _listItems.putIfAbsent(listId, () => <String>{});
    set.add(itemId);
  }

  @override
  Future<void> removeItemFromList(String listId, String itemId) async {
    _listItems[listId]?.remove(itemId);
  }

  @override
  Future<List<Item>> getItemsForList(String listId) async {
    final ids = _listItems[listId] ?? <String>{};
    final items = ids
        .map((id) => _items[id])
        .whereType<Item>()
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  @override
  Future<void> close() async {}
}

class FakeInventoryFfiService extends InventoryFfiService {
  @override
  String get version => 'fake-1.0.0';

  @override
  List<Item> sortItems(List<Item> items, SortField field, {bool ascending = true}) {
    final out = List<Item>.from(items);
    int compare(Item a, Item b) {
      switch (field) {
        case SortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.category:
          return a.category.toLowerCase().compareTo(b.category.toLowerCase());
        case SortField.quantity:
          return a.quantity.compareTo(b.quantity);
        case SortField.price:
          return a.price.compareTo(b.price);
        case SortField.dateAdded:
          return a.dateAdded.compareTo(b.dateAdded);
        case SortField.barcode:
          return a.barcode.toLowerCase().compareTo(b.barcode.toLowerCase());
      }
    }

    out.sort((a, b) => ascending ? compare(a, b) : compare(b, a));
    return out;
  }

  @override
  List<Item> filterItems(List<Item> items, {String query = '', String category = ''}) {
    final q = query.trim().toLowerCase();
    final c = category.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.barcode.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
      final matchesCategory = c.isEmpty || item.category.toLowerCase() == c;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  List<String> matchingListIds(Item item, List<ListRule> rules) {
    final out = <String>[];
    final name = item.name.toLowerCase();
    final category = item.category.toLowerCase();
    final barcode = item.barcode.toLowerCase();

    for (final rule in rules) {
      final value = rule.value.toLowerCase();
      final hit = switch (rule.matchType) {
        MatchType.exactBarcode => barcode == value,
        MatchType.categoryMatch => category == value,
        MatchType.nameContains => name.contains(value),
        MatchType.nameStartsWith => name.startsWith(value),
      };
      if (hit) out.add(rule.listId);
    }

    return out;
  }
}
