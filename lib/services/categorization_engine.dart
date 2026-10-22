import '../models/merchant_rule.dart';

/// Represents the outcome of predicting an expense category for a transaction.
class CategorizationResult {
  /// The predicted category name from [CategorizationEngine.allCategories].
  final String category;

  /// The confidence level of the prediction: 'high', 'medium', or 'low'.
  final String confidence;

  /// The reason or mechanism behind the prediction:
  /// - 'merchant_rule': Matched a user-corrected [MerchantRule] (Layer 1).
  /// - 'keyword_match': Matched a known merchant or service keyword (Layer 2).
  /// - 'transaction_type': Fallback based on transaction type (Layer 3).
  /// - 'no_match': No rule or keyword matched; defaulted to 'Other' (Layer 3).
  final String reason;

  const CategorizationResult({
    required this.category,
    required this.confidence,
    required this.reason,
  });

  /// Whether the result has high confidence.
  bool get isHighConfidence => confidence == 'high';

  /// Whether the result has medium confidence.
  bool get isMediumConfidence => confidence == 'medium';

  /// Whether the result has low confidence.
  bool get isLowConfidence => confidence == 'low';

  /// Converts the result to a map.
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'confidence': confidence,
      'reason': reason,
    };
  }

  /// Creates a result from a map.
  factory CategorizationResult.fromMap(Map<String, dynamic> map) {
    return CategorizationResult(
      category: map['category'] as String? ?? 'Other',
      confidence: map['confidence'] as String? ?? 'low',
      reason: map['reason'] as String? ?? 'no_match',
    );
  }

  /// Returns a copy of this result with updated values.
  CategorizationResult copyWith({
    String? category,
    String? confidence,
    String? reason,
  }) {
    return CategorizationResult(
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
    );
  }

  @override
  String toString() =>
      'CategorizationResult(category: $category, confidence: $confidence, reason: $reason)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorizationResult &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          confidence == other.confidence &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(category, confidence, reason);
}

/// A pure Dart service that predicts expense categories for auto-detected
/// transactions using a layered approach:
///
/// 1. **Layer 1: Merchant Rules** (highest priority) - User-corrected mappings.
/// 2. **Layer 2: Keyword Matching** - Comprehensive keyword matching for Indian merchants.
/// 3. **Layer 3: Transaction Type Fallback** - Fallback rules based on transaction type.
class CategorizationEngine {
  CategorizationEngine._();

  /// All 24 supported transaction categories in Finance Vault.
  static const List<String> allCategories = [
    'Food & Dining',
    'Groceries',
    'Transportation',
    'Fuel',
    'Shopping',
    'Medical & Healthcare',
    'Rent',
    'Electricity & Utilities',
    'Mobile & Internet',
    'Education',
    'Entertainment',
    'Travel',
    'Family',
    'Insurance',
    'Loan Repayment',
    'Gold Loan Interest',
    'EMI',
    'Subscriptions',
    'Personal Care',
    'Business Expenses',
    'Investments',
    'Transfers',
    'Cash Withdrawal',
    'Other',
  ];

