import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;
  final SyncEngine _syncEngine;

  DocumentRepositoryImpl({
    required DocumentLocalDataSource localDataSource,
    required SyncEngine syncEngine,
  })  : _localDataSource = localDataSource,
        _syncEngine = syncEngine;

  @override
  Future<Result<List<DocumentEntity>, AppFailure>> getDocuments(String workspaceId) async {
    try {
      final documents = await _localDataSource.getDocuments(workspaceId);
      return Success(documents);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load documents: $e'));
    }
  }

  @override
  Future<Result<DocumentEntity, AppFailure>> getDocumentById(String id) async {
    try {
      final doc = await _localDataSource.getDocumentById(id);
      if (doc == null) {
        return const Failure(DatabaseFailure('Document not found.'));
      }
      return Success(doc);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to find document: $e'));
    }
  }

  @override
  Future<Result<DocumentEntity, AppFailure>> addDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      // 1. Save locally
      await _localDataSource.saveDocument(model);

      // 2. Queue into local transactional outbox
      await _syncEngine.enqueue(
        entityType: 'documents',
        entityId: model.id,
        operation: OutboxOperation.create,
        payload: model.toMap(),
      );

      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to save document: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteDocument(String id) async {
    try {
      await _localDataSource.deleteDocument(id);
      await _syncEngine.enqueue(
        entityType: 'documents',
        entityId: id,
        operation: OutboxOperation.delete,
        payload: {'id': id},
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete document: $e'));
    }
  }
}
