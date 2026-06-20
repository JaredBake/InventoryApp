import 'package:uuid/uuid.dart';

enum SortField {
  name,
  category,
  quantity,
  price,
  dateAdded,
  barcode,
}

extension SortFieldLabel on SortField {
  String get label {
    switch (this) {
      case SortField.name:
        return 'Name';
      case SortField.category:
        return 'Category';
      case SortField.quantity:
        return 'Quantity';
      case SortField.price:
        return 'Price';
      case SortField.dateAdded:
        return 'Date Added';
      case SortField.barcode:
        return 'Barcode';
    }
  }
}

/// An inventory item.
class Item {
  final String id;
  final String barcode;
  String name;
  String category;
  String description;
  int quantity;
  double price;
  final DateTime dateAdded;

  Item({
    String? id,
    required this.barcode,
    required this.name,
    this.category = '',
    this.description = '',
    this.quantity = 0,
    this.price = 0.0,
    DateTime? dateAdded,
  })  : id = id ?? const Uuid().v4(),
        dateAdded = dateAdded ?? DateTime.now();

  Item copyWith({
    String? barcode,
    String? name,
    String? category,
    String? description,
    int? quantity,
    double? price,
  }) {
    return Item(
      id: id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      dateAdded: dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'price': price,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      category: (map['category'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
          (map['date_added'] as int?) ?? 0),
    );
  }

  @override
  bool operator ==(Object other) => other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
