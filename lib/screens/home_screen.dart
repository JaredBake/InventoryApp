import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/inventory_provider.dart';
import '../providers/custom_lists_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'scanner_screen.dart';
import 'item_detail_screen.dart';
import 'edit_item_screen.dart';
import 'custom_lists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadItems();
      context.read<CustomListsProvider>().loadLists();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilterChips(context),
          Expanded(child: _buildRefreshableItemList(context)),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    return AppBar(
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search items…',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: inv.setSearchQuery,
            )
          : const Text('Inventory'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () => _refreshAllData(context),
        ),
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                inv.setSearchQuery('');
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          onPressed: () => _showSortSheet(context),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'lists') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CustomListsScreen()));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'lists', child: Text('Custom Lists')),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final cats = inv.categories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: inv.filterCat.isEmpty,
            onSelected: (_) => inv.setFilterCategory(''),
          ),
          const SizedBox(width: 8),
          ...cats.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: inv.filterCat == cat,
                onSelected: (_) => inv.setFilterCategory(
                    inv.filterCat == cat ? '' : cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshableItemList(BuildContext context) {
    final inv   = context.watch<InventoryProvider>();
    final items = inv.items;

    return RefreshIndicator(
      onRefresh: () => _refreshAllData(context),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.isEmpty ? 1 : items.length,
        itemBuilder: (ctx, i) {
          if (items.isEmpty) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: inv.searchQuery.isNotEmpty || inv.filterCat.isNotEmpty
                      ? 'No items match your search.'
                      : 'Your inventory is empty.\nTap + to scan or add an item.',
                  actionLabel: inv.searchQuery.isNotEmpty ||
                          inv.filterCat.isNotEmpty
                      ? null
                      : 'Add item',
                  onAction: inv.searchQuery.isNotEmpty || inv.filterCat.isNotEmpty
                      ? null
                      : () => _showAddOptions(context),
                ),
              ),
            );
          }

          final item = items[i];
          return ItemCard(
            item: item,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item))),
            onEdit: () => _openEdit(context, item: item),
            onDelete: () => _confirmDelete(context, item),
            onAdjustQuantity: (delta) =>
                context.read<InventoryProvider>().adjustQuantity(item, delta),
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddOptions(context),
      icon: const Icon(Icons.add),
      label: const Text('Add item'),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan barcode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScannerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Add manually'),
              onTap: () {
                Navigator.pop(context);
                _openEdit(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, {Item? item, String? barcode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditItemScreen(item: item, initialBarcode: barcode),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const SortBottomSheet(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Item item) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete item?',
      message: 'Remove "${item.name}" from inventory?',
    );
    if (confirmed == true && context.mounted) {
      context.read<InventoryProvider>().deleteItem(item.id);
    }
  }

  Future<void> _refreshAllData(BuildContext context) async {
    await Future.wait([
      context.read<InventoryProvider>().loadItems(),
      context.read<CustomListsProvider>().loadLists(),
    ]);
  }
}
