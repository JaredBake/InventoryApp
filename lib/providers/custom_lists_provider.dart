import 'package:flutter/foundation.dart';

import '../models/custom_list_model.dart';
import '../models/item.dart';
import '../repositories/custom_lists_repository.dart';
import '../services/inventory_ffi_service.dart';

/// Holds all custom lists and manages their rules / item membership.
class CustomListsProvider extends ChangeNotifier {
  final CustomListsRepository _repository;
  final InventoryFfiService _ffi;

  List<CustomList> _lists = [];

  CustomListsProvider({
    required CustomListsRepository repository,
    required InventoryFfiService ffi,
  })  : _repository = repository,
        _ffi = ffi;

  List<CustomList> get lists => _lists;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> loadLists() async {
    _lists = await _repository.getAllCustomLists();
    _sortListsByName();
    notifyListeners();
  }

  // ── CRUD (lists) ───────────────────────────────────────────────────────────

  Future<void> addList(CustomList list) async {
    await _repository.insertCustomList(list);
    _lists.add(list);
    _sortListsByName();
    notifyListeners();
  }

  Future<void> updateList(CustomList list) async {
    await _repository.updateCustomList(list);
    final index = _lists.indexWhere((existing) => existing.id == list.id);
    if (index >= 0) {
      _lists[index] = list;
    } else {
      _lists.add(list);
    }
    _sortListsByName();
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    await _repository.deleteCustomList(id);
    _lists.removeWhere((list) => list.id == id);
    notifyListeners();
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  Future<void> addRule(ListRule rule) async {
    await _repository.insertRule(rule);
    final list = _lists.firstWhere((candidate) => candidate.id == rule.listId);
    list.rules.add(rule);
    notifyListeners();
  }

  Future<void> deleteRule(String ruleId) async {
    final list = _lists.firstWhere(
      (candidate) => candidate.rules.any((rule) => rule.id == ruleId),
    );
    await _repository.deleteRule(ruleId);
    list.rules.removeWhere((rule) => rule.id == ruleId);
    notifyListeners();
  }

  // ── Item membership ────────────────────────────────────────────────────────

  Future<List<Item>> getItemsForList(String listId) =>
      _repository.getItemsForList(listId);

  /// After an item is added / updated, check all list rules via C++ and
  /// update list membership accordingly.
  Future<void> applyRulesToItem(Item item) async {
    // Collect every rule from every list
    final allRules = <ListRule>[];
    for (final list in _lists) {
      allRules.addAll(list.rules);
    }
    if (allRules.isEmpty) return;

    final matchedIds = _ffi.matchingListIds(item, allRules);

    // Update membership: add to matched lists, remove from non-matched lists
    for (final list in _lists) {
      final belongs = matchedIds.contains(list.id);
      if (belongs) {
        await _repository.addItemToList(list.id, item.id);
      } else {
        await _repository.removeItemFromList(list.id, item.id);
      }
    }
  }

  void _sortListsByName() {
    _lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