  /// Comprehensive keyword map for Indian merchants, services, and utilities.
  static const Map<String, List<String>> keywordMap = {
    'Food & Dining': [
      'barbeque nation',
      'burger king',
      'haldirams',
      'starbucks',
      'mcdonalds',
      'dominos',
      'restaurant',
      'biryani',
      'kitchen',
      'swiggy',
      'zomato',
      'subway',
      'pizza',
      'dhaba',
      'cafe',
      'food',
      'dine',
      'eat',
      'kfc',
      'bhavan',
      'canteen',
      'bakery',
      'sweets',
      'mithai',
      'chaat',
      'brewery',
      'dining',
      'eatery',
      'mess',
      'chai',
      'coffee shop',
    ],
    'Groceries': [
      'more supermarket',
      'reliance fresh',
      'nature basket',
      'natures basket',
      'swiggy instamart',
      'instamart',
      'amazon fresh',
      'supermarket',
      'vegetables',
      'vegetable',
      'bigbasket',
      'spencer',
      'spencers',
      'groceries',
      'grocery',
      'grofers',
      'blinkit',
      'jiomart',
      'fruits',
      'fruit',
      'kirana',
      'dunzo',
      'dmart',
      'zepto',
      'hypermarket',
      'provision',
      'provisions',
      'sabzi',
      'mandi',
      'dairy',
      'milk',
    ],
    'Transportation': [
      'namma yatri',
      'bluesmart',
      'blusmart',
      'transportation',
      'transport',
      'auto rickshaw',
      'rickshaw',
      'rapido',
      'irctc',
      'train',
      'metro',
      'uber',
      'auto',
      'taxi',
      'cab',
      'cabs',
      'ola',
      'bus',
      'railway',
      'railways',
      'fastag',
      'toll',
      'toll plaza',
      'redbus',
      'chalo',
    ],
    'Fuel': [
      'bharat petroleum',
      'reliance petrol',
      'indian oil',
      'hp petrol',
      'petrol pump',
      'petrol bunk',
      'petrol',
      'diesel',
      'shell',
      'essar',
      'fuel',
      'hpcl',
      'bpcl',
      'iocl',
      'cng',
      'gas station',
    ],
    'Shopping': [
      'shoppers stop',
      'reliance digital',
      'tata cliq',
      'tatacliq',
      'snapdeal',
      'flipkart',
      'lifestyle',
      'shopping',
      'meesho',
      'myntra',
      'amazon',
      'nykaa',
      'store',
      'ajio',
      'zara',
      'mall',
      'h&m',
      'h m',
      'hm',
      'croma',
      'vijay sales',
      'decathlon',
      'uniqlo',
      'westside',
      'pantaloons',
      'retail',
      'clothing',
      'apparel',
      'footwear',
    ],
    'Medical & Healthcare': [
      'apollo pharmacy',
      'pharmeasy',
      'diagnostic',
      'diagnostics',
      'hospital',
      'pharmacy',
      'netmeds',
      'medplus',
      'medical',
      'apollo',
      'clinic',
      'doctor',
      'dental',
      'tata 1mg',
      '1mg',
      'lab',
      'pathology',
      'healthcare',
      'chemist',
      'medicine',
      'medicines',
      'dentist',
      'physician',
      'practo',
    ],
    'Rent': [
      'accommodation',
      'paying guest',
      'landlord',
      'hostel',
      'house rent',
      'office rent',
      'room rent',
      'flat rent',
      'tenancy',
      'lease',
      'rent',
      'pg',
    ],
    'Electricity & Utilities': [
      'reliance energy',
      'electricity',
      'tata power',
      'water bill',
      'municipal',
      'gas bill',
      'bescom',
      'bwssb',
      'sewage',
      'adani electricity',
      'adani power',
      'adani',
      'utility',
      'utilities',
      'power bill',
      'electric bill',
      'indraprastha gas',
      'igl',
      'mahanagar gas',
      'mgl',
      'piped gas',
      'cylinder',
      'lpg',
    ],
    'Mobile & Internet': [
      'act fibernet',
      'mobile bill',
      'broadband',
      'data pack',
      'recharge',
      'airtel',
      'bsnl',
      'jio fiber',
      'jiofiber',
      'jio',
      'vi recharge',
      'vodafone idea',
      'vodafone',
      'vi',
      'wifi',
      'fiber',
      'fibernet',
      'telecom',
      'postpaid',
      'prepaid',
    ],
    'Education': [
      'university',
      'coursera',
      'tuition fees',
      'college fees',
      'school fees',
      'tuition',
      'coaching',
      'college',
      'school',
      'udemy',
      'bookstore',
      'books',
      'fees',
      'exam',
      'academy',
      'education',
      'course',
      'classes',
      'edx',
      'unacademy',
      'byjus',
    ],
    'Entertainment': [
      'disney+ hotstar',
      'disney hotstar',
      'prime video',
      'google play',
      'play store',
      'bookmyshow',
      'multiplex',
      'netflix',
      'hotstar',
      'spotify',
      'youtube',
      'cinema',
      'disney',
      'movie',
      'movies',
      'theatre',
      'theater',
      'inox',
      'game',
      'gaming',
      'apple',
      'pvr',
      'sonyliv',
      'zee5',
      'gaana',
      'wynk',
    ],
    'Travel': [
      'makemytrip',
      'booking.com',
      'booking com',
      'air india',
      'cleartrip',
      'goibibo',
      'airlines',
      'airline',
      'vistara',
      'flights',
      'flight',
      'airbnb',
      'indigo',
      'hotels',
      'hotel',
      'resort',
      'yatra',
      'oyo rooms',
      'oyo',
      'spicejet',
      'akasa air',
      'boarding',
      'trip',
      'travel',
      'tour',
      'tours',
      'homestay',
      'vacation',
      'mmt',
    ],
    'Family': [
      'pocket money',
      'childcare',
      'allowance',
      'parents',
      'daycare',
      'family',
      'baby',
    ],
    'Insurance': [
      'health insurance',
      'motor insurance',
      'life insurance',
      'insurance premium',
      'icici prudential',
      'icici pru',
      'hdfc life',
      'insurance',
      'premium',
      'lic',
      'policybazaar',
      'max life',
      'sbi life',
      'star health',
      'tata aia',
      'bajaj allianz',
    ],
    'Loan Repayment': [
      'principal repayment',
      'loan repayment',
      'personal loan',
      'vehicle loan',
      'education loan',
      'emi payment',
      'home loan',
      'car loan',
      'loan payment',
      'loans',
      'loan',
    ],
    'Gold Loan Interest': [
      'gold loan interest',
      'muthoot finance',
      'gold interest',
      'manappuram',
      'gold loan',
      'muthoot',
    ],
    'EMI': [
      'credit card emi',
      'bajaj finserv',
      'no cost emi',
      'installment',
      'instalment',
      'easy emi',
      'hdfc emi',
      'icici emi',
      'sbi emi',
      'emi',
    ],
    'Subscriptions': [
      'subscription',
      'subscriptions',
      'monthly plan',
      'annual plan',
      'membership',
      'auto renew',
      'renewal',
      'subscriber',
      'recurring',
    ],
    'Personal Care': [
      'cult.fit',
      'cult fit',
      'cultfit',
      'grooming',
      'parlour',
      'parlor',
      'fitness',
      'barber',
      'salon',
      'spa',
      'gym',
      'haircut',
      'beauty',
      'cosmetics',
      'massage',
      'yoga',
      'crossfit',
    ],
    'Business Expenses': [
      'stationery',
      'printing',
      'business',
      'blue dart',
      'bluedart',
      'delhivery',
      'courier',
      'office',
      'vendor',
      'dhl',
      'fedex',
      'dtdc',
      'corporate',
    ],
    'Investments': [
      'mutual funds',
      'mutual fund',
      'fixed deposit',
      'investments',
      'investment',
      'motilal oswal',
      'smallcase',
      'angel one',
      'zerodha',
      'upstox',
      'groww',
      'demat',
      'stocks',
      'stock',
      'shares',
      'share',
      'kuvera',
      'equity',
      'bonds',
      'nps',
      'ppf',
      'sip',
      'fd',
      'sebi',
      'coin',
    ],
    'Transfers': [
      'own account',
      'sent to self',
      'fund transfer',
      'transfers',
      'transfer',
      'wallet',
      'self',
      'neft',
      'rtgs',
      'imps',
      'send money',
    ],
    'Cash Withdrawal': [
      'cash withdrawal',
      'cash dispense',
      'withdrawal',
      'withdraw',
      'atm wdl',
      'cash wdl',
      'atm',
    ],
    'Other': [],
  };

