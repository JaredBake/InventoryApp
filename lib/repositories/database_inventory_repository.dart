import '../models/item.dart';
import '../services/database_service.dart';
import 'inventory_repository.dart';

class DatabaseInventoryRepository implements InventoryRepository {
  final DatabaseService _db;

  DatabaseInventoryRepository(this._db);

  @override
  Future<List<Item>> getAllItems() => _db.getAllItems();

  @override
  Future<List<String>> getAllCategories() => _db.getAllCategories();

  @override
  Future<void> insertItem(Item item) => _db.insertItem(item);

  @override
  Future<void> updateItem(Item item) => _db.updateItem(item);

  @override
  Future<void> deleteItem(String id) => _db.deleteItem(id);

  @override
  Future<Item?> getItemByBarcode(String barcode) => _db.getItemByBarcode(barcode);

  @override
  Future<void> close() => _db.close();
}
