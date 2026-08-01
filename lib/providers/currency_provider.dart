import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_currency_code';

  Currency _currency = Currency.supportedCurrencies.first; // Default: INR

  Currency get currency => _currency;
  String get symbol => _currency.symbol;
  String get code => _currency.code;

  /// Pre-built NumberFormat formatter using the current currency's symbol & decimals.
  NumberFormat get formatter => NumberFormat.currency(
        symbol: _currency.symbol,
        decimalDigits: _currency.decimalDigits,
      );

  /// Format a double amount using the current currency.
  String format(double amount) => formatter.format(amount);

  /// Load saved currency from SharedPreferences.
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      _currency = Currency.fromCode(savedCode);
      notifyListeners();
    }
  }

  /// Change and persist the selected currency.
  Future<void> setCurrency(String code) async {
    _currency = Currency.fromCode(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }
}
