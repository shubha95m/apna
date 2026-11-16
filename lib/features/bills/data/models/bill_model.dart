import '../../domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.category,
    required super.providerName,
    super.consumerNumber,
    required super.amount,
    required super.dueDate,
    super.billingPeriod,
    super.paymentStatus = 'unpaid',
    super.upiVpa,
    super.paidAt,
    super.paymentReference,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BillModel.fromEntity(BillEntity entity) {
    return BillModel(
      id: entity.id,
      workspaceId: entity.workspaceId,
      title: entity.title,
      category: entity.category,
      providerName: entity.providerName,
      consumerNumber: entity.consumerNumber,
      amount: entity.amount,
      dueDate: entity.dueDate,
      billingPeriod: entity.billingPeriod,
      paymentStatus: entity.paymentStatus,
      upiVpa: entity.upiVpa,
      paidAt: entity.paidAt,
      paymentReference: entity.paymentReference,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as String,
      workspaceId: map['workspace_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'other',
      providerName: map['provider_name'] as String? ?? 'Service Provider',
      consumerNumber: map['consumer_number'] as String?,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      billingPeriod: map['billing_period'] as String?,
      paymentStatus: map['payment_status'] as String? ?? 'unpaid',
      upiVpa: map['upi_vpa'] as String?,
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at'] as String) : null,
      paymentReference: map['payment_reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'title': title,
      'category': category.toLowerCase(),
      'provider_name': providerName,
      'consumer_number': consumerNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'billing_period': billingPeriod,
      'payment_status': paymentStatus.toLowerCase(),
      'upi_vpa': upiVpa,
      'paid_at': paidAt?.toIso8601String(),
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
