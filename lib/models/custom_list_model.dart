import 'package:uuid/uuid.dart';

enum MatchType {
  exactBarcode,
  categoryMatch,
  nameContains,
  nameStartsWith,
}

extension MatchTypeLabel on MatchType {
  String get label {
    switch (this) {
      case MatchType.exactBarcode:
        return 'Exact barcode';
      case MatchType.categoryMatch:
        return 'Category equals';
      case MatchType.nameContains:
        return 'Name contains';
      case MatchType.nameStartsWith:
        return 'Name starts with';
    }
  }
}

/// A single auto-add rule for a [CustomList].
class ListRule {
  final String id;
  final String listId;
  final MatchType matchType;
  final String value;

  ListRule({
    String? id,
    required this.listId,
    required this.matchType,
    required this.value,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'match_type': matchType.index,
      'value': value,
    };
  }

  factory ListRule.fromMap(Map<String, dynamic> map) {
    return ListRule(
      id: map['id'] as String,
      listId: map['list_id'] as String,
      matchType: MatchType.values[map['match_type'] as int],
      value: map['value'] as String,
    );
  }
}

/// A user-defined list that can automatically receive items whose details
/// match one or more [ListRule]s.
class CustomList {
  final String id;
  String name;
  String description;
  List<ListRule> rules;

  CustomList({
    String? id,
    required this.name,
    this.description = '',
    List<ListRule>? rules,
  })  : id = id ?? const Uuid().v4(),
        rules = rules ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory CustomList.fromMap(Map<String, dynamic> map,
      {List<ListRule>? rules}) {
    return CustomList(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      rules: rules ?? [],
    );
  }
}
