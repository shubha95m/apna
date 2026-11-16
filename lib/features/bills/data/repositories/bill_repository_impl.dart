import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource _remoteDataSource;
  final List<BillModel> _localCache = [];

  BillRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<BillEntity>, AppFailure>> getBills(String workspaceId) async {
    try {
      final remoteBills = await _remoteDataSource.getBills(workspaceId);
      _localCache.clear();
      _localCache.addAll(remoteBills);
      return Success(remoteBills);
    } catch (e) {
      if (_localCache.isNotEmpty) {
        return Success(_localCache.where((b) => b.workspaceId == workspaceId).toList());
      }
      return Failure(DatabaseFailure('Failed to load bills: $e'));
    }
  }

  @override
  Future<Result<BillEntity, AppFailure>> addBill(BillEntity bill) async {
    try {
      final model = BillModel.fromEntity(bill);
      final saved = await _remoteDataSource.addBill(model);
      _localCache.add(saved);
      return Success(saved);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to add bill: $e'));
    }
  }

  @override
  Future<Result<BillEntity, AppFailure>> markBillAsPaid(String billId, {String? reference}) async {
    try {
      final updated = await _remoteDataSource.markBillAsPaid(billId, reference: reference);
      final index = _localCache.indexWhere((b) => b.id == billId);
      if (index != -1) _localCache[index] = updated;
      return Success(updated);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to mark bill as paid: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteBill(String billId) async {
    try {
      await _remoteDataSource.deleteBill(billId);
      _localCache.removeWhere((b) => b.id == billId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete bill: $e'));
    }
  }
}
