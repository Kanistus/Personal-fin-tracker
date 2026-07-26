import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:personal_fin/models/budget.dart';
import 'package:personal_fin/models/debt.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction toMap and fromMap serialization', () {
      final now = DateTime(2026, 7, 25, 12, 0, 0);
      final txn = Transaction(
        id: 1,
        title: 'Salary Deposit',
        amount: 50000.0,
        isIncome: true,
        category: 'Salary',
        date: now,
      );

      final map = txn.toMap();
      expect(map['id'], equals(1));
      expect(map['title'], equals('Salary Deposit'));
      expect(map['amount'], equals(50000.0));
      expect(map['isIncome'], equals(1));
      expect(map['category'], equals('Salary'));
      expect(map['date'], equals(now.toIso8601String()));

      final restored = Transaction.fromMap(map);
      expect(restored.id, equals(1));
      expect(restored.title, equals('Salary Deposit'));
      expect(restored.amount, equals(50000.0));
      expect(restored.isIncome, isTrue);
      expect(restored.category, equals('Salary'));
      expect(restored.date, equals(now));
    });
  });

  group('Budget Model Tests', () {
    test('Budget toMap, fromMap, and copyWith', () {
      final budget = Budget(
        id: 10,
        category: 'Food',
        limit: 15000.0,
        month: '2026-07',
      );

      final map = budget.toMap();
      expect(map['id'], equals(10));
      expect(map['category'], equals('Food'));
      expect(map['budgetLimit'], equals(15000.0));
      expect(map['month'], equals('2026-07'));

      final restored = Budget.fromMap(map);
      expect(restored.id, equals(10));
      expect(restored.category, equals('Food'));
      expect(restored.limit, equals(15000.0));
      expect(restored.month, equals('2026-07'));

      final updated = budget.copyWith(limit: 20000.0);
      expect(updated.id, equals(10));
      expect(updated.category, equals('Food'));
      expect(updated.limit, equals(20000.0));
      expect(updated.month, equals('2026-07'));
    });
  });

  group('Debt Model Tests', () {
    test('Debt calculations: remainingAmount, isFullyPaid, progress', () {
      final now = DateTime(2026, 7, 25);
      final debt = Debt(
        id: 5,
        personName: 'Rahul',
        totalAmount: 10000.0,
        paidAmount: 2500.0,
        isOwedToMe: true,
        description: 'Trip expense',
        createdDate: now,
      );

      expect(debt.remainingAmount, equals(7500.0));
      expect(debt.isFullyPaid, isFalse);
      expect(debt.progress, equals(0.25));

      final fullyPaid = debt.copyWith(paidAmount: 10000.0);
      expect(fullyPaid.remainingAmount, equals(0.0));
      expect(fullyPaid.isFullyPaid, isTrue);
      expect(fullyPaid.progress, equals(1.0));
    });

    test('Debt toMap and fromMap serialization', () {
      final created = DateTime(2026, 7, 1);
      final due = DateTime(2026, 8, 1);
      final debt = Debt(
        id: 2,
        personName: 'Ankit',
        totalAmount: 5000.0,
        paidAmount: 1000.0,
        isOwedToMe: false,
        description: 'Borrowed money',
        dueDate: due,
        createdDate: created,
      );

      final map = debt.toMap();
      expect(map['isOwedToMe'], equals(0));
      expect(map['dueDate'], equals(due.toIso8601String()));

      final restored = Debt.fromMap(map);
      expect(restored.personName, equals('Ankit'));
      expect(restored.isOwedToMe, isFalse);
      expect(restored.dueDate, equals(due));
      expect(restored.createdDate, equals(created));
    });
  });
}
