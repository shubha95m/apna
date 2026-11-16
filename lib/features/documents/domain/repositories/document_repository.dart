import '../../../../core/result/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

abstract interface class DocumentRepository {
  Future<Result<List<DocumentEntity>, AppFailure>> getDocuments(String workspaceId);
  Future<Result<DocumentEntity, AppFailure>> getDocumentById(String id);
  Future<Result<DocumentEntity, AppFailure>> addDocument(DocumentEntity document);
  Future<Result<void, AppFailure>> deleteDocument(String id);
}