  /// Predicts the category for a transaction using a layered approach:
  ///
  /// - **Layer 1: Merchant Rules** (highest priority)
  ///   Matches user-corrected [MerchantRule] patterns against normalized merchant text.
  ///   Returns with confidence='high', reason='merchant_rule'.
  ///
  /// - **Layer 2: Keyword Matching**
  ///   Matches merchant text (or [description]) against the comprehensive Indian merchant keyword map.
  ///   Uses the most specific (longest) keyword match.
  ///   Returns with confidence='medium', reason='keyword_match'.
  ///
  /// - **Layer 3: Transaction Type Fallback**
  ///   - 'transfer' -> category='Transfers', confidence='medium', reason='transaction_type'
  ///   - 'withdrawal' -> category='Cash Withdrawal', confidence='medium', reason='transaction_type'
  ///   - 'refund' -> category='Other', confidence='low', reason='transaction_type'
  ///   - Default -> category='Other', confidence='low', reason='no_match'
  static CategorizationResult categorize({
    required String merchant,
    required String transactionType,
    String? description,
    List<MerchantRule> merchantRules = const [],
  }) {
    final normMerchant = normalizeMerchant(merchant);
    final normDesc = description != null ? normalizeMerchant(description) : '';

    // =========================================================================
    // Layer 1: Merchant Rules (highest priority)
    // =========================================================================
    if (merchantRules.isNotEmpty) {
      if (normMerchant.isNotEmpty) {
        final ruleMatch = _matchMerchantRule(
          normalizedMerchant: normMerchant,
          transactionType: transactionType,
          merchantRules: merchantRules,
        );
        if (ruleMatch != null) {
          return ruleMatch;
        }
      }

      // If merchant is empty, check description against rules as fallback
      if (normMerchant.isEmpty && normDesc.isNotEmpty) {
        final descRuleMatch = _matchMerchantRule(
          normalizedMerchant: normDesc,
          transactionType: transactionType,
          merchantRules: merchantRules,
        );
        if (descRuleMatch != null) {
          return descRuleMatch;
        }
      }
    }

    // =========================================================================
    // Layer 2: Keyword Matching
    // =========================================================================
    // Check normalized merchant text first
    if (normMerchant.isNotEmpty) {
      final merchantMatch = _matchKeywords(normMerchant);
      if (merchantMatch != null) {
        return merchantMatch;
      }
    }

    // If no match in merchant, check normalized description
    if (normDesc.isNotEmpty) {
      final descMatch = _matchKeywords(normDesc);
      if (descMatch != null) {
        return descMatch;
      }
    }

    // =========================================================================
    // Layer 3: Transaction Type Fallback
    // =========================================================================
    final normType = transactionType.toLowerCase().trim();

    if (normType == 'transfer') {
      return const CategorizationResult(
        category: 'Transfers',
        confidence: 'medium',
        reason: 'transaction_type',
      );
    }

    if (normType == 'withdrawal') {
      return const CategorizationResult(
        category: 'Cash Withdrawal',
        confidence: 'medium',
        reason: 'transaction_type',
      );
    }

    if (normType == 'refund') {
      return const CategorizationResult(
        category: 'Other',
        confidence: 'low',
        reason: 'transaction_type',
      );
    }

    // Default fallback
    return const CategorizationResult(
      category: 'Other',
      confidence: 'low',
      reason: 'no_match',
    );
  }

