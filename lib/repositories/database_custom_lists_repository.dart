import '../models/custom_list_model.dart';
import '../models/item.dart';
import '../services/database_service.dart';
import 'custom_lists_repository.dart';

class DatabaseCustomListsRepository implements CustomListsRepository {
  final DatabaseService _db;

  DatabaseCustomListsRepository(this._db);

  @override
  Future<List<CustomList>> getAllCustomLists() => _db.getAllCustomLists();

  @override
  Future<void> insertCustomList(CustomList list) => _db.insertCustomList(list);

  @override
  Future<void> updateCustomList(CustomList list) => _db.updateCustomList(list);

  @override
  Future<void> deleteCustomList(String id) => _db.deleteCustomList(id);

  @override
  Future<void> insertRule(ListRule rule) => _db.insertRule(rule);

  @override
  Future<void> deleteRule(String ruleId) => _db.deleteRule(ruleId);

  @override
  Future<void> addItemToList(String listId, String itemId) =>
      _db.addItemToList(listId, itemId);

  @override
  Future<void> removeItemFromList(String listId, String itemId) =>
      _db.removeItemFromList(listId, itemId);

  @override
  Future<List<Item>> getItemsForList(String listId) => _db.getItemsForList(listId);

  @override
  Future<void> close() => _db.close();
}
