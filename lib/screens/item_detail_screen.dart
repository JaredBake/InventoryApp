import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/inventory_provider.dart';
import '../providers/custom_lists_provider.dart';
import 'edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Watch so quantity changes are reflected immediately
    final inv     = context.watch<InventoryProvider>();
    final current = inv.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditItemScreen(item: current)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(item: current),
          const SizedBox(height: 16),
          _QuantityCard(item: current),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<InventoryProvider>().deleteItem(item.id);
      Navigator.pop(context);
    }
  }
}

class _InfoCard extends StatelessWidget {
  final Item item;
  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMMd().format(item.dateAdded);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Barcode',     item.barcode),
            _row('Category',    item.category.isEmpty ? '—' : item.category),
            _row('Price',       '\$${item.price.toStringAsFixed(2)}'),
            _row('Date added',  dateStr),
            if (item.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Description',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(item.description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  final Item item;
  const _QuantityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final inv = context.read<InventoryProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text('Quantity',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: item.quantity > 0
                  ? () => inv.adjustQuantity(item, -1)
                  : null,
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: Text('${item.quantity}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => inv.adjustQuantity(item, 1),
            ),
          ],
        ),
      ),
    );
  }
}
