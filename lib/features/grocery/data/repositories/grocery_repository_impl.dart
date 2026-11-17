import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/repositories/grocery_repository.dart';
import '../models/grocery_item_model.dart';

class GroceryRepositoryImpl implements GroceryRepository {
  final SupabaseClient _client;

  GroceryRepositoryImpl(this._client);

  @override
  Future<List<GroceryItemEntity>> getItems(String workspaceId) async {
    final response = await _client
        .from('grocery_items')
        .select()
        .eq('workspace_id', workspaceId)
        .order('is_purchased', ascending: true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => GroceryItemModel.fromJson(json)).toList();
  }

  @override
  Future<GroceryItemEntity> addItem(GroceryItemEntity item) async {
    final model = GroceryItemModel(
      id: item.id,
      workspaceId: item.workspaceId,
      ownerId: item.ownerId,
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      category: item.category,
      isPurchased: item.isPurchased,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );

    final res = await _client.from('grocery_items').insert(model.toJson()).select().single();
    return GroceryItemModel.fromJson(res);
  }

  @override
  Future<void> togglePurchased(String id, bool isPurchased) async {
    await _client.from('grocery_items').update({
      'is_purchased': isPurchased,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client.from('grocery_items').delete().eq('id', id);
  }

  @override
  Future<void> clearPurchased(String workspaceId) async {
    await _client.from('grocery_items').delete().eq('workspace_id', workspaceId).eq('is_purchased', true);
  }
}
