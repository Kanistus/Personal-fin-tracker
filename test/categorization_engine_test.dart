import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/models/merchant_rule.dart';
import 'package:personal_fin/services/categorization_engine.dart';

void main() {
  group('CategorizationEngine - Categories & Constants', () {
    test('allCategories contains exactly 24 categories', () {
      expect(CategorizationEngine.allCategories.length, equals(24));
      expect(CategorizationEngine.allCategories, contains('Food & Dining'));
      expect(CategorizationEngine.allCategories, contains('Groceries'));
      expect(CategorizationEngine.allCategories, contains('Transportation'));
      expect(CategorizationEngine.allCategories, contains('Fuel'));
      expect(CategorizationEngine.allCategories, contains('Shopping'));
      expect(CategorizationEngine.allCategories, contains('Medical & Healthcare'));
      expect(CategorizationEngine.allCategories, contains('Rent'));
      expect(CategorizationEngine.allCategories, contains('Electricity & Utilities'));
      expect(CategorizationEngine.allCategories, contains('Mobile & Internet'));
      expect(CategorizationEngine.allCategories, contains('Education'));
      expect(CategorizationEngine.allCategories, contains('Entertainment'));
      expect(CategorizationEngine.allCategories, contains('Travel'));
      expect(CategorizationEngine.allCategories, contains('Family'));
      expect(CategorizationEngine.allCategories, contains('Insurance'));
      expect(CategorizationEngine.allCategories, contains('Loan Repayment'));
      expect(CategorizationEngine.allCategories, contains('Gold Loan Interest'));
      expect(CategorizationEngine.allCategories, contains('EMI'));
      expect(CategorizationEngine.allCategories, contains('Subscriptions'));
      expect(CategorizationEngine.allCategories, contains('Personal Care'));
      expect(CategorizationEngine.allCategories, contains('Business Expenses'));
      expect(CategorizationEngine.allCategories, contains('Investments'));
      expect(CategorizationEngine.allCategories, contains('Transfers'));
      expect(CategorizationEngine.allCategories, contains('Cash Withdrawal'));
      expect(CategorizationEngine.allCategories, contains('Other'));
    });

    test('isValidCategory returns true for valid categories', () {
      expect(CategorizationEngine.isValidCategory('Food & Dining'), isTrue);
      expect(CategorizationEngine.isValidCategory('Invalid Category'), isFalse);
    });

    test('getKeywordsForCategory returns keyword list', () {
      final foodKeywords =
          CategorizationEngine.getKeywordsForCategory('Food & Dining');
      expect(foodKeywords, contains('swiggy'));
      expect(foodKeywords, contains('zomato'));
      expect(CategorizationEngine.getKeywordsForCategory('Unknown'), isEmpty);
    });
  });

  group('CategorizationEngine - Normalization', () {
    test('normalizes merchant names correctly', () {
      expect(CategorizationEngine.normalizeMerchant('  Swiggy!  '), equals('swiggy'));
      expect(CategorizationEngine.normalizeMerchant("McDonald's"), equals('mcdonalds'));
      expect(CategorizationEngine.normalizeMerchant("H&M Store"), equals('h m store'));
      expect(
        CategorizationEngine.normalizeMerchant('Tata-Power - Mumbai'),
        equals('tata power mumbai'),
      );
      expect(CategorizationEngine.normalizeMerchant(''), equals(''));
      expect(CategorizationEngine.normalizeMerchant('   '), equals(''));
      expect(CategorizationEngine.normalizeMerchant('---'), equals(''));
    });
  });

  group('CategorizationEngine - Layer 1: Merchant Rules', () {
    test('matches user-defined merchant rules with high confidence', () {
      final rules = [
        MerchantRule(
          merchantPattern: 'Corner House',
          category: 'Food & Dining',
        ),
        MerchantRule(
          merchantPattern: 'Amazon Fresh',
          category: 'Groceries',
        ),
      ];

      final res1 = CategorizationEngine.categorize(
        merchant: 'Corner House Ice Cream',
        transactionType: 'expense',
        merchantRules: rules,
      );
      expect(res1.category, equals('Food & Dining'));
      expect(res1.confidence, equals('high'));
      expect(res1.reason, equals('merchant_rule'));
      expect(res1.isHighConfidence, isTrue);

      final res2 = CategorizationEngine.categorize(
        merchant: 'Amazon Fresh Order',
        transactionType: 'expense',
        merchantRules: rules,
      );
      expect(res2.category, equals('Groceries'));
      expect(res2.confidence, equals('high'));
      expect(res2.reason, equals('merchant_rule'));
    });

    test('merchant rules take precedence over keyword matching', () {
      final customRule = MerchantRule(
        merchantPattern: 'Swiggy',
        category: 'Groceries',
      );

      final result = CategorizationEngine.categorize(
        merchant: 'Swiggy',
        transactionType: 'expense',
        merchantRules: [customRule],
      );

      expect(result.category, equals('Groceries'));
      expect(result.confidence, equals('high'));
      expect(result.reason, equals('merchant_rule'));
    });

    test('prefers matching transactionType when multiple rules match', () {
      final rules = [
        MerchantRule(
          merchantPattern: 'HDFC',
          category: 'Investments',
          transactionType: 'expense',
        ),
        MerchantRule(
          merchantPattern: 'HDFC',
          category: 'Transfers',
          transactionType: 'transfer',
        ),
      ];

      final resTransfer = CategorizationEngine.categorize(
        merchant: 'HDFC Bank',
        transactionType: 'transfer',
        merchantRules: rules,
      );
      expect(resTransfer.category, equals('Transfers'));
      expect(resTransfer.confidence, equals('high'));

      final resExpense = CategorizationEngine.categorize(
        merchant: 'HDFC Bank',
        transactionType: 'expense',
        merchantRules: rules,
      );
      expect(resExpense.category, equals('Investments'));
      expect(resExpense.confidence, equals('high'));
    });
  });

  group('CategorizationEngine - Layer 2: Keyword Matching', () {
    test('matches Indian merchants and services with medium confidence', () {
      final cases = <String, String>{
        'Swiggy': 'Food & Dining',
        'Zomato': 'Food & Dining',
        'Blinkit': 'Groceries',
        'BigBasket': 'Groceries',
        'Uber Trip': 'Transportation',
        'Ola Cabs': 'Transportation',
        'HP Petrol Pump': 'Fuel',
        'Indian Oil': 'Fuel',
        'Amazon': 'Shopping',
        'Flipkart': 'Shopping',
        'Apollo Pharmacy': 'Medical & Healthcare',
        'House Rent': 'Rent',
        'Bescom Electricity': 'Electricity & Utilities',
        'Airtel Recharge': 'Mobile & Internet',
        'Udemy': 'Education',
        'PVR Cinemas': 'Entertainment',
        'MakeMyTrip Flight': 'Travel',
        'LIC Premium': 'Insurance',
        'Home Loan': 'Loan Repayment',
        'Muthoot Gold Loan': 'Gold Loan Interest',
        'Bajaj Finserv': 'EMI',
        'Cult.fit': 'Personal Care',
        'Blue Dart Courier': 'Business Expenses',
        'Zerodha': 'Investments',
      };

      for (final entry in cases.entries) {
        final result = CategorizationEngine.categorize(
          merchant: entry.key,
          transactionType: 'expense',
        );
        expect(
          result.category,
          equals(entry.value),
          reason: 'Failed for merchant: ${entry.key}',
        );
        expect(result.confidence, equals('medium'));
        expect(result.reason, equals('keyword_match'));
        expect(result.isMediumConfidence, isTrue);
      }
    });

    test('longest keyword wins when multiple matches occur', () {
      final res = CategorizationEngine.categorize(
        merchant: 'Swiggy Instamart Order',
        transactionType: 'expense',
      );
      expect(res.category, equals('Groceries'));
      expect(res.confidence, equals('medium'));
      expect(res.reason, equals('keyword_match'));
    });

    test('word boundary prevents false substring matches', () {
      // 'public' should not match 'lic' (Insurance)
      final res1 = CategorizationEngine.categorize(
        merchant: 'Public Library',
        transactionType: 'expense',
      );
      expect(res1.category, isNot(equals('Insurance')));

      // 'automation' should not match 'auto' (Transportation)
      final res2 = CategorizationEngine.categorize(
        merchant: 'Automation Solutions',
        transactionType: 'expense',
      );
      expect(res2.category, isNot(equals('Transportation')));
    });

    test('falls back to description when merchant has no keyword', () {
      final res = CategorizationEngine.categorize(
        merchant: 'UPI-987654321',
        transactionType: 'expense',
        description: 'Dinner at Barbeque Nation',
      );
      expect(res.category, equals('Food & Dining'));
      expect(res.confidence, equals('medium'));
      expect(res.reason, equals('keyword_match'));
    });
  });

  group('CategorizationEngine - Layer 3: Transaction Type Fallback', () {
    test('falls back to Transfers for transfer type', () {
      final res = CategorizationEngine.categorize(
        merchant: 'Unknown Recipient',
        transactionType: 'transfer',
      );
      expect(res.category, equals('Transfers'));
      expect(res.confidence, equals('medium'));
      expect(res.reason, equals('transaction_type'));
    });

    test('falls back to Cash Withdrawal for withdrawal type', () {
      final res = CategorizationEngine.categorize(
        merchant: 'Unknown Cash Dispenser',
        transactionType: 'withdrawal',
      );
      expect(res.category, equals('Cash Withdrawal'));
      expect(res.confidence, equals('medium'));
      expect(res.reason, equals('transaction_type'));
    });

    test('falls back to Other with low confidence for refund type', () {
      final res = CategorizationEngine.categorize(
        merchant: 'Unknown Gateway',
        transactionType: 'refund',
      );
      expect(res.category, equals('Other'));
      expect(res.confidence, equals('low'));
      expect(res.reason, equals('transaction_type'));
      expect(res.isLowConfidence, isTrue);
    });

    test('defaults to Other with low confidence and no_match reason', () {
      final res = CategorizationEngine.categorize(
        merchant: 'Completely Unrecognized Merchant XYZ 123',
        transactionType: 'expense',
      );
      expect(res.category, equals('Other'));
      expect(res.confidence, equals('low'));
      expect(res.reason, equals('no_match'));
      expect(res.isLowConfidence, isTrue);
    });
  });

  group('CategorizationResult - Serialization & Equality', () {
    test('toMap and fromMap work symmetrically', () {
      const original = CategorizationResult(
        category: 'Food & Dining',
        confidence: 'high',
        reason: 'merchant_rule',
      );

      final map = original.toMap();
      expect(map['category'], equals('Food & Dining'));
      expect(map['confidence'], equals('high'));
      expect(map['reason'], equals('merchant_rule'));

      final restored = CategorizationResult.fromMap(map);
      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(
        restored.toString(),
        equals('CategorizationResult(category: Food & Dining, confidence: high, reason: merchant_rule)'),
      );
    });

    test('copyWith updates specified fields', () {
      const original = CategorizationResult(
        category: 'Other',
        confidence: 'low',
        reason: 'no_match',
      );

      final updated = original.copyWith(
        category: 'Shopping',
        confidence: 'medium',
      );

      expect(updated.category, equals('Shopping'));
      expect(updated.confidence, equals('medium'));
      expect(updated.reason, equals('no_match'));
    });
  });
}
