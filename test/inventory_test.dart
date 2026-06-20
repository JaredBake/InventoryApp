import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/models/item.dart';
import 'package:inventory_app/models/custom_list_model.dart';

// Pure Dart unit tests – no FFI / DB required.
// Run with: flutter test

void main() {
  group('Item model', () {
    test('generates a unique id when none is provided', () {
      final a = Item(barcode: '111', name: 'A');
      final b = Item(barcode: '222', name: 'B');
      expect(a.id, isNotEmpty);
      expect(b.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('preserves provided id', () {
      final item = Item(id: 'fixed-id', barcode: '111', name: 'A');
      expect(item.id, equals('fixed-id'));
    });

    test('copyWith overrides only given fields', () {
      final original = Item(
        id: 'x',
        barcode: 'bc-1',
        name: 'Milk',
        category: 'Dairy',
        quantity: 5,
        price: 1.99,
      );
      final updated = original.copyWith(quantity: 10, price: 2.49);
      expect(updated.id,       equals('x'));
      expect(updated.barcode,  equals('bc-1'));
      expect(updated.name,     equals('Milk'));
      expect(updated.category, equals('Dairy'));
      expect(updated.quantity, equals(10));
      expect(updated.price,    closeTo(2.49, 0.001));
    });

    test('toMap / fromMap round-trip', () {
      final item = Item(
        id: 'abc',
        barcode: '012345',
        name: 'Cheese',
        category: 'Dairy',
        description: 'Sharp cheddar',
        quantity: 3,
        price: 4.99,
        dateAdded: DateTime.utc(2024, 1, 15),
      );
      final map     = item.toMap();
      final decoded = Item.fromMap(map);

      expect(decoded.id,          equals(item.id));
      expect(decoded.barcode,     equals(item.barcode));
      expect(decoded.name,        equals(item.name));
      expect(decoded.category,    equals(item.category));
      expect(decoded.description, equals(item.description));
      expect(decoded.quantity,    equals(item.quantity));
      expect(decoded.price,       closeTo(item.price, 0.001));
      expect(decoded.dateAdded.millisecondsSinceEpoch,
          equals(item.dateAdded.millisecondsSinceEpoch));
    });

    test('equality is based on id', () {
      final a = Item(id: 'same', barcode: '1', name: 'Foo');
      final b = Item(id: 'same', barcode: '2', name: 'Bar');
      final c = Item(id: 'diff', barcode: '1', name: 'Foo');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('adjustQuantity clamps to zero', () {
      var item = Item(barcode: 'x', name: 'X', quantity: 1);
      // Simulate adjustQuantity(-5) as done in InventoryProvider
      final newQty = (item.quantity - 5).clamp(0, 99999);
      item = item.copyWith(quantity: newQty);
      expect(item.quantity, equals(0));
    });
  });

  group('ListRule model', () {
    test('generates unique id', () {
      final r1 = ListRule(listId: 'l1', matchType: MatchType.nameContains, value: 'milk');
      final r2 = ListRule(listId: 'l1', matchType: MatchType.nameContains, value: 'milk');
      expect(r1.id, isNot(equals(r2.id)));
    });

    test('toMap / fromMap round-trip', () {
      final rule = ListRule(
        id: 'r1',
        listId: 'l1',
        matchType: MatchType.categoryMatch,
        value: 'Dairy',
      );
      final decoded = ListRule.fromMap(rule.toMap());
      expect(decoded.id,        equals(rule.id));
      expect(decoded.listId,    equals(rule.listId));
      expect(decoded.matchType, equals(rule.matchType));
      expect(decoded.value,     equals(rule.value));
    });
  });

  group('CustomList model', () {
    test('toMap / fromMap round-trip', () {
      final list = CustomList(
        id: 'cl1',
        name: 'Dairy Products',
        description: 'All dairy items',
      );
      final decoded = CustomList.fromMap(list.toMap());
      expect(decoded.id,          equals(list.id));
      expect(decoded.name,        equals(list.name));
      expect(decoded.description, equals(list.description));
    });

    test('default rules list is empty', () {
      final list = CustomList(name: 'Test');
      expect(list.rules, isEmpty);
    });
  });

  group('SortField labels', () {
    test('all values have non-empty labels', () {
      for (final field in SortField.values) {
        expect(field.label, isNotEmpty);
      }
    });
  });

  group('MatchType labels', () {
    test('all values have non-empty labels', () {
      for (final type in MatchType.values) {
        expect(type.label, isNotEmpty);
      }
    });
  });
}
