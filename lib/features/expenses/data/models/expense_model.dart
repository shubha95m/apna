import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.workspaceId,
    required super.paidById,
    required super.title,
    required super.amount,
    required super.category,
    required super.paymentMode,
    required super.expenseDate,
    super.notes,
    required super.createdAt,
  });

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      workspaceId: entity.workspaceId,
      paidById: entity.paidById,
      title: entity.title,
      amount: entity.amount,
      category: entity.category,
      paymentMode: entity.paymentMode,
      expenseDate: entity.expenseDate,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      paidById: map['paid_by_id'] as String? ?? 'usr-shubham-001',
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String? ?? 'other',
      paymentMode: map['payment_mode'] as String? ?? 'upi',
      expenseDate: DateTime.parse(map['expense_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'paid_by_id': paidById,
      'title': title,
      'amount': amount,
      'category': category,
      'payment_mode': paymentMode.toLowerCase(),
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
