import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/providers/custom_lists_provider.dart';
import 'package:inventory_app/repositories/database_custom_lists_repository.dart';

import '../test_support/fakes.dart';

void main() {
  group('CustomListsProvider integration', () {
    late FakeDatabaseService db;
    late FakeInventoryFfiService ffi;
    late CustomListsProvider provider;

    setUp(() {
      db = FakeDatabaseService();
      ffi = FakeInventoryFfiService();
      provider = CustomListsProvider(
        repository: DatabaseCustomListsRepository(db),
        ffi: ffi,
      );

      db.seedLists([
        CustomList(
          id: 'list-dairy',
          name: 'Dairy List',
          rules: [
            ListRule(id: 'r1', listId: 'list-dairy', matchType: MatchType.categoryMatch, value: 'Dairy'),
          ],
        ),
        CustomList(
          id: 'list-milk',
          name: 'Milk Keyword',
          rules: [
            ListRule(id: 'r2', listId: 'list-milk', matchType: MatchType.nameContains, value: 'milk'),
          ],
        ),
      ]);
    });

    test('loadLists and addList work end-to-end', () async {
      await provider.loadLists();
      expect(provider.lists.length, 2);

      await provider.addList(CustomList(id: 'list-new', name: 'New List'));
      expect(provider.lists.any((l) => l.id == 'list-new'), isTrue);
    });

    test('addRule and deleteRule update loaded rules', () async {
      await provider.loadLists();
      await provider.addRule(ListRule(id: 'r3', listId: 'list-dairy', matchType: MatchType.nameStartsWith, value: 'Organic'));

      final dairy = provider.lists.firstWhere((l) => l.id == 'list-dairy');
      expect(dairy.rules.any((r) => r.id == 'r3'), isTrue);

      await provider.deleteRule('r3');
      final dairyAfterDelete = provider.lists.firstWhere((l) => l.id == 'list-dairy');
      expect(dairyAfterDelete.rules.any((r) => r.id == 'r3'), isFalse);
    });

    test('applyRulesToItem adds and removes list memberships', () async {
      await provider.loadLists();
      final item = Item(id: 'item-1', barcode: '111', name: 'Whole Milk', category: 'Dairy');

      await provider.applyRulesToItem(item);
      expect(db.listContainsItem('list-dairy', 'item-1'), isTrue);
      expect(db.listContainsItem('list-milk', 'item-1'), isTrue);

      final updatedItem = item.copyWith(name: 'Orange Juice', category: 'Drink');
      await provider.applyRulesToItem(updatedItem);

      expect(db.listContainsItem('list-dairy', 'item-1'), isFalse);
      expect(db.listContainsItem('list-milk', 'item-1'), isFalse);
    });

    test('applyRulesToItem exits early with no rules', () async {
      db.seedLists([CustomList(id: 'empty-list', name: 'Empty', rules: [])]);
      await provider.loadLists();

      final item = Item(id: 'item-2', barcode: '222', name: 'Any', category: 'Any');
      await provider.applyRulesToItem(item);

      expect(db.membershipCount('empty-list'), 0);
    });
  });
}
