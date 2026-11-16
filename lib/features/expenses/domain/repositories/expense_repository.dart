import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/expense_entity.dart';

abstract interface class ExpenseRepository {
  Future<Result<List<ExpenseEntity>, AppFailure>> getExpenses(String workspaceId);
  Future<Result<ExpenseEntity, AppFailure>> addExpense(ExpenseEntity expense);
  Future<Result<void, AppFailure>> deleteExpense(String expenseId);
}
