class GroceryItemEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryItemEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.name,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.category = 'General',
    this.isPurchased = false,
    required this.createdAt,
    required this.updatedAt,
  });

  GroceryItemEntity copyWith({
    String? id,
    String? workspaceId,
    String? ownerId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    bool? isPurchased,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryItemEntity(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