  /// Normalizes a merchant name or pattern for matching.
  ///
  /// Converts to lowercase, strips apostrophes, replaces non-alphanumeric
  /// characters with spaces, collapses multiple whitespace, and trims.
  static String normalizeMerchant(String merchant) {
    if (merchant.isEmpty) return '';
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r"['`]"), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks whether a given category name is valid.
  static bool isValidCategory(String category) {
    return allCategories.contains(category);
  }

  /// Returns the keywords defined for a specific category.
  static List<String> getKeywordsForCategory(String category) {
    return keywordMap[category] ?? const [];
  }

  /// Matches a normalized merchant string against a list of [MerchantRule]s.
  ///
  /// Evaluates exact matches, word-boundary substring matches, and reverse
  /// containment. Prioritizes matching transactionType, exact matches, and
  /// longer pattern lengths.
  static CategorizationResult? _matchMerchantRule({
    required String normalizedMerchant,
    required String transactionType,
    required List<MerchantRule> merchantRules,
  }) {
    if (normalizedMerchant.isEmpty) return null;

    MerchantRule? bestRule;
    int bestScore = -1;
    final normType = transactionType.toLowerCase().trim();

    for (final rule in merchantRules) {
      final normPattern = normalizeMerchant(rule.merchantPattern);
      if (normPattern.isEmpty) continue;

      bool isMatch = false;
      bool isExact = false;

      if (normalizedMerchant == normPattern) {
        isMatch = true;
        isExact = true;
      } else {
        // Word boundary regex: does normalizedMerchant contain normPattern?
        final patternRegex = RegExp(
          r'(?:^|\b)' + RegExp.escape(normPattern) + r'(?:\b|$)',
          caseSensitive: false,
        );
        if (patternRegex.hasMatch(normalizedMerchant)) {
          isMatch = true;
        } else if (normalizedMerchant.length >= 3) {
          // Check if pattern contains merchant (e.g. pattern was 'Uber India' and merchant is 'Uber')
          final reverseRegex = RegExp(
            r'(?:^|\b)' + RegExp.escape(normalizedMerchant) + r'(?:\b|$)',
            caseSensitive: false,
          );
          if (reverseRegex.hasMatch(normPattern)) {
            isMatch = true;
          }
        }
      }

      if (isMatch) {
        final ruleType = rule.transactionType.toLowerCase().trim();
        final matchesType = ruleType.isNotEmpty && ruleType == normType;

        // Scoring: type match (100,000) > exact match (10,000) > pattern length
        int score = normPattern.length;
        if (isExact) score += 10000;
        if (matchesType) score += 100000;

        if (score > bestScore) {
          bestScore = score;
          bestRule = rule;
        }
      }
    }

    if (bestRule != null) {
      return CategorizationResult(
        category: bestRule.category,
        confidence: 'high',
        reason: 'merchant_rule',
      );
    }

    return null;
  }

  /// Matches normalized text against the [keywordMap].
  ///
  /// Returns the match with the longest keyword across all categories.
  static CategorizationResult? _matchKeywords(String normalizedText) {
    if (normalizedText.isEmpty) return null;

    String? bestCategory;
    int maxKeywordLength = 0;

    for (final category in allCategories) {
      final keywords = keywordMap[category];
      if (keywords == null) continue;

      for (final kw in keywords) {
        final normKw = normalizeMerchant(kw);
        if (normKw.isEmpty) continue;

        final regex = RegExp(
          r'(?:^|\b)' + RegExp.escape(normKw) + r'(?:\b|$)',
          caseSensitive: false,
        );

        if (regex.hasMatch(normalizedText)) {
          if (normKw.length > maxKeywordLength) {
            maxKeywordLength = normKw.length;
            bestCategory = category;
          }
        }
      }
    }

    if (bestCategory != null) {
      return CategorizationResult(
        category: bestCategory,
        confidence: 'medium',
        reason: 'keyword_match',
      );
    }

    return null;
  }
}
