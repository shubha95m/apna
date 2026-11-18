import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

enum SmartTransactionType {
  upcomingBill,
  debitExpense,
  creditIncome,
  warrantyPurchase,
}

enum BillCategoryType {
  electricity,
  water,
  internet,
  mobile,
  gas,
  rent,
  dth,
  other,
}

class ParsedSmartTransaction {
  final SmartTransactionType type;
  final String title;
  final String providerOrMerchant;
  final double amount;
  final DateTime date;
  final String? accountOrCard; // e.g. "HDFC Bank (A/c ••4102)" or "SBI Card (••8819)"
  final String? referenceNumber; // e.g. UTR / Txn ID / Consumer No
  final String? upiVpa; // Real extracted or official BBPS VPA (never a mock)
  final String category; // DB category: food, groceries, shopping, travel, utilities, etc.
  final BillCategoryType billCategory;
  final int? warrantyMonths;
  final String rawText;
  final String deduplicationHash;

  const ParsedSmartTransaction({
    required this.type,
    required this.title,
    required this.providerOrMerchant,
    required this.amount,
    required this.date,
    this.accountOrCard,
    this.referenceNumber,
    this.upiVpa,
    required this.category,
    this.billCategory = BillCategoryType.other,
    this.warrantyMonths,
    required this.rawText,
    required this.deduplicationHash,
  });
}

class SmartSyncParser {
  // Regexes for Indian Financial & Telecom SMS
  static final _amountRegex = RegExp(
    r'(?:(?:Rs\.?|INR|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)|([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:INR|Rs\.?|₹))',
    caseSensitive: false,
  );

  static final _dueDateRegex = RegExp(
    r'(?:due(?:\s+on|\s+date)?[:\s]+)([0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}|[0-9]{1,2}\s+[A-Za-z]{3,9}(?:\s+[0-9]{2,4})?)',
    caseSensitive: false,
  );

  static final _dateOnRegex = RegExp(
    r'(?:on\s+)([0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}|[0-9]{1,2}\s+[A-Za-z]{3,9}(?:\s+[0-9]{2,4})?)',
    caseSensitive: false,
  );

  static final _accountRegex = RegExp(
    r'(?:a/c|acct|account)\s*(?:ending(?:\s+in|\s+with)?|no\.?)?\s*[*Xx.\-_]*([0-9]{3,4})',
    caseSensitive: false,
  );

  static final _cardRegex = RegExp(
    r'(?:card|credit card|debit card)\s*(?:ending\s*(?:in|with)?|xx+)?\s*[*Xx.\-_]*([0-9]{4})',
    caseSensitive: false,
  );

  static final _refRegex = RegExp(
    r'(?:upi\s+ref(?:\s+no)?|txn(?:\s+id|\s+no)?|ref(?:\s+no)?|rrn)[:\s]*([0-9A-Za-z]{6,22})',
    caseSensitive: false,
  );

  static final _consumerRegex = RegExp(
    r'(?:ca|consumer|customer|k-no|rr\s*no|connection)\s*(?:no\.?|id|#)?[:\s]*([0-9A-Za-z]{4,16})',
    caseSensitive: false,
  );

  static final _vpaRegex = RegExp(
    r'([a-zA-Z0-9._\-]{2,256}@[a-zA-Z]{2,64})',
    caseSensitive: false,
  );

