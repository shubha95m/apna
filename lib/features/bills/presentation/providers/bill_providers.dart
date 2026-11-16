import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import 'package:apna/features/bills/domain/entities/bill_entity.dart';
import 'package:apna/features/bills/domain/repositories/bill_repository.dart';
import 'package:apna/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:apna/features/bills/data/repositories/bill_repository_impl.dart';

final billRemoteDataSourceProvider = Provider<BillRemoteDataSource>((ref) {
  return BillRemoteDataSourceImpl();
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final remoteDataSource = ref.watch(billRemoteDataSourceProvider);
  return BillRepositoryImpl(remoteDataSource);
});

class BillListNotifier extends StateNotifier<AsyncValue<List<BillEntity>>> {
  final BillRepository _repository;
  final String _workspaceId;

  BillListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    loadBills();
  }

  Future<void> loadBills() async {
    state = const AsyncValue.loading();
    final result = await _repository.getBills(_workspaceId);
    result.fold(
      (bills) => state = AsyncValue.data(bills),
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> addBill(BillEntity bill) async {
    final result = await _repository.addBill(bill);
    result.fold(
      (newBill) {
        final current = state.value ?? [];
        state = AsyncValue.data([...current, newBill]);
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> markAsPaid(String billId, {String? reference}) async {
    final result = await _repository.markBillAsPaid(billId, reference: reference);
    result.fold(
      (updatedBill) {
        final current = state.value ?? [];
        state = AsyncValue.data(current.map((b) => b.id == billId ? updatedBill : b).toList());
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> deleteBill(String billId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((b) => b.id != billId).toList());
    await _repository.deleteBill(billId);
  }
}

final billListNotifierProvider =
    StateNotifierProvider<BillListNotifier, AsyncValue<List<BillEntity>>>((ref) {
  final repository = ref.watch(billRepositoryProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return BillListNotifier(repository, workspaceId);
});
