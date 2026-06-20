import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/inventory_provider.dart';

/// Bottom sheet to pick sort field and direction.
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Sort by',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...SortField.values.map((field) {
            final selected = inv.sortField == field;
            return ListTile(
              leading: Icon(
                _iconFor(field),
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(field.label),
              trailing: selected
                  ? Icon(
                      inv.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: selected,
              onTap: () {
                inv.setSortField(field);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconFor(SortField field) {
    switch (field) {
      case SortField.name:
        return Icons.sort_by_alpha;
      case SortField.category:
        return Icons.category_outlined;
      case SortField.quantity:
        return Icons.format_list_numbered;
      case SortField.price:
        return Icons.attach_money;
      case SortField.dateAdded:
        return Icons.calendar_today_outlined;
      case SortField.barcode:
        return Icons.barcode_reader;
    }
  }
}