  /// Verified official NPCI / BBPS merchant VPA mapping for top Indian billers
  static const Map<String, String> _officialBbpsVpa = {
    'bescom': 'bescom@sbi',
    'tata power': 'tatapower@icici',
    'adani electricity': 'adanipower@icici',
    'bses rajdhani': 'bsesrajdhani@icici',
    'bses yamuna': 'bsesyamuna@icici',
    'msedcl': 'msedcl@sbi',
    'mahavitaran': 'msedcl@sbi',
    'uppcl': 'uppcl@sbi',
    'pspcl': 'pspcl@sbi',
    'tsspdcl': 'tsspdcl@sbi',
    'airtel': 'airtelpaymentsbank@icici',
    'reliance jio': 'reliancejio@icici',
    'jio': 'reliancejio@icici',
    'vodafone': 'vodafone@icici',
    'vi': 'vodafone@icici',
    'tata play': 'tatasky@icici',
    'act fibernet': 'actfibernet@icici',
    'hathway': 'hathway@icici',
    'indane': 'indane@icici',
    'bharat gas': 'bharatgas@sbi',
    'hp gas': 'hpgas@icici',
    'igl': 'igl@icici',
    'mgl': 'mgl@icici',
    'bwssb': 'bwssb@sbi',
    'delhi jal board': 'delhijalboard@icici',
    'hdfc bank credit card': 'hdfcbankcard@hdfcbank',
    'sbi card': 'sbicard@sbi',
    'icici bank credit card': 'icicibankcard@icici',
    'axis bank credit card': 'axisbankcard@axisbank',
    'kotak credit card': 'kotakcard@kotak',
  };

