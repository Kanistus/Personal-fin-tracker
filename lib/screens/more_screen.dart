import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
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
              subtitle: 'Full report with formatted sheets & summaries',
              accentColor: _incomeColor,
              onTap: () => _exportExcel(context),
            ),
            const SizedBox(height: 10),

            // Export to Excel (with budgets)
            _buildOptionCard(
              icon: Icons.file_download_rounded,
              title: 'Export Full Report',
              subtitle: 'Excel file with transactions + budget data',
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
                    'Version 1.1.0',
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

  void _exportExcel(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    if (provider.transactions.isEmpty) {
      _showEmptySnackBar(context);
      return;
    }

    try {
      await ExcelExporter.exportAndShare(
        transactions: provider.transactions,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Excel export failed: $e');
      }
    }
  }

  void _exportFullReport(BuildContext context) async {
    final txnProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider =
        Provider.of<BudgetProvider>(context, listen: false);

    if (txnProvider.transactions.isEmpty) {
      _showEmptySnackBar(context);
      return;
    }

    if (budgetProvider.budgets.isEmpty) {
      await budgetProvider.loadBudgets();
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
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Full report export failed: $e');
      }
    }
  }

  void _showEmptySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No transactions to export'),
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
