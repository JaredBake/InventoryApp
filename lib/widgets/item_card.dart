import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/item.dart';

/// A single row in the inventory list.
class ItemCard extends StatelessWidget {
  final Item     item;
  final VoidCallback      onTap;
  final VoidCallback     onEdit;
  final VoidCallback     onDelete;
  final ValueChanged<int> onAdjustQuantity;

  /// When [compact] is true only the key info is shown (used in list-detail).
  final bool compact;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustQuantity,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _compactTile(context);

    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: _fullTile(context),
    );
  }

  Widget _fullTile(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _categoryAvatar(context),
      title: Text(item.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(item.barcode,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _priceQtyColumn(context),
          _quantityControls(context),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _compactTile(BuildContext context) {
    return ListTile(
      leading: _categoryAvatar(context),
      title: Text(item.name),
      subtitle: Text(item.barcode,
          style: const TextStyle(fontSize: 12)),
      trailing: Text('×${item.quantity}'),
    );
  }

  Widget _categoryAvatar(BuildContext context) {
    final initial = item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer,
      foregroundColor:
          Theme.of(context).colorScheme.onPrimaryContainer,
      child: Text(initial),
    );
  }

  Widget _priceQtyColumn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('\$${item.price.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 2),
        Text('qty: ${item.quantity}',
            style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _quantityControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        InkWell(
          onTap: item.quantity > 0 ? () => onAdjustQuantity(-1) : null,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.remove, size: 18),
          ),
        ),
        InkWell(
          onTap: () => onAdjustQuantity(1),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }
}
