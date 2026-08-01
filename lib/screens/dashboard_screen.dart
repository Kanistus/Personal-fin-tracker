import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Color palette
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);

  static const List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Family',
    'Rent',
    'Gift',
    'Other',
  ];

  static const List<String> _expenseCategories = [
    'Food',
    'Snacks',
    'Rent',
    'Transport',
    'Shopping',
    'Bills',
    'Investment',
    'Family',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Salary': Icons.work_rounded,
    'Freelance': Icons.laptop_rounded,
    'Investment': Icons.trending_up_rounded,
    'Family': Icons.family_restroom_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Food': Icons.restaurant_rounded,
    'Snacks': Icons.fastfood_rounded,
    'Rent': Icons.home_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Personal Finance',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }

          return Column(
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildSummaryCards(provider),
              ),

              // Transactions header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.transactions.length} items',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Transaction list
              Expanded(
                child: provider.transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(context, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: () => _showAddTransactionSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSummaryCards(TransactionProvider provider) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        // Balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                formatter.format(provider.balance),
                style: TextStyle(
                  color: provider.balance >= 0 ? _incomeColor : _expenseColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Income & Expense row
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                'Income',
                formatter.format(provider.totalIncome),
                _incomeColor,
                Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallCard(
                'Expense',
                formatter.format(provider.totalExpense),
                _expenseColor,
                Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, color: _textSecondary.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(color: _textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first entry',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        final txn = provider.transactions[index];
        final icon = _categoryIcons[txn.category] ?? Icons.more_horiz_rounded;

        return Dismissible(
          key: ValueKey(txn.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _expenseColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_rounded, color: _expenseColor),
          ),
          onDismissed: (_) {
            provider.deleteTransaction(txn.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted "${txn.title}"'),
                backgroundColor: _cardColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: GestureDetector(
            onTap: () => _showTransactionDetailSheet(context, txn, provider),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (txn.isIncome ? _incomeColor : _expenseColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: txn.isIncome ? _incomeColor : _expenseColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.title,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${txn.category} • ${dateFormat.format(txn.date)}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${txn.isIncome ? '+' : '-'} ₹${NumberFormat('#,##0').format(txn.amount)}',
                        style: TextStyle(
                          color: txn.isIncome ? _incomeColor : _expenseColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Direct Edit button
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.edit_outlined, color: _accentColor, size: 20),
                    tooltip: 'Edit Transaction',
                    onPressed: () => _showAddTransactionSheet(context, transactionToEdit: txn),
                  ),
                  // Direct Delete button
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.delete_outline_rounded, color: _expenseColor, size: 20),
                    tooltip: 'Delete Transaction',
                    onPressed: () {
                      if (txn.id != null) {
                        provider.deleteTransaction(txn.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${txn.title}"'),
                            backgroundColor: _cardColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetailSheet(
    BuildContext context,
    Transaction txn,
    TransactionProvider provider,
  ) {
    final dateFormat = DateFormat('dd MMMM yyyy');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF152238),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (txn.isIncome ? _incomeColor : _expenseColor)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categoryIcons[txn.category] ?? Icons.more_horiz_rounded,
                        color: txn.isIncome ? _incomeColor : _expenseColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.title,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${txn.isIncome ? "Income" : "Expense"} • ${txn.category}',
                            style: TextStyle(
                              color: txn.isIncome ? _incomeColor : _expenseColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info block
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount', style: TextStyle(color: _textSecondary, fontSize: 13)),
                          Text(
                            '${txn.isIncome ? '+' : '-'} ₹${NumberFormat('#,##0.00').format(txn.amount)}',
                            style: TextStyle(
                              color: txn.isIncome ? _incomeColor : _expenseColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF1F2D42), height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date', style: TextStyle(color: _textSecondary, fontSize: 13)),
                          Text(
                            dateFormat.format(txn.date),
                            style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Edit and Delete buttons row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showAddTransactionSheet(context, transactionToEdit: txn);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _expenseColor.withValues(alpha: 0.2),
                            foregroundColor: _expenseColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _expenseColor),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (txn.id != null) {
                              provider.deleteTransaction(txn.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Deleted "${txn.title}"'),
                                  backgroundColor: _cardColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTransactionSheet(BuildContext context, {Transaction? transactionToEdit}) {
    final bool isEditing = transactionToEdit != null;
    bool isIncome = transactionToEdit?.isIncome ?? false;
    String? selectedCategory = transactionToEdit?.category;
    bool categoryError = false;
    final titleController =
        TextEditingController(text: transactionToEdit?.title ?? '');
    final amountController = TextEditingController(
        text: transactionToEdit != null ? transactionToEdit.amount.toStringAsFixed(0) : '');
    DateTime selectedDate = transactionToEdit?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categories =
                isIncome ? _incomeCategories : _expenseCategories;
            if (selectedCategory != null && !categories.contains(selectedCategory)) {
              selectedCategory = null;
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF152238),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                      isEditing ? 'Edit Transaction' : 'Add Transaction',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Income / Expense toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isIncome = true;
                                  if (selectedCategory != null &&
                                      !_incomeCategories.contains(selectedCategory)) {
                                    selectedCategory = null;
                                  }
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isIncome
                                      ? _incomeColor.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Income',
                                    style: TextStyle(
                                      color: isIncome
                                          ? _incomeColor
                                          : _textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isIncome = false;
                                  if (selectedCategory != null &&
                                      !_expenseCategories.contains(selectedCategory)) {
                                    selectedCategory = null;
                                  }
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isIncome
                                      ? _expenseColor.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Expense',
                                    style: TextStyle(
                                      color: !isIncome
                                          ? _expenseColor
                                          : _textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title field
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: const TextStyle(color: _textSecondary),
                        filled: true,
                        fillColor: _bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        hintStyle: const TextStyle(color: _textSecondary),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: _textPrimary),
                        filled: true,
                        fillColor: _bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: categoryError
                            ? Border.all(color: _expenseColor, width: 1.5)
                            : Border.all(color: Colors.transparent, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          hint: const Text(
                            'Select Category',
                            style: TextStyle(color: _textSecondary),
                          ),
                          isExpanded: true,
                          dropdownColor: _cardColor,
                          style: const TextStyle(color: _textPrimary),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _textSecondary,
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedCategory = val;
                                categoryError = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (categoryError) ...[
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '⚠️ Please fill this: Category is required',
                          style: TextStyle(
                            color: _expenseColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: _textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(color: _textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save / Update button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isIncome ? _incomeColor : _expenseColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim());

                          if (selectedCategory == null || selectedCategory!.isEmpty) {
                            setState(() {
                              categoryError = true;
                            });
                          }

                          if (title.isEmpty || amount == null || amount <= 0 || selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        selectedCategory == null
                                            ? 'Please fill these: Please select a Category'
                                            : 'Please fill these: Title and Amount are required',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: _expenseColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            return;
                          }

                          final txn = Transaction(
                            id: isEditing ? transactionToEdit.id : null,
                            title: title,
                            amount: amount,
                            isIncome: isIncome,
                            category: selectedCategory!,
                            date: selectedDate,
                          );

                          final provider = Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          );

                          if (isEditing) {
                            provider.updateTransaction(txn);
                          } else {
                            provider.addTransaction(txn);
                          }

                          Navigator.of(context).pop();
                        },
                        child: Text(
                          isEditing
                              ? 'Update Transaction'
                              : (isIncome ? 'Add Income' : 'Add Expense'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
