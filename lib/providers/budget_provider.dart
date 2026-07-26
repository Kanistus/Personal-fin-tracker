import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/db_helper.dart';

class BudgetProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  List<Budget> _budgets = [];
  Map<String, double> _spentMap = {};
  bool _isLoading = false;
  String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  List<Budget> get budgets => _budgets;
  Map<String, double> get spentMap => _spentMap;
  bool get isLoading => _isLoading;
  String get currentMonth => _currentMonth;

  Future<void> loadBudgets([String? month]) async {
    _isLoading = true;
    _currentMonth = month ?? (_currentMonth.isNotEmpty ? _currentMonth : DateFormat('yyyy-MM').format(DateTime.now()));
    notifyListeners();

    _budgets = (await _dbHelper.getBudgets(_currentMonth)).cast<Budget>();

    // Load spent amounts for each budget category
    _spentMap = {};
    for (final budget in _budgets) {
      _spentMap[budget.category] =
          await _dbHelper.getExpenseByCategory(budget.category, _currentMonth);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    await _dbHelper.insertBudget(budget);
    await loadBudgets(_currentMonth);
  }

  Future<void> deleteBudget(int id) async {
    await _dbHelper.deleteBudget(id);
    await loadBudgets(_currentMonth);
  }

  Future<void> updateBudget(Budget budget) async {
    await _dbHelper.updateBudget(budget);
    await loadBudgets(_currentMonth);
  }

  double getSpent(String category) => _spentMap[category] ?? 0.0;

  double getProgress(Budget budget) {
    final spent = getSpent(budget.category);
    if (budget.limit <= 0) return 0.0;
    return (spent / budget.limit).clamp(0.0, 1.0);
  }

  // ── Budget Planning Helpers ──

  /// Total budgeted amount for current month
  double get totalBudgeted =>
      _budgets.fold(0.0, (sum, b) => sum + b.limit);

  /// Total spent across all budget categories
  double get totalSpent =>
      _spentMap.values.fold(0.0, (sum, v) => sum + v);

  /// Total remaining budget
  double get totalRemaining => totalBudgeted - totalSpent;

  /// Overall budget usage percentage (0.0 to 1.0)
  double get overallProgress {
    if (totalBudgeted <= 0) return 0.0;
    return (totalSpent / totalBudgeted).clamp(0.0, 1.0);
  }

  /// Copy all budgets from a previous month to the current month
  Future<void> copyBudgetsFromMonth(String sourceMonth) async {
    final sourceBudgets =
        (await _dbHelper.getBudgets(sourceMonth)).cast<Budget>();

    for (final budget in sourceBudgets) {
      final newBudget = Budget(
        category: budget.category,
        limit: budget.limit,
        month: _currentMonth,
      );
      await _dbHelper.insertBudget(newBudget);
    }

    await loadBudgets(_currentMonth);
  }

  /// Check if budgets exist for a given month
  Future<bool> hasBudgetsForMonth(String month) async {
    final budgets = await _dbHelper.getBudgets(month);
    return budgets.isNotEmpty;
  }

  /// Get the previous month string (YYYY-MM)
  String getPreviousMonth(String month) {
    final parts = month.split('-');
    int year = int.parse(parts[0]);
    int m = int.parse(parts[1]);
    m -= 1;
    if (m < 1) {
      m = 12;
      year -= 1;
    }
    return '$year-${m.toString().padLeft(2, '0')}';
  }

  /// Get categories that are over budget
  List<Budget> get overBudgetCategories {
    return _budgets.where((b) => getSpent(b.category) > b.limit).toList();
  }

  /// Get categories that are near budget limit (>80%)
  List<Budget> get nearLimitCategories {
    return _budgets.where((b) {
      final progress = getProgress(b);
      return progress >= 0.8 && progress <= 1.0;
    }).toList();
  }
}
