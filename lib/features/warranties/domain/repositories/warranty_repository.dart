import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/warranty_entity.dart';

abstract interface class WarrantyRepository {
  Future<Result<List<WarrantyEntity>, AppFailure>> getWarranties(String workspaceId);
  Future<Result<WarrantyEntity, AppFailure>> addWarranty(WarrantyEntity warranty);
  Future<Result<void, AppFailure>> deleteWarranty(String warrantyId);
}
