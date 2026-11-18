import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/smart_sync/data/services/smart_sync_parser.dart';

void main() {
  group('SmartSyncParser Tests', () {
    test('Correctly parses BESCOM electricity bill with real VPA and consumer number', () {
      const msg = 'Dear Customer, your electricity bill for BESCOM CA 558192 is Rs. 2,140.00 due date 25-Nov-2026. Avoid late fee, pay now.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'VM-BESCOM');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(2140.00));
      expect(parsed.providerOrMerchant, equals('BESCOM'));
      expect(parsed.billCategory, equals(BillCategoryType.electricity));
      expect(parsed.type, equals(SmartTransactionType.upcomingBill));
      expect(parsed.upiVpa, equals('bescom@sbi'));
      expect(parsed.referenceNumber, equals('558192'));
    });

    test('Correctly parses Airtel postpaid telecom bill with official VPA', () {
      const msg = 'Airtel Postpaid: Bill for 9876543210 is Rs. 999.00 due on 28-Nov-2026. View bill details on Airtel Thanks App.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'AD-AIRTEL');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(999.00));
      expect(parsed.providerOrMerchant, equals('Airtel'));
      expect(parsed.billCategory, equals(BillCategoryType.mobile));
      expect(parsed.type, equals(SmartTransactionType.upcomingBill));
      expect(parsed.upiVpa, equals('airtelpaymentsbank@icici'));
    });

    test('Correctly parses HDFC credit card statement with card number and VPA', () {
      const msg = 'HDFC Bank Credit Card ending in 4102 statement generated. Total amount due: Rs. 14,850.00 due date 02-Dec-2026.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'AD-HDFCBK');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(14850.00));
      expect(parsed.providerOrMerchant, equals('HDFC Bank'));
      expect(parsed.accountOrCard, contains('Card ••4102'));
      expect(parsed.type, equals(SmartTransactionType.upcomingBill));
      expect(parsed.upiVpa, equals('hdfcbankcard@hdfcbank'));
    });

    test('Correctly parses Indane LPG gas cylinder bill', () {
      const msg = 'Indane Gas: Booking ref 99281 confirmed. Cylinder refill bill Rs. 903.00 due on 24-Nov-2026.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'BZ-INDANE');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(903.00));
      expect(parsed.providerOrMerchant, equals('Indane Gas'));
      expect(parsed.billCategory, equals(BillCategoryType.gas));
      expect(parsed.upiVpa, equals('indane@icici'));
    });

    test('Correctly parses real UPI debit expense with account and merchant', () {
      const msg = 'Dear SBI User, your A/c ending 8819 debited by Rs 420.00 on 18-Nov-26 at Swiggy Bangalore via UPI Ref 4321098765.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'VM-SBINB');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(420.00));
      expect(parsed.type, equals(SmartTransactionType.debitExpense));
      expect(parsed.category, equals('food'));
      expect(parsed.accountOrCard, contains('A/c ••8819'));
      expect(parsed.referenceNumber, equals('4321098765'));
    });

    test('Correctly parses Samsung TV warranty order', () {
      const msg = 'Amazon.in: Order delivered for Samsung 43" 4K Smart TV. Rs. 32,990.00. 2 Years Manufacturer Warranty active.';
      final parsed = SmartSyncParser.parseMessage(msg, sender: 'BZ-AMAZON');
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(32990.00));
      expect(parsed.type, equals(SmartTransactionType.warrantyPurchase));
      expect(parsed.warrantyMonths, equals(24));
    });

    test('Correctly parses LG appliance warranty', () {
      const msg = 'Order Confirmed: LG Convection Microwave Oven Rs. 11,490.00. 1-Year Comprehensive Warranty included.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SmartTransactionType.warrantyPurchase));
      expect(parsed.warrantyMonths, equals(12));
    });

    test('Generates deterministic deduplication hash for identical transactions', () {
      const msg = 'Dear Customer, your electricity bill for BESCOM CA 558192 is Rs. 2,140.00 due date 25-Nov-2026.';
      final p1 = SmartSyncParser.parseMessage(msg, sender: 'VM-BESCOM');
      final p2 = SmartSyncParser.parseMessage(msg, sender: 'VM-BESCOM');
      expect(p1, isNotNull);
      expect(p2, isNotNull);
      expect(p1!.deduplicationHash, equals(p2!.deduplicationHash));
    });
  });
}