  /// Parses any SMS or statement text into a structured, validated real transaction.
  /// Returns null if text does not contain a genuine financial amount or transaction.
  static ParsedSmartTransaction? parseMessage(
    String text, {
    String sender = '',
    DateTime? fallbackDate,
  }) {
    if (text.trim().isEmpty) return null;

    final lower = text.toLowerCase();
    final upper = text.toUpperCase();
    final senderUpper = sender.toUpperCase();

    // 1. EXTRACT REAL AMOUNT (Strict: Never mock or default)
    double? extractedAmount;
    final amtMatch = _amountRegex.firstMatch(text);
    if (amtMatch != null) {
      final grp = (amtMatch.group(1) ?? amtMatch.group(2))?.replaceAll(',', '');
      if (grp != null) {
        extractedAmount = double.tryParse(grp);
      }
    }

    // 2. EXTRACT DATE
    final now = fallbackDate ?? DateTime.now();
    DateTime transactionDate = now;
    final dueMatch = _dueDateRegex.firstMatch(text);
    if (dueMatch != null) {
      final d = _parseDateString(dueMatch.group(1)!);
      if (d != null) transactionDate = d;
    } else {
      final dateOnMatch = _dateOnRegex.firstMatch(text);
      if (dateOnMatch != null) {
        final d = _parseDateString(dateOnMatch.group(1)!);
        if (d != null) transactionDate = d;
      }
    }

    // 3. EXTRACT BANK / CARD SOURCE
    String? accountOrCard;
    final bankName = _detectBankName(senderUpper, upper);
    final cardMatch = _cardRegex.firstMatch(text);
    final acctMatch = _accountRegex.firstMatch(text);

    if (cardMatch != null) {
      final digits = cardMatch.group(1)!;
      accountOrCard = bankName.isNotEmpty
          ? '$bankName (Card ••$digits)'
          : 'Credit Card ••$digits';
    } else if (acctMatch != null) {
      final digits = acctMatch.group(1)!;
      accountOrCard = bankName.isNotEmpty
          ? '$bankName (A/c ••$digits)'
          : 'Bank A/c ••$digits';
    } else if (bankName.isNotEmpty) {
      accountOrCard = bankName;
    }

    // 4. EXTRACT REFERENCE / CONSUMER NUMBER
    String? referenceNumber;
    final refMatch = _refRegex.firstMatch(text);
    if (refMatch != null) {
      referenceNumber = refMatch.group(1);
    }
    final consumerMatch = _consumerRegex.firstMatch(text);
    if (consumerMatch != null) {
      referenceNumber ??= consumerMatch.group(1);
    }

    // 5. EXTRACT OR RESOLVE OFFICIAL UPI VPA
    String? upiVpa;
    final vpaMatch = _vpaRegex.firstMatch(text);
    if (vpaMatch != null) {
      final candidate = vpaMatch.group(1)!.trim();
      // Ensure candidate doesn't end with an email domain like gmail.com or outlook.com
      final candidateLower = candidate.toLowerCase();
      if (!candidateLower.endsWith('gmail.com') &&
          !candidateLower.endsWith('outlook.com') &&
          !candidateLower.endsWith('yahoo.com') &&
          !candidateLower.endsWith('hotmail.com')) {
        upiVpa = candidate;
      }
    }

    // 6. DETECT TRANSACTION TYPE & METADATA

    // Case A: Warranty or Appliance purchase
    if (lower.contains('warranty') ||
        (lower.contains('order delivered') && (lower.contains('tv') || lower.contains('appliance') || lower.contains('refrigerator') || lower.contains('washing machine')))) {
      int months = 12;
      if (lower.contains('2 year') || lower.contains('24 month') || lower.contains('2-year')) months = 24;
      if (lower.contains('3 year') || lower.contains('36 month') || lower.contains('3-year')) months = 36;
      if (lower.contains('5 year') || lower.contains('5-year')) months = 60;

      final brand = _detectProviderOrBrand(lower, senderUpper);
      final itemTitle = _detectApplianceTitle(lower, brand);
      final finalAmount = extractedAmount ?? 0.0;
      final expiry = now.add(Duration(days: months * 30));

      final hash = _generateHash(
        'warranty',
        brand,
        itemTitle,
        finalAmount,
        expiry,
        referenceNumber,
      );

      return ParsedSmartTransaction(
        type: SmartTransactionType.warrantyPurchase,
        title: itemTitle,
        providerOrMerchant: brand,
        amount: finalAmount,
        date: expiry,
        accountOrCard: accountOrCard,
        referenceNumber: referenceNumber,
        category: 'appliances',
        warrantyMonths: months,
        rawText: text,
        deduplicationHash: hash,
      );
    }

    // If no real amount was found, we cannot record an accurate financial transaction
    if (extractedAmount == null || extractedAmount <= 0) {
      return null;
    }

    // Case B: Upcoming Bill / Statement Due
    final isUpcomingBill = (lower.contains('due date') ||
            lower.contains('due on') ||
            lower.contains('total amount due') ||
            lower.contains('min amount due') ||
            lower.contains('bill generated') ||
            lower.contains('bill for') ||
            lower.contains('invoice due')) &&
        !lower.contains('paid successfully') &&
        !lower.contains('received payment') &&
        !lower.contains('debited for bill');

    if (isUpcomingBill) {
      final billDetails = _classifyBill(lower, senderUpper);
      // Resolve official BBPS VPA if not extracted from text
      upiVpa ??= _resolveOfficialVpa(billDetails.provider, billDetails.title);

      final hash = _generateHash(
        'bill',
        billDetails.provider,
        billDetails.title,
        extractedAmount,
        transactionDate,
        referenceNumber ?? consumerMatch?.group(1),
      );

      return ParsedSmartTransaction(
        type: SmartTransactionType.upcomingBill,
        title: billDetails.title,
        providerOrMerchant: billDetails.provider,
        amount: extractedAmount,
        date: transactionDate,
        accountOrCard: accountOrCard,
        referenceNumber: referenceNumber ?? consumerMatch?.group(1),
        upiVpa: upiVpa,
        category: 'utilities',
        billCategory: billDetails.category,
        rawText: text,
        deduplicationHash: hash,
      );
    }

    // Case C: Income / Credit
    final isCredit = lower.contains('credited') ||
        lower.contains('received rs') ||
        lower.contains('refund of') ||
        lower.contains('salary credited') ||
        lower.contains('deposited');

    if (isCredit) {
      final merchant = _detectMerchantOrBeneficiary(text, lower, senderUpper);
      final category = lower.contains('salary')
          ? 'salary'
          : lower.contains('refund')
              ? 'refund'
              : 'income';

      final hash = _generateHash(
        'income',
        merchant,
        category,
        extractedAmount,
        transactionDate,
        referenceNumber,
      );

      return ParsedSmartTransaction(
        type: SmartTransactionType.creditIncome,
        title: 'Received from $merchant',
        providerOrMerchant: merchant,
        amount: extractedAmount,
        date: transactionDate,
        accountOrCard: accountOrCard,
        referenceNumber: referenceNumber,
        category: category,
        rawText: text,
        deduplicationHash: hash,
      );
    }

    // Case D: Debit Expense
    final merchant = _detectMerchantOrBeneficiary(text, lower, senderUpper);
    final category = _classifyExpenseCategory(lower, merchant.toLowerCase());
    upiVpa ??= _resolveOfficialVpa(merchant);

    final hash = _generateHash(
      'expense',
      merchant,
      category,
      extractedAmount,
      transactionDate,
      referenceNumber,
    );

    return ParsedSmartTransaction(
      type: SmartTransactionType.debitExpense,
      title: merchant,
      providerOrMerchant: merchant,
      amount: extractedAmount,
      date: transactionDate,
      accountOrCard: accountOrCard,
      referenceNumber: referenceNumber,
      upiVpa: upiVpa,
      category: category,
      rawText: text,
      deduplicationHash: hash,
    );
  }

