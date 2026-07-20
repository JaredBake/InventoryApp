import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/providers/inventory_provider.dart';
import 'package:inventory_app/repositories/supabase_inventory_repository.dart';

import '../test_support/fakes.dart';

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
  group('InventoryProvider + Supabase repository integration', () {
    late _InMemorySupabaseInventoryExecutor executor;
    late InventoryProvider provider;

    setUp(() {
      executor = _InMemorySupabaseInventoryExecutor();
      provider = InventoryProvider(
        repository: SupabaseInventoryRepository(
          userId: 'user-a',
          executor: executor,
        ),
        ffi: FakeInventoryFfiService(),
      );
    });

    test('add update delete flows are persisted in user scoped rows', () async {
      final item = Item(
        id: 'provider-item-1',
        barcode: 'provider-111',
        name: 'Provider Milk',
        category: 'Dairy',
        quantity: 2,
        price: 4.10,
      );

      await provider.addItem(item);
      await provider.loadItems();
      expect(provider.items.length, 1);
      expect(provider.items.single.name, 'Provider Milk');

      final updated = item.copyWith(
        name: 'Provider Skim Milk',
        quantity: 5,
        price: 4.75,
      );
      await provider.updateItem(updated);
      await provider.loadItems();
      expect(provider.items.single.name, 'Provider Skim Milk');
      expect(provider.items.single.quantity, 5);
      expect(provider.items.single.price, 4.75);

      await provider.deleteItem(item.id);
      await provider.loadItems();
      expect(provider.items, isEmpty);
    });

    test('user scope is enforced by repository', () async {
      final userBRepository = SupabaseInventoryRepository(
        userId: 'user-b',
        executor: executor,
      );
      final item = Item(
        id: 'provider-item-2',
        barcode: 'provider-222',
        name: 'User A Only',
      );

      await provider.addItem(item);

      final userBItems = await userBRepository.getAllItems();
      expect(userBItems, isEmpty);
    });
  });
}