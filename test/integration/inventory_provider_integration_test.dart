import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/providers/inventory_provider.dart';

import '../test_support/fakes.dart';

void main() {
  group('InventoryProvider integration', () {
    late FakeDatabaseService db;
    late FakeInventoryFfiService ffi;
    late InventoryProvider provider;

    setUp(() {
      db = FakeDatabaseService();
      ffi = FakeInventoryFfiService();
      provider = InventoryProvider(db: db, ffi: ffi);

      db.seedItems([
        Item(id: '1', barcode: '111', name: 'Whole Milk', category: 'Dairy', description: 'Fresh', quantity: 2, price: 3.2),
        Item(id: '2', barcode: '222', name: 'Apple Juice', category: 'Drink', description: 'Cold', quantity: 1, price: 2.3),
        Item(id: '3', barcode: '333', name: 'Skim Milk', category: 'Dairy', description: 'Low fat', quantity: 4, price: 2.9),
      ]);
    });

    test('loadItems populates sorted items and categories', () async {
      await provider.loadItems();

      expect(provider.items.map((e) => e.name), ['Apple Juice', 'Skim Milk', 'Whole Milk']);
      expect(provider.categories, ['Dairy', 'Drink']);
    });

    test('search and category filter are combined', () async {
      await provider.loadItems();

      provider.setSearchQuery('milk');
      provider.setFilterCategory('dairy');

      expect(provider.items.map((e) => e.name), ['Skim Milk', 'Whole Milk']);
    });

    test('setSortField toggles ascending when same field selected', () async {
      await provider.loadItems();

      provider.setSortField(SortField.quantity);
      expect(provider.items.map((e) => e.quantity), [1, 2, 4]);

      provider.setSortField(SortField.quantity);
      expect(provider.items.map((e) => e.quantity), [4, 2, 1]);
    });

    test('adjustQuantity clamps at zero', () async {
      await provider.loadItems();
      final appleJuice = provider.items.firstWhere((i) => i.id == '2');

      await provider.adjustQuantity(appleJuice, -50);

      final updated = provider.items.firstWhere((i) => i.id == '2');
      expect(updated.quantity, 0);
    });

    test('add update delete item flow stays consistent', () async {
      await provider.loadItems();

      final added = Item(id: '4', barcode: '444', name: 'Bread', category: 'Bakery', quantity: 1);
      await provider.addItem(added);
      expect(provider.items.any((i) => i.id == '4'), isTrue);

      await provider.updateItem(added.copyWith(name: 'Sourdough Bread', quantity: 3));
      expect(provider.items.any((i) => i.name == 'Sourdough Bread'), isTrue);

      await provider.deleteItem('4');
      expect(provider.items.any((i) => i.id == '4'), isFalse);
    });
  });
}