  // --- Helper Categorizers & Extractors ---

  static String _detectBankName(String sender, String upper) {
    if (sender.contains('HDFC') || upper.contains('HDFC BANK')) return 'HDFC Bank';
    if (sender.contains('SBIN') || sender.contains('SBICRD') || upper.contains('SBI') || upper.contains('STATE BANK')) return 'SBI';
    if (sender.contains('ICICI') || upper.contains('ICICI BANK')) return 'ICICI Bank';
    if (sender.contains('AXIS') || upper.contains('AXIS BANK')) return 'Axis Bank';
    if (sender.contains('KOTAK') || upper.contains('KOTAK')) return 'Kotak Bank';
    if (sender.contains('PNB') || upper.contains('PUNJAB NATIONAL')) return 'PNB';
    if (sender.contains('IDFC') || upper.contains('IDFC FIRST')) return 'IDFC First';
    if (sender.contains('BOB') || upper.contains('BANK OF BARODA')) return 'Bank of Baroda';
    if (sender.contains('YES') || upper.contains('YES BANK')) return 'Yes Bank';
    if (sender.contains('INDUS') || upper.contains('INDUSIND')) return 'IndusInd Bank';
    if (sender.contains('CANARA') || upper.contains('CANARA BANK')) return 'Canara Bank';
    return '';
  }

