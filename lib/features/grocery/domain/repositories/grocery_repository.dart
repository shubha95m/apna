import '../entities/grocery_item_entity.dart';

abstract class GroceryRepository {
  Future<List<GroceryItemEntity>> getItems(String workspaceId);
  Future<GroceryItemEntity> addItem(GroceryItemEntity item);
  Future<void> togglePurchased(String id, bool isPurchased);
  Future<void> deleteItem(String id);
  Future<void> clearPurchased(String workspaceId);
}
