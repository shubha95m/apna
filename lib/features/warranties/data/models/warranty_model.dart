import '../../domain/entities/warranty_entity.dart';

class WarrantyModel extends WarrantyEntity {
  const WarrantyModel({
    required super.id,
    required super.workspaceId,
    required super.itemName,
    required super.brand,
    super.modelNumber,
    super.serialNumber,
    required super.purchaseDate,
    required super.warrantyMonths,
    required super.expiryDate,
    super.supportPhone,
    super.supportEmail,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WarrantyModel.fromEntity(WarrantyEntity entity) {
    return WarrantyModel(
      id: entity.id,
      workspaceId: entity.workspaceId,
      itemName: entity.itemName,
      brand: entity.brand,
      modelNumber: entity.modelNumber,
      serialNumber: entity.serialNumber,
      purchaseDate: entity.purchaseDate,
      warrantyMonths: entity.warrantyMonths,
      expiryDate: entity.expiryDate,
      supportPhone: entity.supportPhone,
      supportEmail: entity.supportEmail,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory WarrantyModel.fromMap(Map<String, dynamic> map) {
    return WarrantyModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      itemName: map['item_name'] as String,
      brand: map['brand'] as String,
      modelNumber: map['model_number'] as String?,
      serialNumber: map['serial_number'] as String?,
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      warrantyMonths: map['warranty_months'] as int? ?? 12,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      supportPhone: map['support_phone'] as String?,
      supportEmail: map['support_email'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'item_name': itemName,
      'brand': brand,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'warranty_months': warrantyMonths,
      'expiry_date': expiryDate.toIso8601String().split('T').first,
      'support_phone': supportPhone,
      'support_email': supportEmail,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
