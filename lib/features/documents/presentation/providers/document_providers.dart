import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../data/datasources/document_local_datasource.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../../../workspaces/presentation/providers/workspace_providers.dart';

export '../../../workspaces/presentation/providers/workspace_providers.dart'
    show
        activeWorkspaceIdProvider,
        activeWorkspaceNameProvider,
        activeWorkspaceProvider,
        activeWorkspaceRoleProvider,
        canWriteCurrentWorkspaceProvider,
        canManageCurrentWorkspaceProvider,
        selectedWorkspaceIdProvider,
        userWorkspacesProvider,
        workspaceMembersProvider;

final documentLocalDataSourceProvider = Provider<DocumentLocalDataSource>((ref) {
  return DocumentLocalDataSourceImpl();
});

final documentRemoteDataSourceProvider = Provider<DocumentRemoteDataSource>((ref) {
  return DocumentRemoteDataSourceImpl();
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final localDataSource = ref.watch(documentLocalDataSourceProvider);
  final remoteDataSource = ref.watch(documentRemoteDataSourceProvider);
  return DocumentRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    syncEngine: SyncEngine(),
  );
});

class DocumentListNotifier extends StateNotifier<AsyncValue<List<DocumentEntity>>> {
  final DocumentRepository _repository;
  final String _workspaceId;

  DocumentListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    final result = await _repository.getDocuments(_workspaceId);
    result.fold(
      (docs) => state = AsyncValue.data(docs),
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<bool> addDocument(DocumentEntity document) async {
    final result = await _repository.addDocument(document);
    return result.fold(
      (savedDoc) {
        final currentList = state.value ?? [];
        state = AsyncValue.data([savedDoc, ...currentList.where((d) => d.id != savedDoc.id)]);
        return true;
      },
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<void> deleteDocument(String id) async {
    final result = await _repository.deleteDocument(id);
    result.fold(
      (_) {
        final currentList = state.value ?? [];
        state = AsyncValue.data(currentList.where((d) => d.id != id).toList());
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<String?> uploadFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final result = await _repository.uploadFile(
      workspaceId: _workspaceId,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return result.fold(
      (path) => path,
      (_) => null,
    );
  }

  Future<String?> getDownloadUrl(String storagePath) async {
    final result = await _repository.getDownloadUrl(storagePath);
    return result.fold(
      (url) => url,
      (_) => null,
    );
  }
}

final documentListNotifierProvider =
    StateNotifierProvider<DocumentListNotifier, AsyncValue<List<DocumentEntity>>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return DocumentListNotifier(repository, workspaceId);
});