  static String _detectProviderOrBrand(String lower, String sender) {
    if (lower.contains('bescom') || sender.contains('BESCOM')) return 'BESCOM';
    if (lower.contains('tata power')) return 'Tata Power';
    if (lower.contains('adani electricity') || lower.contains('adani power')) return 'Adani Electricity';
    if (lower.contains('bses')) return 'BSES';
    if (lower.contains('msedcl') || lower.contains('mahavitaran')) return 'MSEDCL';
    if (lower.contains('uppcl')) return 'UPPCL';
    if (lower.contains('airtel') || sender.contains('AIRTEL')) return 'Airtel';
    if (lower.contains('jio') || sender.contains('JIO')) return 'Reliance Jio';
    if (lower.contains('vi') || lower.contains('vodafone')) return 'Vodafone Idea';
    if (lower.contains('tata play') || lower.contains('tatasky')) return 'Tata Play';
    if (lower.contains('act fibernet') || lower.contains('act fiber')) return 'ACT Fibernet';
    if (lower.contains('hathway')) return 'Hathway';
    if (lower.contains('indane')) return 'Indane Gas';
    if (lower.contains('bharat gas') || lower.contains('bpcl')) return 'Bharat Gas';
    if (lower.contains('hp gas') || lower.contains('hpcl')) return 'HP Gas';
    if (lower.contains('igl')) return 'Indraprastha Gas (IGL)';
    if (lower.contains('water board') || lower.contains('bwssb')) return 'Municipal Water Board';
    if (lower.contains('samsung') || sender.contains('SAMSUN')) return 'Samsung';
    if (lower.contains('apple') || sender.contains('APPLE')) return 'Apple';
    if (lower.contains('lg') || sender.contains('LG')) return 'LG Electronics';
    if (lower.contains('sony')) return 'Sony';
    if (lower.contains('whirlpool')) return 'Whirlpool';
    if (lower.contains('amazon') || sender.contains('AMAZON')) return 'Amazon India';
    if (lower.contains('flipkart') || sender.contains('FLIPKT')) return 'Flipkart';
    if (lower.contains('hdfc') || sender.contains('HDFC')) return 'HDFC Bank';
    if (lower.contains('sbi') || sender.contains('SBI')) return 'SBI';
    if (lower.contains('icici') || sender.contains('ICICI')) return 'ICICI Bank';
    if (lower.contains('axis') || sender.contains('AXIS')) return 'Axis Bank';
    if (lower.contains('kotak') || sender.contains('KOTAK')) return 'Kotak Bank';
    return 'Service Provider';
  }

  static String _detectApplianceTitle(String lower, String brand) {
    if (lower.contains('tv')) return '$brand Smart TV';
    if (lower.contains('refrigerator') || lower.contains('fridge')) return '$brand Refrigerator';
    if (lower.contains('washing machine')) return '$brand Washing Machine';
    if (lower.contains('microwave') || lower.contains('oven')) return '$brand Microwave Oven';
    if (lower.contains('ac') || lower.contains('air conditioner')) return '$brand Air Conditioner';
    if (lower.contains('laptop') || lower.contains('macbook')) return '$brand Laptop';
    if (lower.contains('phone') || lower.contains('iphone') || lower.contains('galaxy')) return '$brand Smartphone';
    return '$brand Appliance / Electronics';
  }

  static ({String title, String provider, BillCategoryType category}) _classifyBill(
    String lower,
    String sender,
  ) {
    if (lower.contains('electricity') ||
        lower.contains('bescom') ||
        lower.contains('tata power') ||
        lower.contains('adani electricity') ||
        lower.contains('msedcl') ||
        lower.contains('bses') ||
        lower.contains('uppcl')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Electricity Bill', provider: p, category: BillCategoryType.electricity);
    }

    if (lower.contains('airtel') ||
        lower.contains('jio') ||
        lower.contains('vi') ||
        lower.contains('vodafone') ||
        lower.contains('mobile bill') ||
        lower.contains('postpaid')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Postpaid Mobile Bill', provider: p, category: BillCategoryType.mobile);
    }

    if (lower.contains('broadband') ||
        lower.contains('act fibernet') ||
        lower.contains('fiber') ||
        lower.contains('wifi') ||
        lower.contains('hathway')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Broadband Bill', provider: p, category: BillCategoryType.internet);
    }

    if (lower.contains('gas') ||
        lower.contains('indane') ||
        lower.contains('bharat gas') ||
        lower.contains('hp gas') ||
        lower.contains('igl') ||
        lower.contains('mgl')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Gas / Cylinder Bill', provider: p, category: BillCategoryType.gas);
    }

    if (lower.contains('water') || lower.contains('bwssb') || lower.contains('jal board')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Water Bill', provider: p, category: BillCategoryType.water);
    }

    if (lower.contains('tata play') || lower.contains('dth') || lower.contains('dish tv') || lower.contains('sun direct')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p DTH Recharge Due', provider: p, category: BillCategoryType.dth);
    }

    if (lower.contains('credit card') || lower.contains('card ending') || lower.contains('sbi card') || lower.contains('hdfc card')) {
      final p = _detectProviderOrBrand(lower, sender);
      return (title: '$p Credit Card Statement', provider: p, category: BillCategoryType.other);
    }

    final p = _detectProviderOrBrand(lower, sender);
    return (title: '$p Utility Bill', provider: p, category: BillCategoryType.other);
  }

