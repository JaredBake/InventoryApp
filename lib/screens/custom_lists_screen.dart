import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/custom_list_model.dart';
import '../providers/custom_lists_provider.dart';
import '../widgets/empty_state.dart';
import 'custom_list_detail_screen.dart';

class CustomListsScreen extends StatelessWidget {
  const CustomListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Lists')),
      body: Consumer<CustomListsProvider>(
        builder: (ctx, provider, _) {
          final lists = provider.lists;
          if (lists.isEmpty) {
            return const EmptyState(
              icon: Icons.playlist_add,
              message:
                  'No custom lists yet.\nTap + to create one.',
            );
          }
          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (ctx, i) {
              final list = lists[i];
              return Slidable(
                key: ValueKey(list.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _confirmDelete(context, provider, list),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(list.name),
                  subtitle: Text(
                    '${list.rules.length} rule${list.rules.length == 1 ? '' : 's'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CustomListDetailScreen(customList: list)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New custom list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'List name',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              context
                  .read<CustomListsProvider>()
                  .addList(CustomList(
                      name: name, description: descCtrl.text.trim()));
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      CustomListsProvider provider, CustomList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete list?'),
        content: Text('Delete "${list.name}"?'),
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
    if (confirmed == true) provider.deleteList(list.id);
  }
}
