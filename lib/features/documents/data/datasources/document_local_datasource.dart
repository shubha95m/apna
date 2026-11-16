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
  @override
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    final db = await LocalDatabase.instance;
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
    final db = await LocalDatabase.instance;
    await db.insert(
      'local_documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteDocument(String id) async {
    final db = await LocalDatabase.instance;
    await db.update(
      'local_documents',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
