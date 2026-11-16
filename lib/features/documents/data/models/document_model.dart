import '../../domain/entities/document_entity.dart';

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.id,
    required super.workspaceId,
    required super.ownerId,
    required super.title,
    required super.category,
    super.tags = const [],
    super.documentNumber,
    super.fileName,
    super.fileSizeBytes,
    super.mimeType,
    super.localFilePath,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      category: DocumentCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == (map['category'] as String).toLowerCase(),
        orElse: () => DocumentCategory.other,
      ),
      tags: (map['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      documentNumber: map['document_number'] as String?,
      fileName: map['file_name'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
      mimeType: map['mime_type'] as String?,
      localFilePath: map['local_file_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'owner_id': ownerId,
      'title': title,
      'category': category.name,
      'tags': tags.join(','),
      'document_number': documentNumber,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'local_file_path': localFilePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      workspaceId: entity.workspaceId,
      ownerId: entity.ownerId,
      title: entity.title,
      category: entity.category,
      tags: entity.tags,
      documentNumber: entity.documentNumber,
      fileName: entity.fileName,
      fileSizeBytes: entity.fileSizeBytes,
      mimeType: entity.mimeType,
      localFilePath: entity.localFilePath,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}

