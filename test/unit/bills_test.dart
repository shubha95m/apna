import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/bills/data/models/bill_model.dart';

void main() {
  group('BillEntity & BillModel', () {
    test('BillModel correctly identifies overdue and paid statuses', () {
      final now = DateTime.now();
      final unpaidBill = BillModel(
        id: 'b-001',
        workspaceId: 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a02',
        title: 'BSES Electricity Bill',
        category: 'electricity',
        providerName: 'BSES Rajdhani',
        amount: 3240.0,
        dueDate: now.add(const Duration(days: 3)),
        paymentStatus: 'unpaid',
        upiVpa: 'bsesrajdhani@icici',
        createdAt: now,
        updatedAt: now,
      );

      expect(unpaidBill.isPaid, isFalse);
      expect(unpaidBill.isOverdue, isFalse);

      final paidBill = unpaidBill.copyWith(
        paymentStatus: 'paid',
        paidAt: DateTime.now(),
      );
      expect(paidBill.isPaid, isTrue);

      final overdueBill = unpaidBill.copyWith(
        dueDate: now.subtract(const Duration(days: 2)),
      );
      expect(overdueBill.isOverdue, isTrue);
    });
  });
}
