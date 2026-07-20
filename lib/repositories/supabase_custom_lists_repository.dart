import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/custom_list_model.dart';
import '../models/item.dart';
import 'custom_lists_repository.dart';

abstract class SupabaseCustomListsExecutor {
  Future<List<Map<String, dynamic>>> selectCustomListsByUser(String userId);
  Future<List<Map<String, dynamic>>> selectRulesByList(String userId, String listId);
  Future<void> upsertCustomList(Map<String, dynamic> row);
  Future<void> deleteCustomListByIdAndUser(String id, String userId);
  Future<void> upsertRule(Map<String, dynamic> row);
  Future<void> deleteRuleByIdAndUser(String ruleId, String userId);
  Future<void> upsertListItem(Map<String, dynamic> row);
  Future<void> deleteListItem(String userId, String listId, String itemId);
  Future<List<Map<String, dynamic>>> selectListItems(String userId, String listId);
  Future<List<Map<String, dynamic>>> selectItemsByIds(String userId, List<String> itemIds);
}

class SupabasePostgrestCustomListsExecutor implements SupabaseCustomListsExecutor {
  final SupabaseClient _client;

  SupabasePostgrestCustomListsExecutor(this._client);

  @override
  Future<List<Map<String, dynamic>>> selectCustomListsByUser(String userId) async {
    final rows = await _client
        .from('custom_lists')
        .select('id, user_id, name, description')
        .eq('user_id', userId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> selectRulesByList(String userId, String listId) async {
    final rows = await _client
        .from('list_rules')
        .select('id, user_id, list_id, match_type, value')
        .eq('user_id', userId)
        .eq('list_id', listId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsertCustomList(Map<String, dynamic> row) async {
    await _client.from('custom_lists').upsert(row);
  }

  @override
  Future<void> deleteCustomListByIdAndUser(String id, String userId) async {
    await _client.from('custom_lists').delete().eq('id', id).eq('user_id', userId);
  }

  @override
  Future<void> upsertRule(Map<String, dynamic> row) async {
    await _client.from('list_rules').upsert(row);
  }

  @override
  Future<void> deleteRuleByIdAndUser(String ruleId, String userId) async {
    await _client.from('list_rules').delete().eq('id', ruleId).eq('user_id', userId);
  }

  @override
  Future<void> upsertListItem(Map<String, dynamic> row) async {
    await _client.from('list_items').upsert(row);
  }

  @override
  Future<void> deleteListItem(String userId, String listId, String itemId) async {
    await _client
        .from('list_items')
        .delete()
        .eq('user_id', userId)
        .eq('list_id', listId)
        .eq('item_id', itemId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectListItems(String userId, String listId) async {
    final rows = await _client
        .from('list_items')
        .select('item_id')
        .eq('user_id', userId)
        .eq('list_id', listId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> selectItemsByIds(String userId, List<String> itemIds) async {
    if (itemIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final rows = await _client
        .from('items')
        .select('id, user_id, barcode, name, category, description, quantity, price, date_added')
        .eq('user_id', userId)
        .inFilter('id', itemIds)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}

class SupabaseCustomListsRepository implements CustomListsRepository {
  final String _userId;
  final SupabaseCustomListsExecutor _executor;

  SupabaseCustomListsRepository({
    required String userId,
    required SupabaseCustomListsExecutor executor,
  })  : _userId = userId,
        _executor = executor;

  @override
  Future<List<CustomList>> getAllCustomLists() async {
    final listRows = await _executor.selectCustomListsByUser(_userId);
    final output = <CustomList>[];

    for (final listRow in listRows) {
      final listId = listRow['id'] as String;
      final ruleRows = await _executor.selectRulesByList(_userId, listId);
      final rules = ruleRows.map(_mapRowToRule).toList();
      output.add(
        CustomList(
          id: listId,
          name: listRow['name'] as String,
          description: (listRow['description'] as String?) ?? '',
          rules: rules,
        ),
      );
    }

    output.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return output;
  }

  @override
  Future<void> insertCustomList(CustomList list) async {
    await _executor.upsertCustomList({
      'id': list.id,
      'user_id': _userId,
      'name': list.name,
      'description': list.description,
    });
    for (final rule in list.rules) {
      await insertRule(rule);
    }
  }

  @override
  Future<void> updateCustomList(CustomList list) async {
    await _executor.upsertCustomList({
      'id': list.id,
      'user_id': _userId,
      'name': list.name,
      'description': list.description,
    });
  }

  @override
  Future<void> deleteCustomList(String id) async {
    await _executor.deleteCustomListByIdAndUser(id, _userId);
  }

  @override
  Future<void> insertRule(ListRule rule) async {
    await _executor.upsertRule({
      'id': rule.id,
      'user_id': _userId,
      'list_id': rule.listId,
      'match_type': rule.matchType.index,
      'value': rule.value,
    });
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    await _executor.deleteRuleByIdAndUser(ruleId, _userId);
  }

  @override
  Future<void> addItemToList(String listId, String itemId) async {
    await _executor.upsertListItem({
      'user_id': _userId,
      'list_id': listId,
      'item_id': itemId,
    });
  }

  @override
  Future<void> removeItemFromList(String listId, String itemId) async {
    await _executor.deleteListItem(_userId, listId, itemId);
  }

  @override
  Future<List<Item>> getItemsForList(String listId) async {
    final listItemRows = await _executor.selectListItems(_userId, listId);
    final itemIds = listItemRows
        .map((row) => row['item_id'] as String?)
        .whereType<String>()
        .toList();

    final itemRows = await _executor.selectItemsByIds(_userId, itemIds);
    return itemRows.map(_mapRowToItem).toList();
  }

  @override
  Future<void> close() async {}

  ListRule _mapRowToRule(Map<String, dynamic> row) {
    return ListRule(
      id: row['id'] as String,
      listId: row['list_id'] as String,
      matchType: MatchType.values[(row['match_type'] as num).toInt()],
      value: row['value'] as String,
    );
  }

  Item _mapRowToItem(Map<String, dynamic> row) {
    final dateAddedRaw = row['date_added'];
    final dateAdded = switch (dateAddedRaw) {
      String value => DateTime.parse(value).toLocal(),
      DateTime value => value.toLocal(),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };

    return Item(
      id: row['id'] as String,
      barcode: row['barcode'] as String,
      name: row['name'] as String,
      category: (row['category'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 0,
      price: (row['price'] as num?)?.toDouble() ?? 0,
      dateAdded: dateAdded,
    );
  }
}