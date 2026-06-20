import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/inventory_provider.dart';
import '../providers/custom_lists_provider.dart';

/// Add a new item or edit an existing one.
class EditItemScreen extends StatefulWidget {
  final Item?   item;
  final String? initialBarcode;

  const EditItemScreen({super.key, this.item, this.initialBarcode});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _barcode;
  late TextEditingController _name;
  late TextEditingController _category;
  late TextEditingController _description;
  late TextEditingController _quantity;
  late TextEditingController _price;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _barcode     = TextEditingController(text: item?.barcode     ?? widget.initialBarcode ?? '');
    _name        = TextEditingController(text: item?.name        ?? '');
    _category    = TextEditingController(text: item?.category    ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _quantity    = TextEditingController(text: '${item?.quantity ?? 0}');
    _price       = TextEditingController(
        text: item != null ? item.price.toStringAsFixed(2) : '0.00');
  }

  @override
  void dispose() {
    for (final c in [_barcode, _name, _category, _description, _quantity, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_barcode, 'Barcode', hint: 'e.g. 012345678901',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a barcode' : null),
            _field(_name, 'Item name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null),
            _field(_category, 'Category',
                hint: 'e.g. Dairy, Snacks, Beverages'),
            _field(_description, 'Description',
                maxLines: 3, hint: 'Optional notes'),
            Row(
              children: [
                Expanded(
                  child: _field(_quantity, 'Quantity',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Enter a valid number';
                        return null;
                      }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(_price, 'Price (\$)',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null || n < 0) return 'Enter a valid price';
                        return null;
                      }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save changes' : 'Add to inventory'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines          = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final inv   = context.read<InventoryProvider>();
    final lists = context.read<CustomListsProvider>();

    final item = _isEditing
        ? widget.item!.copyWith(
            barcode:     _barcode.text.trim(),
            name:        _name.text.trim(),
            category:    _category.text.trim(),
            description: _description.text.trim(),
            quantity:    int.parse(_quantity.text),
            price:       double.parse(_price.text),
          )
        : Item(
            barcode:     _barcode.text.trim(),
            name:        _name.text.trim(),
            category:    _category.text.trim(),
            description: _description.text.trim(),
            quantity:    int.parse(_quantity.text),
            price:       double.parse(_price.text),
          );

    if (_isEditing) {
      await inv.updateItem(item);
    } else {
      await inv.addItem(item);
    }

    // Automatically place the item into any matching custom list
    await lists.applyRulesToItem(item);

    if (context.mounted) Navigator.pop(context);
  }
}
