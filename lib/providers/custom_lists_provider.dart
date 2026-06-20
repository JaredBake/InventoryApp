import 'package:flutter/foundation.dart';

import '../models/custom_list_model.dart';
import '../models/item.dart';
import '../services/database_service.dart';
import '../services/inventory_ffi_service.dart';

/// Holds all custom lists and manages their rules / item membership.
class CustomListsProvider extends ChangeNotifier {
  final DatabaseService    _db;
  final InventoryFfiService _ffi;

  List<CustomList> _lists = [];

  CustomListsProvider({
    required DatabaseService    db,
    required InventoryFfiService ffi,
  })  : _db  = db,
        _ffi = ffi;

  List<CustomList> get lists => _lists;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> loadLists() async {
    _lists = await _db.getAllCustomLists();
    notifyListeners();
  }

  // ── CRUD (lists) ───────────────────────────────────────────────────────────

  Future<void> addList(CustomList list) async {
    await _db.insertCustomList(list);
    await loadLists();
  }

  Future<void> updateList(CustomList list) async {
    await _db.updateCustomList(list);
    await loadLists();
  }

  Future<void> deleteList(String id) async {
    await _db.deleteCustomList(id);
    await loadLists();
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  Future<void> addRule(ListRule rule) async {
    await _db.insertRule(rule);
    await loadLists();
  }

  Future<void> deleteRule(String ruleId) async {
    await _db.deleteRule(ruleId);
    await loadLists();
  }

  // ── Item membership ────────────────────────────────────────────────────────

  Future<List<Item>> getItemsForList(String listId) =>
      _db.getItemsForList(listId);

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
        await _db.addItemToList(list.id, item.id);
      } else {
        await _db.removeItemFromList(list.id, item.id);
      }
    }
  }
}
