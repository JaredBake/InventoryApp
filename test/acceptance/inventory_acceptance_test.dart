import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/providers/custom_lists_provider.dart';
import 'package:inventory_app/providers/inventory_provider.dart';

import '../test_support/fakes.dart';

void main() {
  group('Acceptance scenarios', () {
    late FakeDatabaseService db;
    late FakeInventoryFfiService ffi;
    late InventoryProvider inventory;
    late CustomListsProvider lists;

    setUp(() async {
      db = FakeDatabaseService();
      ffi = FakeInventoryFfiService();
      inventory = InventoryProvider(db: db, ffi: ffi);
      lists = CustomListsProvider(db: db, ffi: ffi);

      await inventory.loadItems();
      await lists.loadLists();
    });

    test('Given item is added, then it is visible and retrievable by barcode', () async {
      final item = Item(id: 'i1', barcode: '012345', name: 'Whole Milk', category: 'Dairy', quantity: 2, price: 3.49);
      await inventory.addItem(item);

      expect(inventory.items.any((i) => i.name == 'Whole Milk'), isTrue);
      final byBarcode = await inventory.getItemByBarcode('012345');
      expect(byBarcode?.id, 'i1');
    });

    test('Given search and category filter, only expected item remains', () async {
      await inventory.addItem(Item(id: 'i1', barcode: '111', name: 'Whole Milk', category: 'Dairy'));
      await inventory.addItem(Item(id: 'i2', barcode: '222', name: 'Almond Milk', category: 'Alt'));
      await inventory.addItem(Item(id: 'i3', barcode: '333', name: 'Apple Juice', category: 'Drink'));

      inventory.setSearchQuery('milk');
      inventory.setFilterCategory('DAIRY');

      expect(inventory.items.length, 1);
      expect(inventory.items.first.name, 'Whole Milk');
    });

    test('Given category rule, matching item gets custom-list membership', () async {
      final list = CustomList(
        id: 'l1',
        name: 'Dairy List',
        rules: [
          ListRule(id: 'r1', listId: 'l1', matchType: MatchType.categoryMatch, value: 'dairy'),
        ],
      );
      await lists.addList(list);

      final item = Item(id: 'i1', barcode: '999', name: 'Cheddar', category: 'Dairy');
      await lists.applyRulesToItem(item);

      final members = await lists.getItemsForList('l1');
      expect(members.any((m) => m.id == 'i1'), isTrue);
    });

    test('Given name rules, startsWith and contains both match', () async {
      final list = CustomList(
        id: 'l1',
        name: 'Milk Keywords',
        rules: [
          ListRule(id: 'r1', listId: 'l1', matchType: MatchType.nameContains, value: 'milk'),
          ListRule(id: 'r2', listId: 'l1', matchType: MatchType.nameStartsWith, value: 'organic'),
        ],
      );
      await lists.addList(list);

      final item = Item(id: 'i2', barcode: '888', name: 'Organic Whole Milk', category: 'Dairy');
      await lists.applyRulesToItem(item);

      final members = await lists.getItemsForList('l1');
      expect(members.any((m) => m.id == 'i2'), isTrue);
    });
  });
}
