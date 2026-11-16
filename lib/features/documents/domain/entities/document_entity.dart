enum DocumentCategory {
  kyc,
  insurance,
  property,
  vehicle,
  medical,
  financial,
  education,
  agreements,
  other,
}

extension DocumentCategoryExt on DocumentCategory {
  String get displayName => switch (this) {
        DocumentCategory.kyc => 'Identity & KYC',
        DocumentCategory.insurance => 'Insurance',
        DocumentCategory.property => 'Property',
        DocumentCategory.vehicle => 'Vehicle',
        DocumentCategory.medical => 'Medical',
        DocumentCategory.financial => 'Financial',
        DocumentCategory.education => 'Education',
        DocumentCategory.agreements => 'Agreements',
        DocumentCategory.other => 'Other',
      };
}

class DocumentEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String title;
  final DocumentCategory category;
  final List<String> tags;
  final String? documentNumber;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? localFilePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DocumentEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.title,
    required this.category,
    this.tags = const [],
    this.documentNumber,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.localFilePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
}

