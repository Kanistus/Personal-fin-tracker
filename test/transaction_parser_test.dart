import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/services/transaction_parser.dart';

void main() {
  group('TransactionParser - Amount Extraction', () {
    test('parses ₹250, ₹1,250, ₹1,250.00, ₹ 250', () {
      expect(
        TransactionParser.parse('Paid ₹250 to Store').amount,
        equals(250.0),
      );
      expect(
        TransactionParser.parse('Paid ₹1,250 to Store').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('Paid ₹1,250.00 to Store').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('Paid ₹ 250 to Store').amount,
        equals(250.0),
      );
    });

    test('parses Rs.250, Rs. 1,250, Rs 250.00, Rs250', () {
      expect(
        TransactionParser.parse('Paid Rs.250 to Store').amount,
        equals(250.0),
      );
      expect(
        TransactionParser.parse('Paid Rs. 1,250 to Store').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('Paid Rs 250.00 to Store').amount,
        equals(250.0),
      );
      expect(
        TransactionParser.parse('Rs250 paid to Store').amount,
        equals(250.0),
      );
    });

    test('parses INR 250, INR 1,250.00, inr 250', () {
      expect(
        TransactionParser.parse('INR 250 debited from A/c XX1234').amount,
        equals(250.0),
      );
      expect(
        TransactionParser.parse('INR 1,250.00 debited from A/c XX1234').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('inr 250 debited from account').amount,
        equals(250.0),
      );
    });

    test('parses bare amount with context (e.g., 1,250.00)', () {
      expect(
        TransactionParser.parse('Payment of 1,250.00 to Merchant successful').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('debited by 1,250.00 for purchase').amount,
        equals(1250.0),
      );
      expect(
        TransactionParser.parse('credited with 500.00 from Friend').amount,
        equals(500.0),
      );
    });

    test('handles commas in Indian numbering (1,00,000 = 100000)', () {
      expect(
        TransactionParser.parse('debited by ₹1,00,000 on 22-Oct').amount,
        equals(100000.0),
      );
      expect(
        TransactionParser.parse('Payment of ₹10,50,000.50 to Dealer').amount,
        equals(1050000.50),
      );
      expect(
        TransactionParser.parse('Credited with INR 1,00,00,000.00').amount,
        equals(10000000.0),
      );
    });

    test('ignores balance amount when transaction amount is present', () {
      final res = TransactionParser.parse(
        'INR 1,500.00 debited from A/c XX1234. Avail Bal: INR 25,430.50',
      );
      expect(res.amount, equals(1500.0));
      expect(res.isValid, isTrue);
    });
  });

  group('TransactionParser - Transaction Type Detection', () {
    test('detects expense for paid, debited, sent, payment of, purchase, charged', () {
      expect(
        TransactionParser.parse('Paid ₹250 to Cafe').transactionType,
        equals('expense'),
      );
      expect(
        TransactionParser.parse('₹500 debited from account').transactionType,
        equals('expense'),
      );
      expect(
        TransactionParser.parse('Money sent to Rahul: ₹300').transactionType,
        equals('expense'),
      );
      expect(
        TransactionParser.parse('Payment of ₹1,000 to Store').transactionType,
        equals('expense'),
      );
      expect(
        TransactionParser.parse('₹750 purchase at Mall').transactionType,
        equals('expense'),
      );
      expect(
        TransactionParser.parse('Charged ₹99 for service').transactionType,
        equals('expense'),
      );
    });

    test('detects income for received, credited, cashback, reward', () {
      expect(
        TransactionParser.parse('Received ₹1,000 from Rohit').transactionType,
        equals('income'),
      );
      expect(
        TransactionParser.parse('A/c XX1234 credited with INR 5,000.00').transactionType,
        equals('income'),
      );
      expect(
        TransactionParser.parse('Cashback of ₹50 credited').transactionType,
        equals('income'),
      );
      expect(
        TransactionParser.parse('Reward of ₹25 added to wallet').transactionType,
        equals('income'),
      );
    });

    test('detects transfer for self-transfer, transferred to your, own account', () {
      expect(
        TransactionParser.parse('Self-transfer of ₹2,000 completed').transactionType,
        equals('transfer'),
      );
      expect(
        TransactionParser.parse('Transferred ₹5,000 to your own account').transactionType,
        equals('transfer'),
      );
      expect(
        TransactionParser.parse('Transfer of ₹1,500 to own account successful').transactionType,
        equals('transfer'),
      );
    });

    test('detects refund for refund, refunded', () {
      expect(
        TransactionParser.parse('Refund of ₹350 from Swiggy credited').transactionType,
        equals('refund'),
      );
      expect(
        TransactionParser.parse('₹1,200 refunded for order #123').transactionType,
        equals('refund'),
      );
    });

    test('detects failed for failed, declined, reversed, unsuccessful', () {
      expect(
        TransactionParser.parse('Payment of ₹500 to Merchant failed').transactionType,
        equals('failed'),
      );
      expect(
        TransactionParser.parse('Transaction of ₹750 declined by bank').transactionType,
        equals('failed'),
      );
      expect(
        TransactionParser.parse('Payment of ₹200 reversed').transactionType,
        equals('failed'),
      );
      expect(
        TransactionParser.parse('Transfer of ₹1,000 was unsuccessful').transactionType,
        equals('failed'),
      );
    });
  });

  group('TransactionParser - Merchant Extraction', () {
    test('extracts text after to, at, from, for', () {
      expect(
        TransactionParser.parse('Paid ₹250 to Store Name').merchant,
        equals('Store Name'),
      );
      expect(
        TransactionParser.parse('Payment of ₹500 to Merchant successful').merchant,
        equals('Merchant'),
      );
      expect(
        TransactionParser.parse('Paid ₹1,200 at D-Mart').merchant,
        equals('D-Mart'),
      );
      expect(
        TransactionParser.parse('Received ₹1,000 from John Doe').merchant,
        equals('John Doe'),
      );
      expect(
        TransactionParser.parse('Paid ₹150 for Uber trip').merchant,
        equals('Uber'),
      );
    });

    test('removes UPI IDs (xxx@ybl) and extra whitespace', () {
      final res1 = TransactionParser.parse('Paid ₹300 to Priya Sharma (priya@oksbi) via UPI');
      expect(res1.merchant, equals('Priya Sharma'));

      final res2 = TransactionParser.parse('Payment of ₹450 to rahul@okaxis successful');
      expect(res2.merchant, equals('Rahul'));
    });

    test('capitalizes properly and keeps acronyms', () {
      expect(
        TransactionParser.parse('Paid ₹250 to reliance fresh').merchant,
        equals('Reliance Fresh'),
      );
      expect(
        TransactionParser.parse('Paid ₹500 to KFC').merchant,
        equals('KFC'),
      );
      expect(
        TransactionParser.parse('Paid ₹350 to PVR cinemas').merchant,
        equals('PVR Cinemas'),
      );
      expect(
        TransactionParser.parse('Paid ₹1,200 to d-mart').merchant,
        equals('D-Mart'),
      );
    });

    test('returns null for account numbers and self-transfers instead of guessing', () {
      expect(
        TransactionParser.parse('INR 1,500.00 debited from A/c XX1234').merchant,
        isNull,
      );
      expect(
        TransactionParser.parse('Transferred ₹5,000 to your own account').merchant,
        isNull,
      );
    });
  });

  group('TransactionParser - UPI Reference Extraction', () {
    test('extracts UPI Ref, Txn ID, Ref No, Transaction ID, UPI:', () {
      expect(
        TransactionParser.parse('Paid ₹250 to Cafe. UPI Ref: 123456789012').upiRef,
        equals('123456789012'),
      );
      expect(
        TransactionParser.parse('Payment of ₹500. Txn ID: T231022123456').upiRef,
        equals('T231022123456'),
      );
      expect(
        TransactionParser.parse('Sent ₹1,000. Ref No: 987654321').upiRef,
        equals('987654321'),
      );
      expect(
        TransactionParser.parse('Debited ₹300. Transaction ID: 429381293812').upiRef,
        equals('429381293812'),
      );
      expect(
        TransactionParser.parse('Credited ₹50. UPI: 1234567890').upiRef,
        equals('1234567890'),
      );
      expect(
        TransactionParser.parse('Paid ₹100. RRN: 998877665544').upiRef,
        equals('998877665544'),
      );
    });

    test('returns null when no reference is present', () {
      expect(
        TransactionParser.parse('Paid ₹250 to Store Name').upiRef,
        isNull,
      );
    });
  });

  group('TransactionParser - Filter Out Non-Transactions', () {
    test('filters out OTPs', () {
      final res1 = TransactionParser.parse('Your OTP is 123456 for payment of ₹500');
      expect(res1.isValid, isFalse);

      final res2 = TransactionParser.parse('Your one-time password for ₹1,000 transaction is 987654');
      expect(res2.isValid, isFalse);

      final res3 = TransactionParser.parse('Verification code: 456789 for transaction of INR 200');
      expect(res3.isValid, isFalse);
    });

    test('filters out promos and discounts', () {
      final res1 = TransactionParser.parse('Special cashback offer! Win up to ₹500 on your next recharge');
      expect(res1.isValid, isFalse);

      final res2 = TransactionParser.parse('Use discount code SAVE50 to get ₹50 off on order');
      expect(res2.isValid, isFalse);

      final res3 = TransactionParser.parse('Get 50% off on all items today! Shop now');
      expect(res3.isValid, isFalse);
    });

    test('filters out balance only notifications', () {
      final res1 = TransactionParser.parse('Your account balance is ₹5,420.00');
      expect(res1.isValid, isFalse);

      final res2 = TransactionParser.parse('Available balance in A/c XX1234: INR 10,000');
      expect(res2.isValid, isFalse);

      final res3 = TransactionParser.parse('Avail Bal: Rs 1,200.00 in your account');
      expect(res3.isValid, isFalse);
    });

    test('filters out ads and marketing', () {
      final res1 = TransactionParser.parse('Download the app now and get ₹100 bonus');
      expect(res1.isValid, isFalse);

      final res2 = TransactionParser.parse('Install PhonePe to win ₹50 cashback');
      expect(res2.isValid, isFalse);

      final res3 = TransactionParser.parse('Upgrade to premium today for ₹99/month! Subscribe now');
      expect(res3.isValid, isFalse);
    });
  });

  group('TransactionParser - Specific App Formats', () {
    test('Google Pay format: "Paid ₹250 to Store Name"', () {
      final res = TransactionParser.parse(
        'Paid ₹250 to Store Name',
        TransactionParser.googlePayPackage,
      );
      expect(res.amount, equals(250.0));
      expect(res.merchant, equals('Store Name'));
      expect(res.transactionType, equals('expense'));
      expect(res.isValid, isTrue);
      expect(res.sourceApp, equals(TransactionParser.googlePayPackage));
    });

    test('PhonePe format: "Payment of ₹500 to Merchant successful"', () {
      final res = TransactionParser.parse(
        'Payment of ₹500 to Merchant successful',
        TransactionParser.phonePePackage,
      );
      expect(res.amount, equals(500.0));
      expect(res.merchant, equals('Merchant'));
      expect(res.transactionType, equals('expense'));
      expect(res.isValid, isTrue);
      expect(res.sourceApp, equals(TransactionParser.phonePePackage));
    });

    test('Paytm format: "₹200 paid to XYZ"', () {
      final res = TransactionParser.parse(
        '₹200 paid to XYZ',
        TransactionParser.paytmPackage,
      );
      expect(res.amount, equals(200.0));
      expect(res.merchant, equals('XYZ'));
      expect(res.transactionType, equals('expense'));
      expect(res.isValid, isTrue);
      expect(res.sourceApp, equals(TransactionParser.paytmPackage));
    });

    test('Bank apps format: "INR 1,500.00 debited from A/c XX1234"', () {
      final res = TransactionParser.parse(
        'INR 1,500.00 debited from A/c XX1234',
        'com.csam.icici.bank.imobile',
      );
      expect(res.amount, equals(1500.0));
      expect(res.merchant, isNull);
      expect(res.transactionType, equals('expense'));
      expect(res.isValid, isTrue);
    });

    test('Bank app with merchant: "INR 1,500.00 debited from A/c XX1234 at Amazon"', () {
      final res = TransactionParser.parse(
        'INR 1,500.00 debited from A/c XX1234 at Amazon',
        'com.sbi.SBIFreedomPlus',
      );
      expect(res.amount, equals(1500.0));
      expect(res.merchant, equals('Amazon'));
      expect(res.transactionType, equals('expense'));
      expect(res.isValid, isTrue);
    });
  });

  group('ParsedTransaction Model Serialization', () {
    test('toMap and fromMap work correctly', () {
      const original = ParsedTransaction(
        amount: 350.0,
        merchant: 'Swiggy',
        upiRef: '123456789012',
        transactionType: 'expense',
        isValid: true,
        rawText: 'Paid ₹350 to Swiggy. UPI Ref: 123456789012',
        sourceApp: 'com.phonepe.app',
      );

      final map = original.toMap();
      expect(map['amount'], equals(350.0));
      expect(map['merchant'], equals('Swiggy'));
      expect(map['upiRef'], equals('123456789012'));
      expect(map['transactionType'], equals('expense'));
      expect(map['isValid'], equals(1));
      expect(map['sourceApp'], equals('com.phonepe.app'));

      final restored = ParsedTransaction.fromMap(map);
      expect(restored, equals(original));
    });

    test('copyWith works correctly', () {
      const original = ParsedTransaction(
        amount: 200.0,
        merchant: 'Zomato',
        isValid: true,
        rawText: 'Paid ₹200 to Zomato',
      );

      final updated = original.copyWith(amount: 250.0, transactionType: 'refund');
      expect(updated.amount, equals(250.0));
      expect(updated.merchant, equals('Zomato'));
      expect(updated.transactionType, equals('refund'));
      expect(updated.isValid, isTrue);
    });
  });
}
