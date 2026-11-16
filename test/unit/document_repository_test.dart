import 'package:flutter_test/flutter_test.dart';
import 'package:apna/core/sync/sync_engine.dart';
import 'package:apna/features/documents/data/datasources/document_local_datasource.dart';
import 'package:apna/features/documents/data/models/document_model.dart';
import 'package:apna/features/documents/data/repositories/document_repository_impl.dart';
import 'package:apna/features/documents/domain/entities/document_entity.dart';

class MockDocumentLocalDataSource implements DocumentLocalDataSource {
  final Map<String, DocumentModel> store = {};

  @override
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    return store.values.where((d) => d.workspaceId == workspaceId && d.deletedAt == null).toList();
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    return store[id];
  }

  @override
  Future<void> saveDocument(DocumentModel document) async {
    store[document.id] = document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (store.containsKey(id)) {
      final existing = store[id]!;
      store[id] = DocumentModel(
        id: existing.id,
        workspaceId: existing.workspaceId,
        ownerId: existing.ownerId,
        title: existing.title,
        category: existing.category,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
    }
  }
}

class MockSyncEngine implements SyncEngine {
  final List<Map<String, dynamic>> enqueued = [];

  @override
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required OutboxOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    enqueued.add({
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'payload': payload,
    });
  }

  @override
  Future<int> processPendingQueue() async {
    return enqueued.length;
  }
}

void main() {
  late MockDocumentLocalDataSource mockLocal;
  late MockSyncEngine mockSync;
  late DocumentRepositoryImpl repository;

  setUp(() {
    mockLocal = MockDocumentLocalDataSource();
    mockSync = MockSyncEngine();
    repository = DocumentRepositoryImpl(
      localDataSource: mockLocal,
      syncEngine: mockSync,
    );
  });

  test('DocumentRepository saves document locally and enqueues to sync outbox', () async {
    final doc = DocumentEntity(
      id: 'doc-123',
      workspaceId: 'workspace-family-001',
      ownerId: 'user-shubham',
      title: 'Aadhaar Card.pdf',
      category: DocumentCategory.kyc,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await repository.addDocument(doc);

    expect(result.isSuccess, isTrue);
    expect(mockLocal.store.containsKey('doc-123'), isTrue);
    expect(mockSync.enqueued.length, equals(1));
    expect(mockSync.enqueued.first['entityType'], equals('documents'));
    expect(mockSync.enqueued.first['entityId'], equals('doc-123'));
    expect(mockSync.enqueued.first['operation'], equals(OutboxOperation.create));
  });

  test('DocumentRepository queries documents filtered by workspace', () async {
    final doc1 = DocumentModel(
      id: 'doc-1',
      workspaceId: 'ws-family',
      ownerId: 'user-1',
      title: 'Doc 1',
      category: DocumentCategory.insurance,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final doc2 = DocumentModel(
      id: 'doc-2',
      workspaceId: 'ws-personal',
      ownerId: 'user-1',
      title: 'Doc 2',
      category: DocumentCategory.financial,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await mockLocal.saveDocument(doc1);
    await mockLocal.saveDocument(doc2);

    final familyDocs = await repository.getDocuments('ws-family');
    expect(familyDocs.dataOrNull?.length, equals(1));
    expect(familyDocs.dataOrNull?.first.id, equals('doc-1'));
  });
}
