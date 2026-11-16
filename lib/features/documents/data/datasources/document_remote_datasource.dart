import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../../domain/entities/document_entity.dart';
import '../models/document_model.dart';

abstract interface class DocumentRemoteDataSource {
  Future<List<DocumentModel>> getDocuments(String workspaceId);
  Future<DocumentModel?> getDocumentById(String id);
  Future<DocumentModel> addDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final response = await _client
        .from('documents')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final catStr = map['category'] as String? ?? 'other';
      final category = DocumentCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == catStr.toLowerCase(),
        orElse: () => DocumentCategory.other,
      );
      final tagsList = (map['tags'] is List)
          ? (map['tags'] as List).map((e) => e.toString()).toList()
          : <String>[];

      return DocumentModel(
        id: map['id'] as String,
        workspaceId: map['workspace_id'] as String,
        ownerId: map['owner_id'] as String,
        title: map['title'] as String,
        category: category,
        tags: tagsList,
        documentNumber: map['document_number'] as String?,
        fileName: map['file_name'] as String?,
        fileSizeBytes: map['file_size_bytes'] as int?,
        mimeType: map['mime_type'] as String?,
        localFilePath: map['local_file_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
    }).toList();
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    if (!SupabaseConfig.isConfigured) return null;

    final response = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (response == null) return null;
    final map = Map<String, dynamic>.from(response);
    final catStr = map['category'] as String? ?? 'other';
    final category = DocumentCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == catStr.toLowerCase(),
      orElse: () => DocumentCategory.other,
    );
    final tagsList = (map['tags'] is List)
        ? (map['tags'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return DocumentModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      category: category,
      tags: tagsList,
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

  @override
  Future<DocumentModel> addDocument(DocumentModel document) async {
    if (!SupabaseConfig.isConfigured) return document;

    final ownerId = _client.auth.currentUser?.id ?? document.ownerId;
    final payload = {
      'id': document.id,
      'workspace_id': document.workspaceId,
      'owner_id': ownerId,
      'title': document.title,
      'category': document.category.name.toLowerCase(),
      'tags': document.tags,
      'document_number': document.documentNumber,
      'created_at': document.createdAt.toIso8601String(),
      'updated_at': document.updatedAt.toIso8601String(),
    };

    await _client.from('documents').insert(payload);
    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('documents')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
