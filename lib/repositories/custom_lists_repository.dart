import '../models/custom_list_model.dart';
import '../models/item.dart';

abstract class CustomListsRepository {
  Future<List<CustomList>> getAllCustomLists();
  Future<void> insertCustomList(CustomList list);
  Future<void> updateCustomList(CustomList list);
  Future<void> deleteCustomList(String id);
  Future<void> insertRule(ListRule rule);
  Future<void> deleteRule(String ruleId);
  Future<void> addItemToList(String listId, String itemId);
  Future<void> removeItemFromList(String listId, String itemId);
  Future<List<Item>> getItemsForList(String listId);
  Future<void> close();
}
