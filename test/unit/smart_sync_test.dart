import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/smart_sync/data/services/smart_sync_parser.dart';

void main() {
  group('SmartSyncParser Tests', () {
    test('Correctly parses BESCOM electricity bill', () {
      const msg = 'Dear Customer, your electricity bill for BESCOM CA 558192 is Rs. 2,140.00 due date 25-Nov-2026. Avoid late fee, pay now.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(2140.00));
      expect(parsed.provider, equals('BESCOM'));
      expect(parsed.category, equals(ParsedCategory.electricity));
      expect(parsed.isWarranty, isFalse);
    });

    test('Correctly parses Airtel postpaid telecom bill', () {
      const msg = 'Airtel Postpaid: Bill for 9876543210 is Rs. 999.00 due on 28-Nov-2026. View bill details on Airtel Thanks App.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(999.00));
      expect(parsed.provider, equals('Airtel'));
      expect(parsed.category, equals(ParsedCategory.telecom));
      expect(parsed.isWarranty, isFalse);
    });

    test('Correctly parses HDFC credit card statement', () {
      const msg = 'HDFC Bank Credit Card ending in 4102 statement generated. Total amount due: Rs. 14,850.00 due date 02-Dec-2026.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(14850.00));
      expect(parsed.provider, equals('HDFC Bank'));
      expect(parsed.category, equals(ParsedCategory.creditCard));
    });

    test('Correctly parses Indane LPG gas cylinder bill', () {
      const msg = 'Indane Gas: Booking ref 99281 confirmed. Cylinder refill bill Rs. 903.00 paid successfully.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(903.00));
      expect(parsed.provider, equals('Indane Gas'));
      expect(parsed.category, equals(ParsedCategory.gas));
    });

    test('Correctly parses Samsung TV warranty order', () {
      const msg = 'Amazon.in: Order delivered for Samsung 43" 4K Smart TV. Rs. 32,990.00. 2 Years Manufacturer Warranty active.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(32990.00));
      expect(parsed.isWarranty, isTrue);
      expect(parsed.warrantyMonths, equals(24));
    });

    test('Correctly parses LG appliance warranty', () {
      const msg = 'Order Confirmed: LG Convection Microwave Oven Rs. 11,490.00. 1-Year Comprehensive Warranty included.';
      final parsed = SmartSyncParser.parseMessage(msg);
      expect(parsed, isNotNull);
      expect(parsed!.isWarranty, isTrue);
      expect(parsed.warrantyMonths, equals(12));
    });
  });
}
