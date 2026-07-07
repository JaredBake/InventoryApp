import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventory_app/models/custom_list_model.dart';
import 'package:inventory_app/providers/custom_lists_provider.dart';
import 'package:inventory_app/screens/custom_lists_screen.dart';

import '../test_support/fakes.dart';

void main() {
  group('System test: CustomListsScreen', () {
    testWidgets('creates list through UI dialog', (tester) async {
      final db = FakeDatabaseService();
      final ffi = FakeInventoryFfiService();
      final provider = CustomListsProvider(db: db, ffi: ffi);
      await provider.loadLists();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: CustomListsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('No custom lists yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'List name'), 'Dairy List');
      await tester.enterText(find.widgetWithText(TextField, 'Description (optional)'), 'Auto dairy items');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Dairy List'), findsOneWidget);
      expect(provider.lists.any((l) => l.name == 'Dairy List'), isTrue);
    });

    testWidgets('deletes list after confirmation', (tester) async {
      final db = FakeDatabaseService();
      db.seedLists([CustomList(id: 'l1', name: 'Temp List')]);
      final ffi = FakeInventoryFfiService();
      final provider = CustomListsProvider(db: db, ffi: ffi);
      await provider.loadLists();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: CustomListsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Temp List'), findsOneWidget);
      await tester.drag(find.text('Temp List'), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Temp List'), findsNothing);
      expect(provider.lists, isEmpty);
    });
  });
}
