import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../models/expense_model.dart';

abstract interface class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses(String workspaceId);
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<ExpenseModel>> getExpenses(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final response = await _client
        .from('expenses')
        .select()
        .eq('workspace_id', workspaceId)
        .order('expense_date', ascending: false);

    return (response as List)
        .map((row) => ExpenseModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    if (!SupabaseConfig.isConfigured) return expense;

    final paidById = _client.auth.currentUser?.id ?? expense.paidById;
    final payload = {
      'id': expense.id,
      'workspace_id': expense.workspaceId,
      'paid_by_id': paidById,
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'payment_mode': expense.paymentMode.toLowerCase(),
      'expense_date': expense.expenseDate.toIso8601String().split('T').first,
      'notes': expense.notes,
      'created_at': expense.createdAt.toIso8601String(),
    };

    await _client.from('expenses').insert(payload);
    return expense;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client.from('expenses').delete().eq('id', expenseId);
  }
}
