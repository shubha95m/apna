import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import 'package:apna/features/expenses/domain/entities/expense_entity.dart';
import 'package:apna/features/expenses/domain/repositories/expense_repository.dart';
import 'package:apna/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:apna/features/expenses/data/repositories/expense_repository_impl.dart';

final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((ref) {
  return ExpenseRemoteDataSourceImpl();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final remote = ref.watch(expenseRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(remote);
});

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<ExpenseEntity>>> {
  final ExpenseRepository _repository;
  final String _workspaceId;

  ExpenseListNotifier(this._repository, this._workspaceId)
      : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    final result = await _repository.getExpenses(_workspaceId);
    result.fold(
      (expenses) => state = AsyncValue.data(expenses),
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    final result = await _repository.addExpense(expense);
    result.fold(
      (newExpense) {
        final current = state.value ?? [];
        state = AsyncValue.data([newExpense, ...current]);
      },
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != expenseId).toList());
    await _repository.deleteExpense(expenseId);
  }
}

final expenseListNotifierProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<ExpenseEntity>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return ExpenseListNotifier(repository, workspaceId);
});
