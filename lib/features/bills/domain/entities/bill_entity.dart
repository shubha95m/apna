class BillEntity {
  final String id;
  final String workspaceId;
  final String title;
  final String category; // 'electricity', 'water', 'internet', 'mobile', 'gas', 'rent', 'dth', 'other'
  final String providerName;
  final String? consumerNumber;
  final double amount;
  final DateTime dueDate;
  final String? billingPeriod;
  final String paymentStatus; // 'unpaid', 'paid', 'overdue'
  final String? upiVpa;
  final DateTime? paidAt;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillEntity({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.category,
    required this.providerName,
    this.consumerNumber,
    required this.amount,
    required this.dueDate,
    this.billingPeriod,
    this.paymentStatus = 'unpaid',
    this.upiVpa,
    this.paidAt,
    this.paymentReference,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isOverdue => paymentStatus == 'overdue' || (!isPaid && dueDate.isBefore(DateTime.now()));

  BillEntity copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? category,
    String? providerName,
    String? consumerNumber,
    double? amount,
    DateTime? dueDate,
    String? billingPeriod,
    String? paymentStatus,
    String? upiVpa,
    DateTime? paidAt,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillEntity(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      category: category ?? this.category,
      providerName: providerName ?? this.providerName,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      upiVpa: upiVpa ?? this.upiVpa,
      paidAt: paidAt ?? this.paidAt,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