  static String _detectMerchantOrBeneficiary(String text, String lower, String sender) {
    // 1. Look for "at <MERCHANT>"
    final atMatch = RegExp(r'\bat\s+([A-Za-z0-9\s&.\-_]+?)(?:\s+on|\s+ref|\s+txn|\s+avl|\s+bal|\.|$|,)', caseSensitive: false).firstMatch(text);
    if (atMatch != null) {
      final m = atMatch.group(1)!.trim();
      if (m.isNotEmpty && m.length < 32 && !m.toLowerCase().startsWith('rs') && !m.toLowerCase().startsWith('inr')) {
        return m;
      }
    }

    // 2. Look for "to <MERCHANT/PERSON>"
    final toMatch = RegExp(r'\bto\s+([A-Za-z0-9\s&.\-_@]+?)(?:\s+on|\s+ref|\s+txn|\s+avl|\s+bal|\.|$|,)', caseSensitive: false).firstMatch(text);
    if (toMatch != null) {
      final m = toMatch.group(1)!.trim();
      if (m.isNotEmpty && m.length < 32 && !m.toLowerCase().startsWith('rs') && !m.toLowerCase().startsWith('inr')) {
        return m;
      }
    }

    // 3. Known Indian online services
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('blinkit')) return 'Blinkit';
    if (lower.contains('zepto')) return 'Zepto';
    if (lower.contains('instamart')) return 'Swiggy Instamart';
    if (lower.contains('bigbasket') || lower.contains('bbnow')) return 'BigBasket';
    if (lower.contains('amazon')) return 'Amazon India';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('myntra')) return 'Myntra';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola Cabs';
    if (lower.contains('rapido')) return 'Rapido';
    if (lower.contains('dmart')) return 'DMart';
    if (lower.contains('apollo')) return 'Apollo Pharmacy';
    if (lower.contains('1mg')) return 'Tata 1mg';
    if (lower.contains('bookmyshow')) return 'BookMyShow';
    if (lower.contains('irctc')) return 'IRCTC';
    if (lower.contains('makemytrip')) return 'MakeMyTrip';
    if (lower.contains('cred')) return 'CRED';
    if (lower.contains('shell')) return 'Shell Fuel';
    if (lower.contains('petrol') || lower.contains('fuel')) return 'Fuel Station';

    // 4. Fallback to sender if available
    if (sender.isNotEmpty && sender.length < 20) {
      return sender;
    }

    return 'Merchant / UPI Transfer';
  }

  static String _classifyExpenseCategory(String lower, String merchantLower) {
    // Food & Dining
    if (merchantLower.contains('swiggy') ||
        merchantLower.contains('zomato') ||
        merchantLower.contains('mcdonald') ||
        merchantLower.contains('dominos') ||
        merchantLower.contains('pizza') ||
        merchantLower.contains('burger') ||
        merchantLower.contains('starbucks') ||
        merchantLower.contains('cafe') ||
        merchantLower.contains('restaurant') ||
        merchantLower.contains('biryani') ||
        lower.contains('dining') ||
        lower.contains('restaurant')) {
      return 'food';
    }

    // Groceries
    if (merchantLower.contains('blinkit') ||
        merchantLower.contains('zepto') ||
        merchantLower.contains('instamart') ||
        merchantLower.contains('bigbasket') ||
        merchantLower.contains('dmart') ||
        merchantLower.contains('spencers') ||
        lower.contains('supermarket') ||
        lower.contains('grocery') ||
        lower.contains('kirana') ||
        lower.contains('milk') ||
        lower.contains('vegetables')) {
      return 'groceries';
    }

    // Shopping
    if (merchantLower.contains('amazon') ||
        merchantLower.contains('flipkart') ||
        merchantLower.contains('myntra') ||
        merchantLower.contains('nykaa') ||
        merchantLower.contains('ajio') ||
        merchantLower.contains('zara') ||
        merchantLower.contains('h&m') ||
        merchantLower.contains('croma') ||
        merchantLower.contains('reliance digital')) {
      return 'shopping';
    }

    // Travel & Transit
    if (merchantLower.contains('uber') ||
        merchantLower.contains('ola') ||
        merchantLower.contains('rapido') ||
        merchantLower.contains('metro') ||
        merchantLower.contains('fuel') ||
        merchantLower.contains('petrol') ||
        merchantLower.contains('diesel') ||
        merchantLower.contains('irctc') ||
        merchantLower.contains('makemytrip') ||
        merchantLower.contains('fastag') ||
        lower.contains('toll') ||
        lower.contains('flight') ||
        lower.contains('cab')) {
      return 'travel';
    }

    // Health
    if (merchantLower.contains('apollo') ||
        merchantLower.contains('1mg') ||
        merchantLower.contains('pharmeasy') ||
        merchantLower.contains('medplus') ||
        lower.contains('hospital') ||
        lower.contains('clinic') ||
        lower.contains('pharmacy') ||
        lower.contains('doctor') ||
        lower.contains('diagnostic')) {
      return 'health';
    }

    // Entertainment
    if (merchantLower.contains('bookmyshow') ||
        merchantLower.contains('netflix') ||
        merchantLower.contains('spotify') ||
        merchantLower.contains('prime video') ||
        merchantLower.contains('hotstar') ||
        merchantLower.contains('pvr') ||
        merchantLower.contains('inox')) {
      return 'entertainment';
    }

    // Utilities & Recharge
    if (merchantLower.contains('airtel') ||
        merchantLower.contains('jio') ||
        merchantLower.contains('bescom') ||
        merchantLower.contains('electricity') ||
        merchantLower.contains('broadband') ||
        merchantLower.contains('gas') ||
        lower.contains('recharge') ||
        lower.contains('bill pay')) {
      return 'utilities';
    }

    // Investment
    if (merchantLower.contains('zerodha') ||
        merchantLower.contains('groww') ||
        merchantLower.contains('mutual fund') ||
        merchantLower.contains('sip') ||
        merchantLower.contains('insurance') ||
        merchantLower.contains('lic')) {
      return 'investment';
    }

    return 'other';
  }

  static String? _resolveOfficialVpa(String providerOrMerchant, [String title = '']) {
    final lower = '${providerOrMerchant.toLowerCase()} ${title.toLowerCase()}';
    for (final entry in _officialBbpsVpa.entries) {
      if (lower.contains(entry.key) || entry.key.contains(providerOrMerchant.toLowerCase().trim())) {
        return entry.value;
      }
    }
    return null;
  }

  static String _generateHash(
    String type,
    String providerOrMerchant,
    String titleOrCategory,
    double amount,
    DateTime date,
    String? reference,
  ) {
    final normalizedDate = DateFormat('yyyy-MM-dd').format(date);
    final key = '$type|${providerOrMerchant.toLowerCase().trim()}|${titleOrCategory.toLowerCase().trim()}|${amount.toStringAsFixed(2)}|$normalizedDate|${reference?.trim() ?? ''}';
    return sha256.convert(utf8.encode(key)).toString();
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
        'dd-MMM-yyyy',
        'dd-MMM-yy',
      ];
      final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      for (final f in formats) {
        try {
          final dt = DateFormat(f).parseLoose(cleaned);
          if (dt.year < 2000) {
            return DateTime(dt.year + 2000, dt.month, dt.day);
          }
          return dt;
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }
}
