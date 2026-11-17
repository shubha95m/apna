import '../../domain/entities/grocery_item_entity.dart';

class GroceryItemModel extends GroceryItemEntity {
  const GroceryItemModel({
    required super.id,
    required super.workspaceId,
    required super.ownerId,
    required super.name,
    super.quantity,
    super.unit,
    super.category,
    super.isPurchased,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryItemModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'pcs',
      category: json['category'] as String? ?? 'General',
      isPurchased: json['is_purchased'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'owner_id': ownerId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'is_purchased': isPurchased,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
