import 'package:intl/intl.dart';

enum ParsedCategory {
  electricity,
  telecom,
  creditCard,
  gas,
  water,
  broadband,
  warranty,
  generalExpense,
}

class ParsedItem {
  final String title;
  final double amount;
  final DateTime dueDate;
  final ParsedCategory category;
  final String provider;
  final String? referenceNumber;
  final String rawText;
  final bool isWarranty;
  final int? warrantyMonths;

  const ParsedItem({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.provider,
    this.referenceNumber,
    required this.rawText,
    this.isWarranty = false,
    this.warrantyMonths,
  });
}

class SmartSyncParser {
  /// Robust regex patterns for Indian utility & financial communication
  static final _amountRegex = RegExp(r'(?:Rs\.?|INR|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
  static final _dueDateRegex = RegExp(r'(?:due(?:\s+on|\s+date)?[:\s]+)([0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}|[0-9]{1,2}\s+[A-Za-z]{3,9}(?:\s+[0-9]{2,4})?)', caseSensitive: false);

  static ParsedItem? parseMessage(String text, {DateTime? fallbackDate}) {
    if (text.trim().isEmpty) return null;

    final now = fallbackDate ?? DateTime.now();

    // 1. Amount Extraction
    double amount = 0.0;
    final amtMatch = _amountRegex.firstMatch(text);
    if (amtMatch != null) {
      final cleanAmt = amtMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(cleanAmt) ?? 0.0;
    }

    // 2. Due Date Extraction
    DateTime dueDate = now.add(const Duration(days: 7));
    final dueMatch = _dueDateRegex.firstMatch(text);
    if (dueMatch != null) {
      final rawDate = dueMatch.group(1)!;
      final parsed = _parseDateString(rawDate);
      if (parsed != null) {
        dueDate = parsed;
      }
    }

    // 3. Category & Provider Detection
    final lower = text.toLowerCase();

    // Warranty detection
    if (lower.contains('warranty') || lower.contains('order delivered') || lower.contains('order confirmed')) {
      int months = 12;
      if (lower.contains('2 year') || lower.contains('24 month')) months = 24;
      if (lower.contains('3 year') || lower.contains('36 month')) months = 36;
      if (lower.contains('5 year')) months = 60;

      String item = 'Consumer Appliance / Electronics';
      if (lower.contains('samsung')) item = 'Samsung Electronics';
      if (lower.contains('apple') || lower.contains('iphone') || lower.contains('macbook')) item = 'Apple Device';
      if (lower.contains('tv')) item = 'Smart TV';
      if (lower.contains('refrigerator') || lower.contains('fridge')) item = 'Refrigerator';
      if (lower.contains('washing machine')) item = 'Washing Machine';
      if (lower.contains('laptop')) item = 'Laptop Computer';

      return ParsedItem(
        title: item,
        amount: amount > 0 ? amount : 15000.0,
        dueDate: now.add(Duration(days: months * 30)),
        category: ParsedCategory.warranty,
        provider: _extractProvider(lower),
        rawText: text,
        isWarranty: true,
        warrantyMonths: months,
      );
    }

    if (lower.contains('electricity') || lower.contains('bescom') || lower.contains('tata power') || lower.contains('adani electricity') || lower.contains('msedcl') || lower.contains('bses') || lower.contains('uppcl')) {
      return ParsedItem(
        title: 'Electricity Bill',
        amount: amount > 0 ? amount : 1850.0,
        dueDate: dueDate,
        category: ParsedCategory.electricity,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    if (lower.contains('airtel') || lower.contains('jio') || lower.contains('vi') || lower.contains('vodafone') || lower.contains('mobile bill') || lower.contains('postpaid')) {
      return ParsedItem(
        title: 'Mobile Postpaid Bill',
        amount: amount > 0 ? amount : 999.0,
        dueDate: dueDate,
        category: ParsedCategory.telecom,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    if (lower.contains('broadband') || lower.contains('act fibernet') || lower.contains('wifi') || lower.contains('fiber')) {
      return ParsedItem(
        title: 'Broadband Internet Bill',
        amount: amount > 0 ? amount : 1299.0,
        dueDate: dueDate,
        category: ParsedCategory.broadband,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    if (lower.contains('credit card') || lower.contains('card ending') || lower.contains('hdfc bank') || lower.contains('sbi card') || lower.contains('icici bank')) {
      return ParsedItem(
        title: 'Credit Card Statement Due',
        amount: amount > 0 ? amount : 12450.0,
        dueDate: dueDate,
        category: ParsedCategory.creditCard,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    if (lower.contains('gas') || lower.contains('igl') || lower.contains('indane') || lower.contains('bharat gas') || lower.contains('hp gas')) {
      return ParsedItem(
        title: 'Piped Gas / LPG Bill',
        amount: amount > 0 ? amount : 940.0,
        dueDate: dueDate,
        category: ParsedCategory.gas,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    if (amount > 0) {
      return ParsedItem(
        title: 'Utility / Service Payment',
        amount: amount,
        dueDate: dueDate,
        category: ParsedCategory.generalExpense,
        provider: _extractProvider(lower),
        rawText: text,
      );
    }

    return null;
  }

  static String _extractProvider(String lower) {
    if (lower.contains('tata power')) return 'Tata Power';
    if (lower.contains('bescom')) return 'BESCOM';
    if (lower.contains('adani')) return 'Adani Electricity';
    if (lower.contains('bses')) return 'BSES';
    if (lower.contains('airtel')) return 'Airtel';
    if (lower.contains('jio')) return 'Reliance Jio';
    if (lower.contains('act fibernet')) return 'ACT Fibernet';
    if (lower.contains('tata play')) return 'Tata Play';
    if (lower.contains('hdfc')) return 'HDFC Bank';
    if (lower.contains('sbi')) return 'SBI';
    if (lower.contains('icici')) return 'ICICI Bank';
    if (lower.contains('indane')) return 'Indane Gas';
    if (lower.contains('bharat gas')) return 'Bharat Gas';
    if (lower.contains('hp gas')) return 'HP Gas';
    if (lower.contains('water board')) return 'Municipal Water Board';
    if (lower.contains('samsung')) return 'Samsung';
    if (lower.contains('lg')) return 'LG Electronics';
    if (lower.contains('amazon')) return 'Amazon India';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    return 'Utility Provider';
  }

  static DateTime? _parseDateString(String raw) {
    try {
      final formats = [
        'dd-MM-yyyy',
        'dd/MM/yyyy',
        'dd-MM-yy',
        'dd/MM/yy',
        'dd MMM yyyy',
        'dd MMMM yyyy',
        'dd MMM',
      ];
      final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      for (final f in formats) {
        try {
          return DateFormat(f).parseLoose(cleaned);
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }
}
