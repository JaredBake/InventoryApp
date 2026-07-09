import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_list_model.dart';
import '../models/item.dart';
import '../providers/custom_lists_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/empty_state.dart';

class CustomListDetailScreen extends StatefulWidget {
  final CustomList customList;
  const CustomListDetailScreen({super.key, required this.customList});

  @override
  State<CustomListDetailScreen> createState() =>
      _CustomListDetailScreenState();
}

class _CustomListDetailScreenState
    extends State<CustomListDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Item> _listItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await context
        .read<CustomListsProvider>()
        .getItemsForList(widget.customList.id);
    if (mounted) setState(() { _listItems = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    // Refresh when the provider updates (rule changes etc.)
    final provider = context.watch<CustomListsProvider>();
    final list = provider.lists.firstWhere(
      (l) => l.id == widget.customList.id,
      orElse: () => widget.customList,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Items'),
            Tab(icon: Icon(Icons.rule),        text: 'Rules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildItemsTab(),
          _buildRulesTab(context, list, provider),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index == 1) {
            return FloatingActionButton(
              onPressed: () => _showAddRuleDialog(context, list),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ── Items tab ──────────────────────────────────────────────────────────────

  Widget _buildItemsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_listItems.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        message:
            'No items in this list yet.\nAdd rules to auto-populate it.',
        actionLabel: 'Add rule',
        onAction: () => _tabs.animateTo(1),
      );
    }
    return ListView.builder(
      itemCount: _listItems.length,
      itemBuilder: (_, i) => ItemCard(
        item: _listItems[i],
        onTap: () {},
        onEdit: () {},
        onDelete: () {},
        onAdjustQuantity: (_) {},
        compact: true,
      ),
    );
  }

  // ── Rules tab ──────────────────────────────────────────────────────────────

  Widget _buildRulesTab(BuildContext context, CustomList list,
      CustomListsProvider provider) {
    if (list.rules.isEmpty) {
      return EmptyState(
        icon: Icons.rule,
        message:
            'No rules yet.\nTap + to add a rule.\nItems will be auto-added when they match.',
        actionLabel: 'Add rule',
        onAction: () => _showAddRuleDialog(context, list),
      );
    }
    return ListView.builder(
      itemCount: list.rules.length,
      itemBuilder: (_, i) {
        final rule = list.rules[i];
        return ListTile(
          leading: const Icon(Icons.filter_alt_outlined),
          title: Text(rule.matchType.label),
          subtitle: Text('"${rule.value}"'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => provider.deleteRule(rule.id),
          ),
        );
      },
    );
  }

  // ── Add-rule dialog ────────────────────────────────────────────────────────

  void _showAddRuleDialog(BuildContext context, CustomList list) {
    MatchType selectedType = MatchType.nameContains;
    final valueCtrl        = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Add auto-add rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MatchType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                    labelText: 'Match type',
                    border: OutlineInputBorder()),
                items: MatchType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _rulePlaceholder(selectedType),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = valueCtrl.text.trim();
                if (value.isEmpty) return;
                context.read<CustomListsProvider>().addRule(
                      ListRule(
                          listId: list.id,
                          matchType: selectedType,
                          value: value),
                    );
                Navigator.pop(dialogCtx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _rulePlaceholder(MatchType type) {
    switch (type) {
      case MatchType.exactBarcode:
        return 'Exact barcode value';
      case MatchType.categoryMatch:
        return 'Category name (e.g. Dairy)';
      case MatchType.nameContains:
        return 'Keyword (e.g. milk)';
      case MatchType.nameStartsWith:
        return 'Prefix (e.g. Organic)';
    }
  }
}
