/// Service for parsing Indian payment notifications and extracting transaction details.
library;

/// Represents the parsed result of a payment notification.
class ParsedTransaction {
  /// The extracted transaction amount in Indian Rupees (INR), or null if not detected.
  final double? amount;

  /// The extracted merchant or recipient name, or null if not detected.
  final String? merchant;

  /// The UPI reference number or transaction ID, or null if not detected.
  final String? upiRef;

  /// The detected transaction type:
  /// 'expense', 'income', 'transfer', 'refund', or 'failed'.
  final String transactionType;

  /// Whether the notification represents a valid financial transaction.
  final bool isValid;

  /// The raw notification text that was parsed.
  final String rawText;

  /// The package name of the source app (e.g. `com.phonepe.app`).
  final String sourceApp;

  /// Creates a [ParsedTransaction] instance.
  const ParsedTransaction({
    this.amount,
    this.merchant,
    this.upiRef,
    this.transactionType = 'expense',
    required this.isValid,
    required this.rawText,
    this.sourceApp = '',
  });

  /// Creates an invalid transaction result.
  factory ParsedTransaction.invalid({
    required String rawText,
    String sourceApp = '',
    String transactionType = 'failed',
    double? amount,
    String? merchant,
    String? upiRef,
  }) {
    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      upiRef: upiRef,
      transactionType: transactionType,
      isValid: false,
      rawText: rawText,
      sourceApp: sourceApp,
    );
  }

  /// Converts this [ParsedTransaction] to a Map.
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'upiRef': upiRef,
      'transactionType': transactionType,
      'isValid': isValid ? 1 : 0,
      'rawText': rawText,
      'sourceApp': sourceApp,
    };
  }

  /// Creates a [ParsedTransaction] from a Map.
  factory ParsedTransaction.fromMap(Map<String, dynamic> map) {
    return ParsedTransaction(
      amount: (map['amount'] as num?)?.toDouble(),
      merchant: map['merchant'] as String?,
      upiRef: map['upiRef'] as String?,
      transactionType: map['transactionType'] as String? ?? 'expense',
      isValid: map['isValid'] == 1 || map['isValid'] == true,
      rawText: map['rawText'] as String? ?? '',
      sourceApp: map['sourceApp'] as String? ?? '',
    );
  }

  /// Creates a copy of this [ParsedTransaction] with optional updated fields.
  ParsedTransaction copyWith({
    double? amount,
    String? merchant,
    String? upiRef,
    String? transactionType,
    bool? isValid,
    String? rawText,
    String? sourceApp,
  }) {
    return ParsedTransaction(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      upiRef: upiRef ?? this.upiRef,
      transactionType: transactionType ?? this.transactionType,
      isValid: isValid ?? this.isValid,
      rawText: rawText ?? this.rawText,
      sourceApp: sourceApp ?? this.sourceApp,
    );
  }

  @override
  String toString() {
    return 'ParsedTransaction('
        'amount: $amount, '
        'merchant: $merchant, '
        'upiRef: $upiRef, '
        'transactionType: $transactionType, '
        'isValid: $isValid, '
        'sourceApp: $sourceApp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTransaction &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          merchant == other.merchant &&
          upiRef == other.upiRef &&
          transactionType == other.transactionType &&
          isValid == other.isValid &&
          rawText == other.rawText &&
          sourceApp == other.sourceApp;

  @override
  int get hashCode => Object.hash(
        amount,
        merchant,
        upiRef,
        transactionType,
        isValid,
        rawText,
        sourceApp,
      );
}

/// Pure Dart service that parses Indian payment notification text and extracts
/// transaction details.
class TransactionParser {
  TransactionParser._();

  /// Known payment app package names.
  static const String googlePayPackage = 'com.google.android.apps.nbu.paisa.user';
  static const String phonePePackage = 'com.phonepe.app';
  static const String paytmPackage = 'net.one97.paytm';
  static const String amazonPayPackage = 'in.amazon.mShop.android.shopping';
  static const String credPackage = 'com.cred.android';
  static const String bhimPackage = 'in.org.npci.upiapp';

