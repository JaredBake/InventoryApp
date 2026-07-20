import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/providers/custom_lists_provider.dart';
import 'package:inventory_app/repositories/supabase_custom_lists_repository.dart';

import '../test_support/fakes.dart';

class _InMemorySupabaseCustomListsExecutor
    implements SupabaseCustomListsExecutor {
  final List<Map<String, dynamic>> _lists = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _rules = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _listItems = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  void seedItem({
    required String id,
    required String userId,
    required String barcode,
    required String name,
    String category = '',
    String description = '',
    int quantity = 0,
    double price = 0,
  }) {
    _items.add({
      'id': id,
      'user_id': userId,
      'barcode': barcode,
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'price': price,
      'date_added': DateTime(2026, 1, 1).toIso8601String(),
    });
  }

  bool hasMembership(String userId, String listId, String itemId) {
    return _listItems.any(
      (row) =>
          row['user_id'] == userId &&
          row['list_id'] == listId &&
          row['item_id'] == itemId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectCustomListsByUser(String userId) async {
    final rows = _lists
        .where((row) => row['user_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    rows.sort(
      (a, b) =>
          (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()),
    );
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> selectRulesByList(
    String userId,
    String listId,
  ) async {
    return _rules
        .where((row) => row['user_id'] == userId && row['list_id'] == listId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<void> upsertCustomList(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final userId = row['user_id'] as String;
    final index = _lists.indexWhere(
      (existing) => existing['id'] == id && existing['user_id'] == userId,
    );
    if (index >= 0) {
      _lists[index] = Map<String, dynamic>.from(row);
      return;
    }
    _lists.add(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteCustomListByIdAndUser(String id, String userId) async {
    _lists.removeWhere((row) => row['id'] == id && row['user_id'] == userId);
    _rules.removeWhere((row) => row['list_id'] == id && row['user_id'] == userId);
    _listItems.removeWhere((row) => row['list_id'] == id && row['user_id'] == userId);
  }

  @override
  Future<void> upsertRule(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final userId = row['user_id'] as String;
    final index = _rules.indexWhere(
      (existing) => existing['id'] == id && existing['user_id'] == userId,
    );
    if (index >= 0) {
      _rules[index] = Map<String, dynamic>.from(row);
      return;
    }
    _rules.add(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteRuleByIdAndUser(String ruleId, String userId) async {
    _rules.removeWhere((row) => row['id'] == ruleId && row['user_id'] == userId);
  }

  @override
  Future<void> upsertListItem(Map<String, dynamic> row) async {
    final userId = row['user_id'] as String;
    final listId = row['list_id'] as String;
    final itemId = row['item_id'] as String;
    final index = _listItems.indexWhere(
      (existing) =>
          existing['user_id'] == userId &&
          existing['list_id'] == listId &&
          existing['item_id'] == itemId,
    );
    if (index >= 0) {
      _listItems[index] = Map<String, dynamic>.from(row);
      return;
    }
    _listItems.add(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteListItem(String userId, String listId, String itemId) async {
    _listItems.removeWhere(
      (row) =>
          row['user_id'] == userId &&
          row['list_id'] == listId &&
          row['item_id'] == itemId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectListItems(
    String userId,
    String listId,
  ) async {
    return _listItems
        .where((row) => row['user_id'] == userId && row['list_id'] == listId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectItemsByIds(
    String userId,
    List<String> itemIds,
  ) async {
    return _items
        .where((row) => row['user_id'] == userId && itemIds.contains(row['id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

void main() {
  group('CustomListsProvider + Supabase repository integration', () {
    late _InMemorySupabaseCustomListsExecutor executor;
    late CustomListsProvider provider;

    setUp(() {
      executor = _InMemorySupabaseCustomListsExecutor();
      provider = CustomListsProvider(
        repository: SupabaseCustomListsRepository(
          userId: 'user-a',
          executor: executor,
        ),
        ffi: FakeInventoryFfiService(),
      );
    });

    test('add update delete list flow is persisted for the active user', () async {
      final list = CustomList(
        id: 'list-1',
        name: 'Dairy Picks',
        description: 'Milk and cheese',
      );

      await provider.addList(list);
      await provider.loadLists();
      expect(provider.lists.length, 1);
      expect(provider.lists.single.name, 'Dairy Picks');

      await provider.updateList(
        CustomList(
          id: 'list-1',
          name: 'Dairy Favorites',
          description: 'Top dairy items',
          rules: const [],
        ),
      );
      await provider.loadLists();
      expect(provider.lists.single.name, 'Dairy Favorites');

      await provider.deleteList('list-1');
      await provider.loadLists();
      expect(provider.lists, isEmpty);
    });

    test('applyRulesToItem writes and removes list memberships', () async {
      const listId = 'list-rule-1';
      const itemId = 'item-1';

      await provider.addList(
        CustomList(
          id: listId,
          name: 'Milk Rule',
          rules: [
            ListRule(
              id: 'rule-1',
              listId: listId,
              matchType: MatchType.nameContains,
              value: 'milk',
            ),
          ],
        ),
      );
      await provider.loadLists();

      await provider.applyRulesToItem(
        Item(
          id: itemId,
          barcode: '111',
          name: 'Whole Milk',
          category: 'Dairy',
        ),
      );
      expect(executor.hasMembership('user-a', listId, itemId), isTrue);

      await provider.applyRulesToItem(
        Item(
          id: itemId,
          barcode: '111',
          name: 'Orange Juice',
          category: 'Drink',
        ),
      );
      expect(executor.hasMembership('user-a', listId, itemId), isFalse);
    });

    test('getItemsForList returns user-scoped rows only', () async {
      const listId = 'list-items';
      await provider.addList(
        CustomList(
          id: listId,
          name: 'List Items',
          rules: [
            ListRule(
              id: 'rule-items',
              listId: listId,
              matchType: MatchType.nameContains,
              value: 'bread',
            ),
          ],
        ),
      );
      await provider.loadLists();

      executor.seedItem(
        id: 'a-1',
        userId: 'user-a',
        barcode: 'a1',
        name: 'User A Bread',
      );
      executor.seedItem(
        id: 'b-1',
        userId: 'user-b',
        barcode: 'b1',
        name: 'User B Bread',
      );

      await provider.applyRulesToItem(
        Item(
          id: 'a-1',
          barcode: 'a1',
          name: 'User A Bread',
        ),
      );
      await provider.applyRulesToItem(
        Item(
          id: 'b-1',
          barcode: 'b1',
          name: 'User B Bread',
        ),
      );

      final items = await provider.getItemsForList(listId);
      expect(items.length, 1);
      expect(items.single.id, 'a-1');
    });
  });
}