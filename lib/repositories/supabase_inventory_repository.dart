import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';
import 'inventory_repository.dart';

abstract class SupabaseInventoryExecutor {
  Future<List<Map<String, dynamic>>> selectItemsByUser(String userId);
  Future<void> upsertItem(Map<String, dynamic> row);
  Future<void> deleteItemByIdAndUser(String id, String userId);
  Future<List<Map<String, dynamic>>> selectItemByBarcode(String userId, String barcode);
}

class SupabasePostgrestInventoryExecutor implements SupabaseInventoryExecutor {
  final SupabaseClient _client;

  SupabasePostgrestInventoryExecutor(this._client);

  @override
  Future<List<Map<String, dynamic>>> selectItemsByUser(String userId) async {
    final rows = await _client
        .from('items')
        .select(
          'id, user_id, barcode, name, category, description, quantity, price, date_added',
        )
        .eq('user_id', userId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsertItem(Map<String, dynamic> row) async {
    await _client.from('items').upsert(row);
  }

  @override
  Future<void> deleteItemByIdAndUser(String id, String userId) async {
    await _client.from('items').delete().eq('id', id).eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectItemByBarcode(
    String userId,
    String barcode,
  ) async {
    final rows = await _client
        .from('items')
        .select(
          'id, user_id, barcode, name, category, description, quantity, price, date_added',
        )
        .eq('user_id', userId)
        .eq('barcode', barcode)
        .limit(1);
    return List<Map<String, dynamic>>.from(rows);
  }
}

class SupabaseInventoryRepository implements InventoryRepository {
  final String _userId;
  final SupabaseInventoryExecutor _executor;

  SupabaseInventoryRepository({
    required String userId,
    required SupabaseInventoryExecutor executor,
  })  : _userId = userId,
        _executor = executor;

  @override
  Future<List<Item>> getAllItems() async {
    final rows = await _executor.selectItemsByUser(_userId);
    return rows.map(_mapRowToItem).toList();
  }

  @override
  Future<List<String>> getAllCategories() async {
    final rows = await _executor.selectItemsByUser(_userId);
    final categories = <String>{};
    for (final row in rows) {
      final category = (row['category'] as String? ?? '').trim();
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }
    final sorted = categories.toList()..sort();
    return sorted;
  }

  @override
  Future<void> insertItem(Item item) async {
    await _executor.upsertItem(_itemToRow(item));
  }

  @override
  Future<void> updateItem(Item item) async {
    await _executor.upsertItem(_itemToRow(item));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _executor.deleteItemByIdAndUser(id, _userId);
  }

  @override
  Future<Item?> getItemByBarcode(String barcode) async {
    final rows = await _executor.selectItemByBarcode(_userId, barcode);
    if (rows.isEmpty) {
      return null;
    }
    return _mapRowToItem(rows.first);
  }

  @override
  Future<void> close() async {}

  Map<String, dynamic> _itemToRow(Item item) {
    return {
      'id': item.id,
      'user_id': _userId,
      'barcode': item.barcode,
      'name': item.name,
      'category': item.category,
      'description': item.description,
      'quantity': item.quantity,
      'price': item.price,
      'date_added': item.dateAdded.toUtc().toIso8601String(),
    };
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