import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/auto_transaction.dart';
import '../providers/auto_tracking_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/categorization_engine.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _warningColor = Color(0xFFF39C12);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);

  @override
  Widget build(BuildContext context) {
    final autoProvider = Provider.of<AutoTrackingProvider>(context);
    final txnProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final pending = autoProvider.pendingTransactions;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Review Detected Expenses',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (pending.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await autoProvider.approveAllPending(txnProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Text('All transactions approved and logged!'),
                        ],
                      ),
                      backgroundColor: _incomeColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded, color: _incomeColor, size: 20),
              label: const Text(
                'Approve All',
                style: TextStyle(color: _incomeColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: pending.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: _incomeColor,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'All Caught Up!',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'No pending transactions to review. Automatic detections from Google Pay, PhonePe, and other payment apps will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final txn = pending[index];
                return _buildTransactionCard(context, txn, autoProvider, txnProvider, currencyProvider);
              },
            ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    AutoTransaction txn,
    AutoTrackingProvider autoProvider,
    TransactionProvider txnProvider,
    CurrencyProvider currencyProvider,
  ) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final isIncome = txn.transactionType == 'income' || txn.transactionType == 'refund';

    Color confidenceColor;
    String confidenceLabel;
    if (txn.confidence == 'high') {
      confidenceColor = _incomeColor;
      confidenceLabel = 'High match';
    } else if (txn.confidence == 'medium') {
      confidenceColor = _warningColor;
      confidenceLabel = 'Likely match';
    } else {
      confidenceColor = _expenseColor;
      confidenceLabel = 'Needs category';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isIncome ? _incomeColor : _expenseColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isIncome ? _incomeColor : _expenseColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.merchant,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateFormat.format(txn.date),
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: confidenceColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              confidenceLabel,
                              style: TextStyle(
                                color: confidenceColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'} ${currencyProvider.symbol}${NumberFormat('#,##0.00').format(txn.amount)}',
                  style: TextStyle(
                    color: isIncome ? _incomeColor : _expenseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Category selector pill
            InkWell(
              onTap: () => _showEditCategorySheet(context, txn, autoProvider, txnProvider),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_outlined, size: 14, color: _accentColor),
                    const SizedBox(width: 6),
                    Text(
                      txn.category,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: _textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _expenseColor,
                      side: BorderSide(color: _expenseColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => autoProvider.rejectTransaction(txn),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _incomeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await autoProvider.approveTransaction(txn, txnProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved "${txn.merchant}" to expenses'),
                            backgroundColor: _incomeColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategorySheet(
    BuildContext context,
    AutoTransaction txn,
    AutoTrackingProvider autoProvider,
    TransactionProvider txnProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF152238),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Change Category for "${txn.merchant}"',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Future payments to this merchant will automatically use this category.',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: CategorizationEngine.allCategories.length,
                  itemBuilder: (context, i) {
                    final cat = CategorizationEngine.allCategories[i];
                    final isSelected = cat == txn.category;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected ? _accentColor.withValues(alpha: 0.15) : null,
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isSelected ? _accentColor : _textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? _accentColor : _textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        autoProvider.approveTransaction(
                          txn,
                          txnProvider,
                          category: cat,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
