import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  final List<ExpenseModel> _localCache = [];

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ExpenseEntity>, AppFailure>> getExpenses(String workspaceId) async {
    try {
      final remote = await _remoteDataSource.getExpenses(workspaceId);
      _localCache.clear();
      _localCache.addAll(remote);
      return Success(remote);
    } catch (e) {
      if (_localCache.isNotEmpty) {
        return Success(_localCache.where((x) => x.workspaceId == workspaceId).toList());
      }
      return Failure(DatabaseFailure('Failed to load expenses: $e'));
    }
  }

  @override
  Future<Result<ExpenseEntity, AppFailure>> addExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final saved = await _remoteDataSource.addExpense(model);
      _localCache.insert(0, saved);
      return Success(saved);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to add expense: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteExpense(String expenseId) async {
    try {
      await _remoteDataSource.deleteExpense(expenseId);
      _localCache.removeWhere((x) => x.id == expenseId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete expense: $e'));
    }
  }
}
