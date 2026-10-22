import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/models/auto_transaction.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/services/duplicate_detector.dart';

void main() {
  group('DuplicateCheckResult Tests', () {
    test('Default noMatch factory', () {
      final result = DuplicateCheckResult.noMatch();
      expect(result.isDuplicate, isFalse);
      expect(result.isPossibleDuplicate, isFalse);
      expect(result.hasMatch, isFalse);
      expect(result.needsReview, isFalse);
      expect(result.existingAutoTransactionId, isNull);
      expect(result.existingTransactionId, isNull);
      expect(result.reason, equals('no_match'));
      expect(result.matchScore, equals(0.0));
    });

    test('toMap and fromMap serialization', () {
      const result = DuplicateCheckResult(
        isDuplicate: true,
        isPossibleDuplicate: false,
        existingAutoTransactionId: 42,
        existingTransactionId: 10,
        reason: 'exact_upi_ref',
        matchScore: 1.0,
      );

      final map = result.toMap();
      expect(map['isDuplicate'], isTrue);
      expect(map['isPossibleDuplicate'], isFalse);
      expect(map['existingAutoTransactionId'], equals(42));
      expect(map['existingTransactionId'], equals(10));
      expect(map['reason'], equals('exact_upi_ref'));
      expect(map['matchScore'], equals(1.0));

      final restored = DuplicateCheckResult.fromMap(map);
      expect(restored, equals(result));
    });

    test('copyWith updates properties', () {
      final base = DuplicateCheckResult.noMatch();
      final updated = base.copyWith(
        isDuplicate: true,
        matchScore: 0.95,
        reason: 'same_amount_merchant_time',
      );
      expect(updated.isDuplicate, isTrue);
      expect(updated.matchScore, equals(0.95));
      expect(updated.reason, equals('same_amount_merchant_time'));
      expect(updated.hasMatch, isTrue);
    });
  });

  group('Merchant Normalization and Similarity Tests', () {
    test('Normalizes merchant with legal noise words and punctuation', () {
      expect(
        DuplicateDetector.normalizeMerchant('Swiggy Pvt. Ltd.'),
        equals('swiggy'),
      );
      expect(
        DuplicateDetector.normalizeMerchant("McDonald's"),
        equals('mcdonalds'),
      );
      expect(
        DuplicateDetector.normalizeMerchant('  ZOMATO   PRIVATE   LIMITED  '),
        equals('zomato'),
      );
      expect(
        DuplicateDetector.normalizeMerchant('Chai-Point'),
        equals('chai point'),
      );
    });

    test('Levenshtein merchant similarity', () {
      // Identical
      expect(
        DuplicateDetector.merchantSimilarity('Swiggy', 'Swiggy'),
        equals(1.0),
      );
      expect(
        DuplicateDetector.merchantSimilarity('Swiggy', 'swiggy'),
        equals(1.0),
      );
      expect(
        DuplicateDetector.merchantSimilarity('Swiggy Pvt Ltd', 'Swiggy'),
        equals(1.0),
      );

      // Minor typo / high similarity (>0.70)
      final typoSimilarity =
          DuplicateDetector.merchantSimilarity('Swiggy', 'Swigy');
      expect(typoSimilarity, greaterThan(0.70));

      final zomatoSimilarity =
          DuplicateDetector.merchantSimilarity('Zomato', 'Zomatto');
      expect(zomatoSimilarity, greaterThan(0.70));

      // Completely different (0.0 or low)
      expect(
        DuplicateDetector.merchantSimilarity('Amazon', 'Netflix'),
        lessThan(0.3),
      );
    });
  });

  group('Rule 1: Exact UPI Reference Match Tests', () {
    test('Matches exact UPI ref with 1.0 confidence score', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 250.0,
        merchant: 'Unknown Merchant',
        sourceApp: 'com.google.android.apps.nbu.paisa.user',
        upiRef: 'UPI123456789012',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 500.0, // Different amount
        merchant: 'Different Merchant',
        sourceApp: 'net.one97.paytm',
        upiRef: 'upi123456789012', // Case-insensitive match
        date: baseDate.add(const Duration(hours: 1)),
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isTrue);
      expect(result.isPossibleDuplicate, isFalse);
      expect(result.reason, equals('exact_upi_ref'));
      expect(result.matchScore, equals(1.0));
      expect(result.existingAutoTransactionId, equals(1));
    });
  });

  group('Rule 2: Exact Match Tests (Same amount, merchant, within 2 min)', () {
    test('Matches same amount, normalized merchant, within 2 minutes', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 350.0,
        merchant: 'Swiggy',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 350.0,
        merchant: 'SWIGGY PVT LTD',
        sourceApp: 'com.google.android.apps.nbu.paisa.user',
        date: baseDate.subtract(const Duration(seconds: 90)), // 1.5 min earlier
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isTrue);
      expect(result.isPossibleDuplicate, isFalse);
      expect(result.reason, equals('same_amount_merchant_time'));
      expect(result.matchScore, equals(0.95));
      expect(result.existingAutoTransactionId, equals(1));
    });
  });

  group('Rule 3: Near Match Tests (Same amount, similar merchant, within 5 min)', () {
    test('Matches similar merchant within 5 minutes as possible duplicate', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 450.0,
        merchant: 'Swiggy',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 450.0,
        merchant: 'Swigy', // Typo, > 70% similarity
        sourceApp: 'net.one97.paytm',
        date: baseDate.subtract(const Duration(minutes: 3)), // 3 min earlier
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isFalse);
      expect(result.isPossibleDuplicate, isTrue);
      expect(result.reason, equals('possible_match'));
      expect(result.matchScore, greaterThanOrEqualTo(0.7));
      expect(result.matchScore, lessThanOrEqualTo(0.9));
      expect(result.existingAutoTransactionId, equals(1));
    });

    test('Same merchant beyond 2 minutes but within 5 minutes triggers Rule 3', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 450.0,
        merchant: 'Swiggy',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 450.0,
        merchant: 'Swiggy',
        sourceApp: 'net.one97.paytm',
        date: baseDate.subtract(const Duration(minutes: 3)), // 3 minutes apart
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isFalse);
      expect(result.isPossibleDuplicate, isTrue);
      expect(result.reason, equals('possible_match'));
      expect(result.matchScore, equals(0.90));
      expect(result.existingAutoTransactionId, equals(1));
    });
  });

  group('Rule 4: Amount + Time Match Tests (Same amount & app, within 1 min)', () {
    test('Matches same amount & app within 1 minute even if merchant differs', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 1200.0,
        merchant: 'Notification A',
        sourceApp: 'com.google.android.apps.nbu.paisa.user',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 1200.0,
        merchant: 'Completely Different Store',
        sourceApp: 'com.google.android.apps.nbu.paisa.user',
        date: baseDate.subtract(const Duration(seconds: 40)), // 40 seconds apart
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isFalse);
      expect(result.isPossibleDuplicate, isTrue);
      expect(result.reason, equals('possible_match'));
      expect(result.matchScore, equals(0.5));
      expect(result.existingAutoTransactionId, equals(1));
    });
  });

  group('Rule 5: No Match Tests', () {
    test('Returns noMatch when no criteria are met', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 2,
        amount: 100.0,
        merchant: 'Book Store',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final existingTxn = AutoTransaction(
        id: 1,
        amount: 2500.0,
        merchant: 'Flight Tickets',
        sourceApp: 'net.one97.paytm',
        date: baseDate.subtract(const Duration(days: 2)),
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        newTxn,
        [existingTxn],
      );

      expect(result.isDuplicate, isFalse);
      expect(result.isPossibleDuplicate, isFalse);
      expect(result.reason, equals('no_match'));
      expect(result.matchScore, equals(0.0));
      expect(result.existingAutoTransactionId, isNull);
    });

    test('Does not match a transaction with itself', () {
      final txn = AutoTransaction(
        id: 1,
        amount: 100.0,
        merchant: 'Book Store',
        sourceApp: 'com.phonepe.app',
        upiRef: 'UPI123456789012',
        date: DateTime.now(),
      );

      final result = DuplicateDetector.checkAgainstAutoTransactions(
        txn,
        [txn],
      );

      expect(result.isDuplicate, isFalse);
      expect(result.hasMatch, isFalse);
    });
  });

  group('Manual Transaction Duplicate Checking Tests', () {
    test('Matches manual transaction by exact merchant and time within 2 min', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final autoTxn = AutoTransaction(
        id: 10,
        amount: 250.0,
        merchant: 'Chai Point',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final manualTxn = Transaction(
        id: 5,
        title: 'Chai Point',
        amount: 250.0,
        isIncome: false,
        category: 'Food',
        date: baseDate.subtract(const Duration(seconds: 45)),
      );

      final result = DuplicateDetector.checkAgainstTransactions(
        autoTxn,
        [manualTxn],
      );

      expect(result.isDuplicate, isTrue);
      expect(result.reason, equals('same_amount_merchant_time'));
      expect(result.matchScore, equals(0.95));
      expect(result.existingTransactionId, equals(5));
      expect(result.existingAutoTransactionId, isNull);
    });

    test('Matches manual transaction containing UPI reference in title', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final autoTxn = AutoTransaction(
        id: 10,
        amount: 250.0,
        merchant: 'Chai Point',
        upiRef: 'UPI987654321000',
        sourceApp: 'com.phonepe.app',
        date: baseDate,
      );

      final manualTxn = Transaction(
        id: 8,
        title: 'Payment UPI987654321000',
        amount: 250.0,
        isIncome: false,
        category: 'Food',
        date: baseDate.subtract(const Duration(hours: 1)),
      );

      final result = DuplicateDetector.checkAgainstTransactions(
        autoTxn,
        [manualTxn],
      );

      expect(result.isDuplicate, isTrue);
      expect(result.reason, equals('exact_upi_ref'));
      expect(result.matchScore, equals(1.0));
      expect(result.existingTransactionId, equals(8));
    });
  });

  group('checkAll Combined Tests', () {
    test('Selects highest confidence match and sets both IDs if applicable', () {
      final baseDate = DateTime(2026, 10, 22, 14, 0, 0);

      final newTxn = AutoTransaction(
        id: 20,
        amount: 500.0,
        merchant: 'Zomato',
        upiRef: 'UPI112233445566',
        sourceApp: 'com.google.android.apps.nbu.paisa.user',
        date: baseDate,
      );

      final existingAuto = AutoTransaction(
        id: 15,
        amount: 500.0,
        merchant: 'Zomato',
        upiRef: 'UPI112233445566', // Rule 1 (1.0)
        sourceApp: 'net.one97.paytm',
        date: baseDate.subtract(const Duration(minutes: 10)),
      );

      final existingManual = Transaction(
        id: 9,
        title: 'Zomato',
        amount: 500.0,
        isIncome: false,
        category: 'Food',
        date: baseDate.subtract(const Duration(seconds: 30)), // Rule 2 (0.95)
      );

      final result = DuplicateDetector.checkAll(
        newTxn: newTxn,
        autoTransactions: [existingAuto],
        manualTransactions: [existingManual],
      );

      expect(result.isDuplicate, isTrue);
      expect(result.matchScore, equals(1.0));
      expect(result.reason, equals('exact_upi_ref'));
      expect(result.existingAutoTransactionId, equals(15));
      expect(result.existingTransactionId, equals(9));
    });
  });

  group('generateDuplicateGroupId Tests', () {
    test('Generates group ID matching expected format and uniqueness', () {
      final id1 = DuplicateDetector.generateDuplicateGroupId();
      final id2 = DuplicateDetector.generateDuplicateGroupId();

      expect(id1.startsWith('dup_'), isTrue);
      expect(id2.startsWith('dup_'), isTrue);
      expect(id1, isNot(equals(id2)));
    });
  });
}
