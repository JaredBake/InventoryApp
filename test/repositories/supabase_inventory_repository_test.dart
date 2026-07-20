import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/repositories/supabase_inventory_repository.dart';

class _InMemorySupabaseInventoryExecutor implements SupabaseInventoryExecutor {
  final List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> selectItemsByUser(String userId) async {
    final rows = _rows
        .where((row) => row['user_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    rows.sort((a, b) {
      final aName = (a['name'] as String).toLowerCase();
      final bName = (b['name'] as String).toLowerCase();
      return aName.compareTo(bName);
    });
    return rows;
  }

  @override
  Future<void> upsertItem(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final userId = row['user_id'] as String;
    final index = _rows.indexWhere(
      (existing) => existing['id'] == id && existing['user_id'] == userId,
    );
    if (index >= 0) {
      _rows[index] = Map<String, dynamic>.from(row);
      return;
    }
    _rows.add(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deleteItemByIdAndUser(String id, String userId) async {
    _rows.removeWhere(
      (row) => row['id'] == id && row['user_id'] == userId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectItemByBarcode(
    String userId,
    String barcode,
  ) async {
    return _rows
        .where(
          (row) => row['user_id'] == userId && row['barcode'] == barcode,
        )
        .take(1)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

void main() {
  group('SupabaseInventoryRepository', () {
    late _InMemorySupabaseInventoryExecutor executor;

    setUp(() {
      executor = _InMemorySupabaseInventoryExecutor();
    });

    test('add and retrieve item for same user', () async {
      final repo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );

      final item = Item(
        id: 'item-1',
        barcode: '12345',
        name: 'Milk',
        category: 'Dairy',
        description: '2%',
        quantity: 2,
        price: 3.49,
      );
      await repo.insertItem(item);

      final all = await repo.getAllItems();
      expect(all.length, 1);
      expect(all.first.name, 'Milk');
      expect(all.first.barcode, '12345');
    });

    test('supports update and delete for stored items', () async {
      final repo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );

      final original = Item(
        id: 'item-2',
        barcode: '99999',
        name: 'Bread',
        quantity: 1,
      );
      await repo.insertItem(original);

      await repo.updateItem(
        original.copyWith(name: 'Sourdough', quantity: 3, price: 5.25),
      );

      final afterUpdate = await repo.getAllItems();
      expect(afterUpdate.single.name, 'Sourdough');
      expect(afterUpdate.single.quantity, 3);
      expect(afterUpdate.single.price, 5.25);

      await repo.deleteItem('item-2');
      final afterDelete = await repo.getAllItems();
      expect(afterDelete, isEmpty);
    });

    test('items are isolated by user id', () async {
      final userARepo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );
      final userBRepo = SupabaseInventoryRepository(
        userId: 'user-b',
        executor: executor,
      );

      await userARepo.insertItem(
        Item(id: 'item-3', barcode: '111', name: 'User A Item'),
      );
      await userBRepo.insertItem(
        Item(id: 'item-4', barcode: '222', name: 'User B Item'),
      );

      final userAItems = await userARepo.getAllItems();
      final userBItems = await userBRepo.getAllItems();

      expect(userAItems.map((e) => e.name), ['User A Item']);
      expect(userBItems.map((e) => e.name), ['User B Item']);
    });

    test('same user data is persistent across repository instances', () async {
      final deviceOneRepo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );
      final deviceTwoRepo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );

      await deviceOneRepo.insertItem(
        Item(id: 'item-5', barcode: 'abc', name: 'Cross Device Cereal'),
      );

      final deviceTwoItems = await deviceTwoRepo.getAllItems();
      expect(deviceTwoItems.length, 1);
      expect(deviceTwoItems.single.name, 'Cross Device Cereal');
    });

    test('getItemByBarcode respects user scope', () async {
      final userARepo = SupabaseInventoryRepository(
        userId: 'user-a',
        executor: executor,
      );
      final userBRepo = SupabaseInventoryRepository(
        userId: 'user-b',
        executor: executor,
      );

      await userARepo.insertItem(
        Item(id: 'item-6', barcode: 'shared-code', name: 'A Product'),
      );

      final aMatch = await userARepo.getItemByBarcode('shared-code');
      final bMatch = await userBRepo.getItemByBarcode('shared-code');

      expect(aMatch?.name, 'A Product');
      expect(bMatch, isNull);
    });
  });
}