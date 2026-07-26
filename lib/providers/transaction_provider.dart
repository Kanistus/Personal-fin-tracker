import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    _transactions = (await _dbHelper.getTransactions()).cast<Transaction>();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction txn) async {
    await _dbHelper.insertTransaction(txn);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction txn) async {
    await _dbHelper.updateTransaction(txn);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await loadTransactions();
  }

  Future<double> getExpenseByCategory(String category, String month) async {
    return await _dbHelper.getExpenseByCategory(category, month);
  }

  // ── Spending Analysis Helpers ──

  /// Get all transactions for a specific month (YYYY-MM format)
  List<Transaction> getTransactionsForMonth(String month) {
    return _transactions.where((t) {
      final txnMonth =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      return txnMonth == month;
    }).toList();
  }

  /// Get total expense for a specific month
  double getMonthlyExpense(String month) {
    return getTransactionsForMonth(month)
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total income for a specific month
  double getMonthlyIncome(String month) {
    return getTransactionsForMonth(month)
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get category-wise expense breakdown for a month
  Map<String, double> getCategoryExpenses(String month) {
    final monthTxns = getTransactionsForMonth(month)
        .where((t) => !t.isIncome);

    final Map<String, double> result = {};
    for (final txn in monthTxns) {
      result[txn.category] = (result[txn.category] ?? 0.0) + txn.amount;
    }
    return result;
  }

  /// Get category-wise income breakdown for a month
  Map<String, double> getCategoryIncomes(String month) {
    final monthTxns = getTransactionsForMonth(month)
        .where((t) => t.isIncome);

    final Map<String, double> result = {};
    for (final txn in monthTxns) {
      result[txn.category] = (result[txn.category] ?? 0.0) + txn.amount;
    }
    return result;
  }

  /// Get daily spending for a month (for trend visualization)
  Map<int, double> getDailySpending(String month) {
    final monthTxns = getTransactionsForMonth(month)
        .where((t) => !t.isIncome);

    final Map<int, double> result = {};
    for (final txn in monthTxns) {
      final day = txn.date.day;
      result[day] = (result[day] ?? 0.0) + txn.amount;
    }
    return result;
  }

  /// Get the number of transaction days in a month
  int getActiveDaysInMonth(String month) {
    final monthTxns = getTransactionsForMonth(month);
    final days = monthTxns.map((t) => t.date.day).toSet();
    return days.length;
  }
}
