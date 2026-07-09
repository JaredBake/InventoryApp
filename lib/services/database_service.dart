import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

import '../models/item.dart';
import '../models/custom_list_model.dart';

/// Manages all SQLite persistence for the app.
class DatabaseService {
  static const _guestDbName = 'inventory_guest.db';
  static const _dbVersion = 1;

  Database? _db;
  String _scopeKey = '';

  Future<Database> get db async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<void> setScopeKey(String? scopeKey) async {
    final normalized = _normalizeScopeKey(scopeKey);
    if (_scopeKey == normalized) {
      return;
    }

    await close();
    _scopeKey = normalized;
  }

  Future<Database> _openDatabase() async {
    final dbName = _scopeKey.isEmpty
        ? _guestDbName
        : 'inventory_${_scopeKey}.db';
    final dbPath = path.join(await getDatabasesPath(), dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  String _normalizeScopeKey(String? scopeKey) {
    final value = scopeKey?.trim().toLowerCase() ?? '';
    if (value.isEmpty) {
      return '';
    }

    return value
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id          TEXT PRIMARY KEY,
        barcode     TEXT NOT NULL,
        name        TEXT NOT NULL,
        category    TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        quantity    INTEGER NOT NULL DEFAULT 0,
        price       REAL NOT NULL DEFAULT 0.0,
        date_added  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_lists (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE list_rules (
        id         TEXT PRIMARY KEY,
        list_id    TEXT NOT NULL,
        match_type INTEGER NOT NULL,
        value      TEXT NOT NULL,
        FOREIGN KEY (list_id) REFERENCES custom_lists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE list_items (
        list_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        PRIMARY KEY (list_id, item_id),
        FOREIGN KEY (list_id) REFERENCES custom_lists(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_items_barcode ON items(barcode)');
    await db.execute(
        'CREATE INDEX idx_list_rules_list_id ON list_rules(list_id)');
  }

  // ── Items ──────────────────────────────────────────────────────────────────

  Future<void> insertItem(Item item) async {
    final d = await db;
    await d.insert('items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(Item item) async {
    final d = await db;
    await d.update('items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    final d = await db;
    await d.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    final d = await db;
    final rows = await d.query('items',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<List<Item>> getAllItems() async {
    final d = await db;
    final rows = await d.query('items', orderBy: 'name ASC');
    return rows.map(Item.fromMap).toList();
  }

  Future<List<String>> getAllCategories() async {
    final d = await db;
    final rows = await d.rawQuery(
        "SELECT DISTINCT category FROM items WHERE category <> '' AND TRIM(category) <> '' ORDER BY category ASC");
    return rows.map((r) => r['category'] as String).toList();
  }

  // ── Custom lists ───────────────────────────────────────────────────────────

  Future<void> insertCustomList(CustomList list) async {
    final d = await db;
    await d.insert('custom_lists', list.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final rule in list.rules) {
      await d.insert('list_rules', rule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateCustomList(CustomList list) async {
    final d = await db;
    await d.update('custom_lists', list.toMap(),
        where: 'id = ?', whereArgs: [list.id]);
  }

  Future<void> deleteCustomList(String id) async {
    final d = await db;
    await d.delete('custom_lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CustomList>> getAllCustomLists() async {
    final d = await db;
    final listRows = await d.query('custom_lists', orderBy: 'name ASC');
    final lists = <CustomList>[];
    for (final row in listRows) {
      final id = row['id'] as String;
      final ruleRows = await d.query('list_rules',
          where: 'list_id = ?', whereArgs: [id]);
      final rules = ruleRows.map(ListRule.fromMap).toList();
      lists.add(CustomList.fromMap(row, rules: rules));
    }
    return lists;
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  Future<void> insertRule(ListRule rule) async {
    final d = await db;
    await d.insert('list_rules', rule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRule(String ruleId) async {
    final d = await db;
    await d.delete('list_rules', where: 'id = ?', whereArgs: [ruleId]);
  }

  // ── List-item membership ───────────────────────────────────────────────────

  Future<void> addItemToList(String listId, String itemId) async {
    final d = await db;
    await d.insert('list_items', {'list_id': listId, 'item_id': itemId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeItemFromList(String listId, String itemId) async {
    final d = await db;
    await d.delete('list_items',
        where: 'list_id = ? AND item_id = ?',
        whereArgs: [listId, itemId]);
  }

  Future<List<Item>> getItemsForList(String listId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT i.* FROM items i
      INNER JOIN list_items li ON li.item_id = i.id
      WHERE li.list_id = ?
      ORDER BY i.name ASC
    ''', [listId]);
    return rows.map(Item.fromMap).toList();
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }
}
