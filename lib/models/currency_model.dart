class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    required this.decimalDigits,
  });

  static const List<Currency> supportedCurrencies = [
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳', decimalDigits: 0),
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸', decimalDigits: 2),
    Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺', decimalDigits: 2),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧', decimalDigits: 2),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵', decimalDigits: 0),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺', decimalDigits: 2),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flag: '🇨🇦', decimalDigits: 2),
    Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', flag: '🇨🇭', decimalDigits: 2),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳', decimalDigits: 2),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won', flag: '🇰🇷', decimalDigits: 0),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬', decimalDigits: 2),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', flag: '🇦🇪', decimalDigits: 2),
    Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', flag: '🇸🇦', decimalDigits: 2),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', flag: '🇧🇷', decimalDigits: 2),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', flag: '🇲🇾', decimalDigits: 2),
  ];

  static Currency fromCode(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first, // Default to INR
    );
  }
}
