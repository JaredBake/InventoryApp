import '../models/item.dart';

abstract class InventoryRepository {
  Future<List<Item>> getAllItems();
  Future<List<String>> getAllCategories();
  Future<void> insertItem(Item item);
  Future<void> updateItem(Item item);
  Future<void> deleteItem(String id);
  Future<Item?> getItemByBarcode(String barcode);
  Future<void> close();
}
