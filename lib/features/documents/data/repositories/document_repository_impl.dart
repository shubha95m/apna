import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../datasources/document_remote_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;
  final DocumentRemoteDataSource _remoteDataSource;
  final SyncEngine _syncEngine;

  DocumentRepositoryImpl({
    required DocumentLocalDataSource localDataSource,
    DocumentRemoteDataSource? remoteDataSource,
    required SyncEngine syncEngine,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource ?? DocumentRemoteDataSourceImpl(),
        _syncEngine = syncEngine;

  @override
  Future<Result<List<DocumentEntity>, AppFailure>> getDocuments(String workspaceId) async {
    try {
      // 1. Fetch from live Supabase remote
      final remoteDocs = await _remoteDataSource.getDocuments(workspaceId);
      if (remoteDocs.isNotEmpty) {
        // Cache to local
        for (final doc in remoteDocs) {
          await _localDataSource.saveDocument(doc);
        }
        return Success(remoteDocs);
      }

      // 2. Fallback to local
      final localDocs = await _localDataSource.getDocuments(workspaceId);
      return Success(localDocs);
    } catch (_) {
      // Offline fallback
      try {
        final localDocs = await _localDataSource.getDocuments(workspaceId);
        return Success(localDocs);
      } catch (e) {
        return Failure(DatabaseFailure('Failed to load documents: $e'));
      }
    }
  }

  @override
  Future<Result<DocumentEntity, AppFailure>> getDocumentById(String id) async {
    try {
      final remoteDoc = await _remoteDataSource.getDocumentById(id);
      if (remoteDoc != null) return Success(remoteDoc);

      final localDoc = await _localDataSource.getDocumentById(id);
      if (localDoc != null) return Success(localDoc);

      return const Failure(DatabaseFailure('Document not found.'));
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

      // 2. Push to Supabase remote
      try {
        await _remoteDataSource.addDocument(model);
      } catch (_) {
        // Queue to sync engine if network drops
        await _syncEngine.enqueue(
          entityType: 'documents',
          entityId: model.id,
          operation: OutboxOperation.create,
          payload: model.toMap(),
        );
      }

      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to save document: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteDocument(String id) async {
    try {
      await _localDataSource.deleteDocument(id);
      try {
        await _remoteDataSource.deleteDocument(id);
      } catch (_) {
        await _syncEngine.enqueue(
          entityType: 'documents',
          entityId: id,
          operation: OutboxOperation.delete,
          payload: {'id': id},
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete document: $e'));
    }
  }
}
