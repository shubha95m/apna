import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/document_model.dart';

abstract interface class DocumentLocalDataSource {
  Future<List<DocumentModel>> getDocuments(String workspaceId);
  Future<DocumentModel?> getDocumentById(String id);
  Future<void> saveDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  // In-memory fallback for web and offline environments
  final Map<String, DocumentModel> _memoryStore = {};

  @override
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    final db = await LocalDatabase.instance;
    if (db == null) {
      return _memoryStore.values
          .where((doc) => doc.workspaceId == workspaceId && doc.deletedAt == null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final results = await db.query(
      'local_documents',
      where: 'workspace_id = ? AND deleted_at IS NULL',
      whereArgs: [workspaceId],
      orderBy: 'created_at DESC',
    );
    return results.map(DocumentModel.fromMap).toList();
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    final db = await LocalDatabase.instance;
    if (db == null) {
      final doc = _memoryStore[id];
      if (doc != null && doc.deletedAt == null) return doc;
      return null;
    }

    final results = await db.query(
      'local_documents',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DocumentModel.fromMap(results.first);
  }

  @override
  Future<void> saveDocument(DocumentModel document) async {
    _memoryStore[document.id] = document;
    final db = await LocalDatabase.instance;
    if (db != null) {
      await db.insert(
        'local_documents',
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    final existing = _memoryStore[id];
    if (existing != null) {
      _memoryStore[id] = DocumentModel(
        id: existing.id,
        workspaceId: existing.workspaceId,
        ownerId: existing.ownerId,
        title: existing.title,
        category: existing.category,
        tags: existing.tags,
        documentNumber: existing.documentNumber,
        fileName: existing.fileName,
        fileSizeBytes: existing.fileSizeBytes,
        mimeType: existing.mimeType,
        localFilePath: existing.localFilePath,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
    }

    final db = await LocalDatabase.instance;
    if (db != null) {
      await db.update(
        'local_documents',
        {'deleted_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
