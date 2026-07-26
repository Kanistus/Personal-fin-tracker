import 'package:flutter/foundation.dart';
import '../models/debt.dart';
import '../services/db_helper.dart';

class DebtProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  List<Debt> _debts = [];
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;

  // Debts where someone owes me
  List<Debt> get debtsOwedToMe =>
      _debts.where((d) => d.isOwedToMe).toList();

  // Debts where I owe someone
  List<Debt> get debtsIOwe =>
      _debts.where((d) => !d.isOwedToMe).toList();

  // Active (unpaid) debts
  List<Debt> get activeDebts =>
      _debts.where((d) => !d.isFullyPaid).toList();

  // Settled debts
  List<Debt> get settledDebts =>
      _debts.where((d) => d.isFullyPaid).toList();

  // Total amount others owe me (remaining)
  double get totalOwedToMe =>
      debtsOwedToMe.fold(0.0, (sum, d) => sum + d.remainingAmount);

  // Total amount I owe others (remaining)
  double get totalIOwe =>
      debtsIOwe.fold(0.0, (sum, d) => sum + d.remainingAmount);

  // Net position (positive = people owe me more)
  double get netPosition => totalOwedToMe - totalIOwe;

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();

    _debts = (await _dbHelper.getDebts()).cast<Debt>();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    await _dbHelper.insertDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    await _dbHelper.deleteDebt(id);
    await loadDebts();
  }

  Future<void> updateDebt(Debt debt) async {
    await _dbHelper.updateDebt(debt);
    await loadDebts();
  }

  Future<void> recordPayment(Debt debt, double paymentAmount) async {
    final newPaid = (debt.paidAmount + paymentAmount).clamp(0.0, debt.totalAmount);
    final updated = debt.copyWith(paidAmount: newPaid);
    await _dbHelper.updateDebt(updated);
    await loadDebts();
  }

  Future<void> markAsSettled(Debt debt) async {
    final updated = debt.copyWith(paidAmount: debt.totalAmount);
    await _dbHelper.updateDebt(updated);
    await loadDebts();
  }
}
