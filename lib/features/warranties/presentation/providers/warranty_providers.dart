import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import 'package:apna/features/warranties/domain/entities/warranty_entity.dart';
import 'package:apna/features/warranties/domain/repositories/warranty_repository.dart';
import 'package:apna/features/warranties/data/datasources/warranty_remote_datasource.dart';
import 'package:apna/features/warranties/data/repositories/warranty_repository_impl.dart';

final warrantyRemoteDataSourceProvider = Provider<WarrantyRemoteDataSource>((ref) {
  return WarrantyRemoteDataSourceImpl();
});

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  final remote = ref.watch(warrantyRemoteDataSourceProvider);
  return WarrantyRepositoryImpl(remote);
});

class WarrantyListNotifier extends StateNotifier<AsyncValue<List<WarrantyEntity>>> {
  final WarrantyRepository _repository;
  final String _workspaceId;

  WarrantyListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    loadWarranties();
  }

  Future<void> loadWarranties() async {
    state = const AsyncValue.loading();
    final result = await _repository.getWarranties(_workspaceId);
    result.fold(
      (warranties) => state = AsyncValue.data(warranties),
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> addWarranty(WarrantyEntity warranty) async {
    final result = await _repository.addWarranty(warranty);
    result.fold(
      (newWarranty) {
        final current = state.value ?? [];
        state = AsyncValue.data([...current, newWarranty]);
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> deleteWarranty(String warrantyId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((w) => w.id != warrantyId).toList());
    await _repository.deleteWarranty(warrantyId);
  }
}

final warrantyListNotifierProvider =
    StateNotifierProvider<WarrantyListNotifier, AsyncValue<List<WarrantyEntity>>>((ref) {
  final repository = ref.watch(warrantyRepositoryProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return WarrantyListNotifier(repository, workspaceId);
});
