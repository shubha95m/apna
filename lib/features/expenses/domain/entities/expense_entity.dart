class ExpenseEntity {
  final String id;
  final String workspaceId;
  final String paidById;
  final String title;
  final double amount;
  final String category; // 'groceries', 'utilities', 'dining', 'shopping', 'travel', 'health', 'other'
  final String paymentMode; // 'upi', 'cash', 'card', 'net_banking'
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.workspaceId,
    required this.paidById,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMode,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
  });
}
