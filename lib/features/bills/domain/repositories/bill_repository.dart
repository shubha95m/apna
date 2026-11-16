import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/bill_entity.dart';

abstract interface class BillRepository {
  Future<Result<List<BillEntity>, AppFailure>> getBills(String workspaceId);
  Future<Result<BillEntity, AppFailure>> addBill(BillEntity bill);
  Future<Result<BillEntity, AppFailure>> markBillAsPaid(String billId, {String? reference});
  Future<Result<void, AppFailure>> deleteBill(String billId);
}
