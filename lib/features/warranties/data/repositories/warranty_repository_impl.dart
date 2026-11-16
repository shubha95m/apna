import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/warranty_entity.dart';
import '../../domain/repositories/warranty_repository.dart';
import '../datasources/warranty_remote_datasource.dart';
import '../models/warranty_model.dart';

class WarrantyRepositoryImpl implements WarrantyRepository {
  final WarrantyRemoteDataSource _remoteDataSource;
  final List<WarrantyModel> _localCache = [];

  WarrantyRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<WarrantyEntity>, AppFailure>> getWarranties(String workspaceId) async {
    try {
      final remote = await _remoteDataSource.getWarranties(workspaceId);
      _localCache.clear();
      _localCache.addAll(remote);
      return Success(remote);
    } catch (e) {
      if (_localCache.isNotEmpty) {
        return Success(_localCache.where((w) => w.workspaceId == workspaceId).toList());
      }
      return Failure(DatabaseFailure('Failed to load warranties: $e'));
    }
  }

  @override
  Future<Result<WarrantyEntity, AppFailure>> addWarranty(WarrantyEntity warranty) async {
    try {
      final model = WarrantyModel.fromEntity(warranty);
      final saved = await _remoteDataSource.addWarranty(model);
      _localCache.add(saved);
      return Success(saved);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to add warranty: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteWarranty(String warrantyId) async {
    try {
      await _remoteDataSource.deleteWarranty(warrantyId);
      _localCache.removeWhere((w) => w.id == warrantyId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete warranty: $e'));
    }
  }
}
