import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency_model.dart';
import '../services/csv_exporter.dart';
import '../services/excel_exporter.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);
  static const Color _incomeColor = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currentCurrency = currencyProvider.currency;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings section header
            const Text(
              'Settings',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Currency selector
            _buildOptionCard(
              icon: Icons.currency_exchange_rounded,
              title: 'Currency',
              subtitle: '${currentCurrency.flag}  ${currentCurrency.name} (${currentCurrency.symbol})',
              accentColor: const Color(0xFFE67E22),
              onTap: () => _showCurrencyPicker(context),
            ),
            const SizedBox(height: 20),

            // Export section header
            const Text(
              'Export Data',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Export to CSV
            _buildOptionCard(
              icon: Icons.table_chart_rounded,
              title: 'Export to CSV',
              subtitle: 'Download transactions as a CSV file',
              accentColor: _accentColor,
              onTap: () => _exportCsv(context),
            ),
            const SizedBox(height: 10),

            // Export to Excel
            _buildOptionCard(
              icon: Icons.grid_on_rounded,
              title: 'Export to Excel',
              subtitle: 'Full report with Budget vs Expense columns',
              accentColor: _incomeColor,
              onTap: () => _exportFullReport(context),
            ),
            const SizedBox(height: 10),

            // Export Full Report
            _buildOptionCard(
              icon: Icons.file_download_rounded,
              title: 'Export Full Report',
              subtitle: 'Transactions, Budget vs Expense & Debts',
              accentColor: const Color(0xFF9B59B6),
              onTap: () => _exportFullReport(context),
            ),

            const Spacer(),

            // App info
            Center(
              child: Column(
                children: const [
                  Text(
                    'Personal Finance Tracker',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.3.0',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accentColor = const Color(0xFF3498DB),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Currency Picker Bottom Sheet ──
  void _showCurrencyPicker(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedCode = currencyProvider.code;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF152238),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _textSecondary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.currency_exchange_rounded, color: Color(0xFFE67E22), size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Select Currency',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Choose your preferred currency for all amounts',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Currency list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: Currency.supportedCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = Currency.supportedCurrencies[index];
                        final isSelected = currency.code == selectedCode;

                        return GestureDetector(
                          onTap: () {
                            currencyProvider.setCurrency(currency.code);
                            setState(() {}); // Rebuild to show checkmark
                            Navigator.of(ctx).pop();

                            // Show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Currency changed to ${currency.flag} ${currency.name} (${currency.symbol})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF27AE60),
                                behavior: SnackBarBehavior.floating,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE67E22).withValues(alpha: 0.12)
                                  : _bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFFE67E22).withValues(alpha: 0.4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Flag
                                Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 14),
                                // Name & Code
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency.name,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFFE67E22) : _textPrimary,
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currency.code,
                                        style: const TextStyle(
                                          color: _textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Symbol
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE67E22).withValues(alpha: 0.2)
                                        : _cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    currency.symbol,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFFE67E22) : _textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFFE67E22), size: 22),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportCsv(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    if (provider.transactions.isEmpty) {
      _showEmptySnackBar(context);
      return;
    }

    try {
      await CsvExporter.exportAndShare(provider.transactions);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'CSV export failed: $e');
      }
    }
  }

  void _exportFullReport(BuildContext context) async {
    final txnProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider =
        Provider.of<BudgetProvider>(context, listen: false);
    final debtProvider =
        Provider.of<DebtProvider>(context, listen: false);
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    if (txnProvider.transactions.isEmpty) {
      _showEmptySnackBar(context);
      return;
    }

    if (budgetProvider.budgets.isEmpty) {
      await budgetProvider.loadBudgets();
    }

    if (debtProvider.debts.isEmpty) {
      await debtProvider.loadDebts();
    }

    try {
      await ExcelExporter.exportAndShare(
        transactions: txnProvider.transactions,
        budgets: budgetProvider.budgets.isNotEmpty
            ? budgetProvider.budgets
            : null,
        spentMap: budgetProvider.spentMap.isNotEmpty
            ? budgetProvider.spentMap
            : null,
        debts: debtProvider.debts.isNotEmpty ? debtProvider.debts : null,
        settlements: debtProvider.allSettlements.isNotEmpty
            ? debtProvider.allSettlements
            : null,
        currencySymbol: currencyProvider.symbol,
        currencyDecimals: currencyProvider.currency.decimalDigits,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Report export failed: $e');
      }
    }
  }

  void _showEmptySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'No transactions to export',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2980B9),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFC0392B),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