  /// Main entry point - parse a notification.
  ///
  /// Extracts the amount, merchant, UPI reference, and transaction type from
  /// [text], applying heuristics and app-specific rules based on [sourceApp].
  static ParsedTransaction parse(String text, [String sourceApp = '']) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return ParsedTransaction(
        isValid: false,
        rawText: text,
        sourceApp: sourceApp,
        transactionType: 'failed',
      );
    }

    // Step 1: Detect transaction type
    final transactionType = _detectTransactionType(cleanText);

    // Step 2: Extract amount
    final amount = _extractAmount(cleanText);

    // Step 3: Extract merchant
    final merchant = _extractMerchant(cleanText);

    // Step 4: Extract UPI Reference ID
    final upiRef = _extractUpiRef(cleanText);

    // Step 5: Validate transaction
    final isValid = _isValidTransaction(cleanText) && amount != null && amount > 0;

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      upiRef: upiRef,
      transactionType: transactionType,
      isValid: isValid,
      rawText: text,
      sourceApp: sourceApp,
    );
  }

  /// Extracts the transaction amount from [text].
  ///
  /// Supports:
  /// - `₹250`, `₹1,250`, `₹1,250.00`, `₹ 250`
  /// - `Rs.250`, `Rs. 1,250`, `Rs 250.00`, `Rs250`
  /// - `INR 250`, `INR 1,250.00`, `inr 250`
  /// - Bare amounts with context (e.g., `Payment of 1,250.00`)
  /// - Indian numbering format with commas (e.g., `1,00,000` = 100000)
  ///
  /// Filters out account balance figures when an actual transaction amount is present.
  static double? _extractAmount(String text) {
    // Priority 1: Amounts preceded by transaction verbs, e.g. "paid ₹250", "debited by INR 1,500.00"
    final directActionRegex = RegExp(
      r'(?:paid|payment\s+of|debited\s*(?:by|for|with)?|credited\s*(?:by|for|with)?|received|sent|transferred|spent|charged\s*(?:for|with)?|refund\s+of)\s*(?:INR|Rs\.?|₹)?\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final directMatch = directActionRegex.firstMatch(text);
    if (directMatch != null) {
      final val = _parseAmount(directMatch.group(1));
      if (val != null) return val;
    }

    // Priority 2: Amounts followed by transaction verbs, e.g. "₹200 paid", "INR 1,500.00 debited"
    final reverseActionRegex = RegExp(
      r'(?:INR|Rs\.?|₹)?\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*(?:debited|credited|paid|transferred|sent|spent|received|refunded)',
      caseSensitive: false,
    );
    final reverseMatch = reverseActionRegex.firstMatch(text);
    if (reverseMatch != null) {
      final val = _parseAmount(reverseMatch.group(1));
      if (val != null) return val;
    }

    // Priority 3: Currency-prefixed amounts: ₹, Rs, Rs., INR
    // Find all currency matches, filtering out those that are balances
    final currencyRegex = RegExp(
      r'(?:₹|Rs\.?|INR)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final matches = currencyRegex.allMatches(text);
    for (final match in matches) {
      // Check prefix before this match to ensure it's not an account balance
      final startIndex = match.start;
      final prefixStart = startIndex > 30 ? startIndex - 30 : 0;
      final prefix = text.substring(prefixStart, startIndex).toLowerCase();

      final isBalance = RegExp(
        r'(?:bal(?:ance)?|avail(?:able)?\s+bal(?:ance)?|total\s+bal(?:ance)?|ledger\s+bal(?:ance)?)\s*(?:is|:)?\s*$',
        caseSensitive: false,
      ).hasMatch(prefix);

      if (!isBalance) {
        final val = _parseAmount(match.group(1));
        if (val != null) return val;
      }
    }

    // Priority 4: Currency postfix (e.g. "250 ₹", "1,250 Rs")
    final postfixRegex = RegExp(
      r'([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*(?:₹|Rs\.?|INR)',
      caseSensitive: false,
    );
    final postfixMatch = postfixRegex.firstMatch(text);
    if (postfixMatch != null) {
      final val = _parseAmount(postfixMatch.group(1));
      if (val != null) return val;
    }

    // Priority 5: Bare amount with generic context keywords
    final bareContextRegex = RegExp(
      r'\b(?:amount|sum|value)\s*(?:of|is|:)?\s*(?:INR|Rs\.?|₹)?\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final bareMatch = bareContextRegex.firstMatch(text);
    if (bareMatch != null) {
      final val = _parseAmount(bareMatch.group(1));
      if (val != null) return val;
    }

    return null;
  }

  /// Parses a raw amount string (handling commas in Indian numbering) into a double.
  static double? _parseAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed != null && parsed > 0 && !parsed.isNaN && !parsed.isInfinite) {
      return parsed;
    }
    return null;
  }

  /// Extracts the merchant or recipient name from [text].
  ///
  /// Extracts text after `to`, `at`, `from`, or `for` keywords,
  /// strips out UPI IDs (e.g. `user@ybl`), trailing clauses (e.g. `via UPI`, `on PhonePe`),
  /// discards account numbers (e.g. `A/c XX1234`), and capitalizes the result properly.
  static String? _extractMerchant(String text) {
    String? candidate;

    // Pattern 1: Action + 'to' + Merchant
    // Examples: "Paid ₹250 to Store Name", "Payment of ₹500 to Merchant successful", "₹200 paid to XYZ"
    final toPattern = RegExp(
      r'(?:paid\s*(?:to)?|payment\s*(?:of\s*[^to\n]+)?\s*to|sent\s*(?:to)?|transferred\s*(?:to)?)\s+([A-Za-z0-9\s&.\-_@()]+)',
      caseSensitive: false,
    );
    final toMatch = toPattern.firstMatch(text);
    if (toMatch != null) {
      candidate = _cleanMerchantCandidate(toMatch.group(1));
      if (_isValidMerchant(candidate)) return _capitalizeMerchant(candidate!);
    }

    // Pattern 2: 'at' / 'towards' + Merchant (stores, restaurants, POS)
    // Examples: "purchase at Starbucks", "debited at Reliance Fresh", "spent at Cafe"
    final atPattern = RegExp(
      r'(?:at|towards)\s+([A-Za-z0-9\s&.\-_@()]+)',
      caseSensitive: false,
    );
    final atMatch = atPattern.firstMatch(text);
    if (atMatch != null) {
      candidate = _cleanMerchantCandidate(atMatch.group(1));
      if (_isValidMerchant(candidate)) return _capitalizeMerchant(candidate!);
    }

    // Pattern 3: 'from' + Sender/Merchant (for received / income / refund)
    // Examples: "received from John Doe", "refund from Amazon", "Cashback from Google Pay"
    final fromPattern = RegExp(
      r'(?:from)\s+([A-Za-z0-9\s&.\-_@()]+)',
      caseSensitive: false,
    );
    final fromMatches = fromPattern.allMatches(text);
    for (final match in fromMatches) {
      final clean = _cleanMerchantCandidate(match.group(1));
      if (_isValidMerchant(clean)) {
        return _capitalizeMerchant(clean!);
      }
    }

    // Pattern 4: 'for' + Merchant/Service
    // Examples: "paid for Uber", "paid ₹150 for Uber trip", "payment for Swiggy"
    final forPattern = RegExp(
      r'\bfor\s+([A-Za-z0-9\s&.\-_@()]+)',
      caseSensitive: false,
    );
    final forMatches = forPattern.allMatches(text);
    for (final match in forMatches) {
      final clean = _cleanMerchantCandidate(match.group(1));
      if (_isValidMerchant(clean)) {
        return _capitalizeMerchant(clean!);
      }
    }

    // Pattern 5: Generic 'to <Recipient>'
    final genericTo = RegExp(r'\bto\s+([A-Za-z0-9\s&.\-_@()]+)', caseSensitive: false);
    final genericMatch = genericTo.firstMatch(text);
    if (genericMatch != null) {
      candidate = _cleanMerchantCandidate(genericMatch.group(1));
      if (_isValidMerchant(candidate)) return _capitalizeMerchant(candidate!);
    }

    return null;
  }

  /// Cleans a candidate merchant string by stripping UPI IDs, stop words, and punctuation.
  static String? _cleanMerchantCandidate(String? raw) {
    if (raw == null) return null;
    var candidate = raw.trim();

    // Stop at currency indicator or amount
    candidate = candidate.split(RegExp(r'(?:₹|Rs\.?|INR|\b\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?\b)'))[0];

    // Remove stop words and suffixes (e.g. "successful", "via UPI", "using ...", "on PhonePe")
    final stopPhrases = [
      RegExp(r'\b(?:is\s+)?successful(?:ly)?\b.*$', caseSensitive: false),
      RegExp(r'\b(?:is\s+)?completed\b.*$', caseSensitive: false),
      RegExp(r'\b(?:is\s+)?failed\b.*$', caseSensitive: false),
      RegExp(r'\b(?:via|using|through)\b.*$', caseSensitive: false),
      RegExp(r'\bon\s+(?:PhonePe|Google\s*Pay|GPay|Paytm|Amazon\s*Pay|BHIM|WhatsApp|UPI|\d{1,2}[-\/]\d{1,2}).*$', caseSensitive: false),
      RegExp(r'\b(?:upi\s*ref|txn\s*id|transaction\s*id|ref\s*no|rrn|info)[\s:#].*$', caseSensitive: false),
      RegExp(r'\b(?:avail|bal|balance)\b.*$', caseSensitive: false),
      RegExp(r'\b(?:dated|with)\b.*$', caseSensitive: false),
      RegExp(r'\b(?:order|trip|ride|subscription)\b.*$', caseSensitive: false),
      RegExp(r'[\n\r.,;!?].*$'),
    ];

    for (final pattern in stopPhrases) {
      candidate = candidate.split(pattern)[0];
    }

    // Remove UPI ID in parentheses: e.g. " (user@ybl)"
    candidate = candidate.replaceAll(RegExp(r'\([a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+\)'), '');

    // If candidate itself is just a UPI ID: "rahul@okaxis"
    final pureUpiMatch = RegExp(r'^([a-zA-Z0-9.\-_]+)@[a-zA-Z0-9]+$').firstMatch(candidate.trim());
    if (pureUpiMatch != null) {
      candidate = pureUpiMatch.group(1) ?? '';
    } else {
      // Remove standalone UPI IDs
      candidate = candidate.replaceAll(RegExp(r'[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+'), '');
    }

    // Remove stray parentheses, brackets, or punctuation
    candidate = candidate.replaceAll(RegExp(r'[()[\]{}"\x27]'), '');
    candidate = candidate.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    candidate = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();

    return candidate.isEmpty ? null : candidate;
  }

  /// Verifies whether [name] is a plausible merchant name rather than an account number or system keyword.
  static bool _isValidMerchant(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final trimmed = name.trim();

    // Too short (single letter)
    if (trimmed.length < 2) return false;

    final lower = trimmed.toLowerCase();

    // Check account-like patterns: "A/c XX1234", "Account 5678", "card ending 1234", "XX1234", "your own account"
    if (RegExp(r'\b(?:a\/c|acct|account|card|vpa|wallet|upi)\b', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }

    // Pure digits or masked numbers like "XX1234", "****5678", "1234"
    if (RegExp(r'^[xX\*\d\s\-]+$').hasMatch(trimmed)) {
      return false;
    }

    // Generic self / account / banking words
    if (lower == 'self' ||
        lower.contains('own account') ||
        lower.contains('your account') ||
        lower == 'bank' ||
        lower == 'atm' ||
        lower == 'branch' ||
        lower == 'user') {
      return false;
    }

    return true;
  }

  /// Properly capitalizes a merchant name, handling title casing, acronyms, and hyphens.
  static String _capitalizeMerchant(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    final isAllUpper = trimmed == trimmed.toUpperCase() && trimmed.contains(RegExp(r'[A-Z]'));
    final isAllLower = trimmed == trimmed.toLowerCase() && trimmed.contains(RegExp(r'[a-z]'));

    // Known acronyms to preserve in uppercase
    const knownAcronyms = {
      'KFC',
      'PVR',
      'CCD',
      'ATM',
      'BBQ',
      'HDFC',
      'SBI',
      'ICICI',
      'PNB',
      'UPI',
      'OTP',
      'NCR',
      'IRCTC',
      'BEST',
      'BMTC',
      'DMRC',
      'BBD',
    };

    final words = trimmed.split(' ');
    final capitalizedWords = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;

      // Handle hyphenated words like "D-Mart"
      if (word.contains('-')) {
        final parts = word.split('-');
        final capitalizedParts = parts.map((p) {
          if (p.isEmpty) return '';
          final upperPart = p.toUpperCase();
          if (knownAcronyms.contains(upperPart)) return upperPart;
          return p[0].toUpperCase() + p.substring(1).toLowerCase();
        }).join('-');
        capitalizedWords.add(capitalizedParts);
        continue;
      }

      final upperWord = word.toUpperCase();
      if (knownAcronyms.contains(upperWord) ||
          (word.length <= 3 && isAllUpper && RegExp(r'^[A-Z]+$').hasMatch(word))) {
        capitalizedWords.add(upperWord);
      } else if (isAllUpper || isAllLower) {
        capitalizedWords.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
      } else {
        capitalizedWords.add(word[0].toUpperCase() + word.substring(1));
      }
    }

    return capitalizedWords.join(' ');
  }

  /// Extracts the UPI Reference ID or Transaction ID from [text].
  ///
  /// Patterns recognized:
  /// - `UPI Ref: 123456789012`
  /// - `UPI Ref No: 123456789012`
  /// - `Txn ID: T231022123456`
  /// - `Ref No: 987654321`
  /// - `Transaction ID: 429381293812`
  /// - `UPI: 1234567890`
  /// - `RRN: 123456789012`
  static String? _extractUpiRef(String text) {
    final upiRefRegex = RegExp(
      r'(?:UPI\s*Ref(?:erence)?(?:\s*No\.?)?|Txn\s*(?:ID|No\.?)|Transaction\s*ID|Ref\s*No\.?|Ref\s*ID|UPI\s*RRN|RRN|UPI[:/])\s*[:#-]?\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );

    final match = upiRefRegex.firstMatch(text);
    if (match != null) {
      final ref = match.group(1)?.trim();
      if (ref != null && ref.length >= 4) {
        return ref;
      }
    }
    return null;
  }

  /// Detects the transaction type from [text].
  ///
  /// Returns one of:
  /// - `'failed'` for declined, reversed, or failed transactions.
  /// - `'refund'` for refunds and reversal credits.
  /// - `'transfer'` for self-transfers or transfers between own accounts.
  /// - `'income'` for deposits, received payments, credits, and cashbacks.
  /// - `'expense'` for debits, payments, purchases, and sent money.
  static String _detectTransactionType(String text) {
    final lower = text.toLowerCase();

    // 1. Failed
    final failedPattern = RegExp(
      r'\b(failed|declined|unsuccessful|bounced|rejected|cancelled|timed\s*out|declined\s+by\s+bank)\b',
      caseSensitive: false,
    );
    if (failedPattern.hasMatch(lower)) {
      return 'failed';
    }

    if (lower.contains('reversed')) {
      return 'failed';
    }

    // 2. Refund
    final refundPattern = RegExp(
      r'\b(refund|refunded|reversal\s+credit|reversal\s+of\s+debit)\b',
      caseSensitive: false,
    );
    if (refundPattern.hasMatch(lower)) {
      return 'refund';
    }

    // 3. Transfer (self / own account)
    final transferPattern = RegExp(
      r'\b(self[-\s]transfer|transferred\s+to\s+your|own\s+account|transfer\s+to\s+self|transferred\s+to\s+own|between\s+accounts)\b',
      caseSensitive: false,
    );
    if (transferPattern.hasMatch(lower)) {
      return 'transfer';
    }

    // 4. Income / Credit
    final incomePattern = RegExp(
      r'\b(received|credited|cashback|reward|rewards|deposited|money\s+received|added\s+to\s+(?:your\s+)?wallet|added\s+to\s+a\/c)\b',
      caseSensitive: false,
    );
    final incomeTransferPattern = RegExp(
      r'\btransferred\s+to\s+you\b',
      caseSensitive: false,
    );
    if (incomePattern.hasMatch(lower) || incomeTransferPattern.hasMatch(lower)) {
      return 'income';
    }

    // 5. Expense / Debit (default for payments)
    final expensePattern = RegExp(
      r'\b(paid|debited|sent|payment\s+of|payment\s+to|payment\s+for|transferred|purchase|charged|spent|withdrawn)\b',
      caseSensitive: false,
    );
    if (expensePattern.hasMatch(lower)) {
      return 'expense';
    }

    return 'expense';
  }

  /// Determines whether [text] represents a valid transaction notification.
  ///
  /// Filters out:
  /// - OTPs / verification codes
  /// - Promotional offers, coupons, and discounts
  /// - Balance-only notifications without debit/credit actions
  /// - App ads and marketing text
  static bool _isValidTransaction(String text) {
    if (text.trim().isEmpty) return false;

    // 1. Filter out OTPs
    final otpPattern = RegExp(
      r'\b(otp|one[-\s]time\s+password|verification\s+code|secret\s+code|auth(?:entication)?\s+code)\b',
      caseSensitive: false,
    );
    if (otpPattern.hasMatch(text)) return false;

    // 2. Filter out Promos / Discounts
    final promoPattern = RegExp(
      r'\b(cashback\s+offer|discount\s+code|coupon\s+code|promo\s+code|%\s*off|flat\s+\d+\s+off|win\s+up\s+to|scratch\s+card|limited\s+period\s+offer|festive\s+offer|special\s+offer|exclusive\s+offer)\b',
      caseSensitive: false,
    );
    if (promoPattern.hasMatch(text)) return false;

    // Check standalone 'offer' / 'offers' if it is promotional
    final generalOfferPattern = RegExp(
      r'\b(offers?|use\s+coupon|use\s+code)\b',
      caseSensitive: false,
    );
    if (generalOfferPattern.hasMatch(text)) {
      final isPaymentAction = RegExp(
        r'\b(?:paid|debited|credited|received)\b',
        caseSensitive: false,
      ).hasMatch(text);
      final isPromoStyle = RegExp(
        r'\b(?:claim|grab|avail|win|congrats|hurry|code|valid\s+till|chance\s+to)\b',
        caseSensitive: false,
      ).hasMatch(text);
      if (isPromoStyle || !isPaymentAction) {
        return false;
      }
    }

    // 3. Filter out Ads / App installation prompts
    final adPattern = RegExp(
      r'\b(download|install|upgrade|subscribe\s+now|apply\s+now|click\s+here\s+to)\b',
      caseSensitive: false,
    );
    if (adPattern.hasMatch(text)) return false;

    // 4. Filter out Balance-only notifications (without debit/credit/payment actions)
    final balancePattern = RegExp(
      r'\b(avail(?:able)?\s+bal(?:ance)?|bal(?:ance)?|a\/c\s+bal)\b',
      caseSensitive: false,
    );
    final actionPattern = RegExp(
      r'\b(debited|credited|paid|received|sent|payment|transferred|recharge|purchase|charged|spent|refund|refunded|cashback|reward|failed|declined|reversed|unsuccessful|withdrawn)\b',
      caseSensitive: false,
    );
    if (balancePattern.hasMatch(text) && !actionPattern.hasMatch(text)) {
      return false;
    }

    // 5. Must have some transaction indicator or currency indicator
    final currencyPattern = RegExp(r'(?:₹|Rs\.?|INR)', caseSensitive: false);
    if (!actionPattern.hasMatch(text) && !currencyPattern.hasMatch(text)) {
      return false;
    }

    return true;
  }
}
