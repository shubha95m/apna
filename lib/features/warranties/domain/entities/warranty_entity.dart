class WarrantyEntity {
  final String id;
  final String workspaceId;
  final String itemName;
  final String brand;
  final String? modelNumber;
  final String? serialNumber;
  final DateTime purchaseDate;
  final int warrantyMonths;
  final DateTime expiryDate;
  final String? supportPhone;
  final String? supportEmail;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WarrantyEntity({
    required this.id,
    required this.workspaceId,
    required this.itemName,
    required this.brand,
    this.modelNumber,
    this.serialNumber,
    required this.purchaseDate,
    required this.warrantyMonths,
    required this.expiryDate,
    this.supportPhone,
    this.supportEmail,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;
}
