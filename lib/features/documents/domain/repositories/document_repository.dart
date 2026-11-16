import 'dart:typed_data';
import '../../../../core/result/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

abstract interface class DocumentRepository {
  Future<Result<List<DocumentEntity>, AppFailure>> getDocuments(String workspaceId);
  Future<Result<DocumentEntity, AppFailure>> getDocumentById(String id);
  Future<Result<DocumentEntity, AppFailure>> addDocument(DocumentEntity document);
  Future<Result<void, AppFailure>> deleteDocument(String id);
  Future<Result<String, AppFailure>> uploadFile({
    required String workspaceId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
  Future<Result<String, AppFailure>> getDownloadUrl(String storagePath);
}
