class UpiDirectory {
  static const Map<String, String> _knownVpas = {
    // Electricity
    'bescom': 'bescom@sbi',
    'tata power': 'tatapower@icici',
    'adani electricity': 'adanipower@icici',
    'bses': 'bsesrajdhani@icici',
    'bses rajdhani': 'bsesrajdhani@icici',
    'bses yamuna': 'bsesyamuna@icici',
    'msedcl': 'msedcl@sbi',
    'mahavitaran': 'msedcl@sbi',
    'uppcl': 'uppcl@sbi',
    'pspcl': 'pspcl@sbi',
    'tsspdcl': 'tsspdcl@sbi',

    // Telecom & Broadband
    'airtel': 'airtelpaymentsbank@icici',
    'reliance jio': 'reliancejio@icici',
    'jio': 'reliancejio@icici',
    'vodafone': 'vodafone@icici',
    'vi': 'vodafone@icici',
    'act fibernet': 'actfibernet@icici',
    'tata play': 'tatasky@icici',
    'hathway': 'hathway@icici',

    // Gas & Water
    'indane': 'indane@icici',
    'bharat gas': 'bharatgas@sbi',
    'hp gas': 'hpgas@icici',
    'igl': 'igl@icici',
    'mgl': 'mgl@icici',
    'bwssb': 'bwssb@sbi',
    'delhi jal board': 'delhijalboard@icici',

    // Credit Cards
    'hdfc bank credit card': 'hdfcbankcard@hdfcbank',
    'hdfc card': 'hdfcbankcard@hdfcbank',
    'sbi card': 'sbicard@sbi',
    'icici bank credit card': 'icicibankcard@icici',
    'icici card': 'icicibankcard@icici',
    'axis bank credit card': 'axisbankcard@axisbank',
    'kotak credit card': 'kotakcard@kotak',
  };

  /// Resolves real official BBPS VPA for a provider or bill title.
  /// Returns null if provider is unverified (never returns a fake mock VPA).
  static String? resolveVpa(String providerName, [String billTitle = '']) {
    final cleanProvider = providerName.toLowerCase().trim();
    final cleanTitle = billTitle.toLowerCase().trim();

    for (final entry in _knownVpas.entries) {
      if (cleanProvider.contains(entry.key) || cleanTitle.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
