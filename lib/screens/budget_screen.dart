import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _warningColor = Color(0xFFF39C12);
  static const Color _expenseColor = Color(0xFFE74C3C);

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
    'Food': Icons.restaurant_rounded,
    'Snacks': Icons.fastfood_rounded,
    'Rent': Icons.home_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Investment': Icons.trending_up_rounded,
    'Family': Icons.family_restroom_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  void _loadBudgets() {
    Provider.of<BudgetProvider>(context, listen: false).loadBudgets(_monthKey);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadBudgets();
  }

  Color _progressColor(double progress) {
    if (progress < 0.6) return _incomeColor;
    if (progress < 0.85) return _warningColor;
    return _expenseColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Budget',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: _textPrimary),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: _textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Budget list
          Expanded(
            child: Consumer<BudgetProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                if (provider.budgets.isEmpty) {
                  return _buildEmptyState(provider);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    // ── Budget Planning Summary Card ──
                    _buildPlanningCard(provider),
                    const SizedBox(height: 16),

                    // ── Alerts Section ──
                    if (provider.overBudgetCategories.isNotEmpty)
                      _buildAlertCard(provider),

                    // Section header
                    Row(
                      children: [
                        const Text(
                          'Category Budgets',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${provider.budgets.length} categories',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Budget cards
                    ...provider.budgets.map(
                      (budget) =>
                          _buildBudgetCard(context, provider, budget),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: () => _showAddBudgetSheet(context),
        child:
            const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Budget Planning Summary Card ──
  Widget _buildPlanningCard(BudgetProvider provider) {
    final formatter =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final overallProgress = provider.overallProgress;
    final progressColor = _progressColor(overallProgress);

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Budget Overview',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(overallProgress * 100).toInt()}% used',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formatter.format(provider.totalSpent)} of ${formatter.format(provider.totalBudgeted)}',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Budgeted',
                  formatter.format(provider.totalBudgeted),
                  _accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Spent',
                  formatter.format(provider.totalSpent),
                  _warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Remaining',
                  formatter.format(provider.totalRemaining),
                  provider.totalRemaining >= 0
                      ? _incomeColor
                      : _expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textSecondary.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Alerts Card ──
  Widget _buildAlertCard(BudgetProvider provider) {
    final overBudget = provider.overBudgetCategories;
    final formatter =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _expenseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _expenseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: _expenseColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${overBudget.length} ${overBudget.length == 1 ? 'category' : 'categories'} over budget',
                style: const TextStyle(
                  color: _expenseColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...overBudget.map((b) {
            final spent = provider.getSpent(b.category);
            final over = spent - b.limit;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${b.category}: ${formatter.format(over)} over limit',
                style: TextStyle(
                  color: _expenseColor.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BudgetProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              color: _textSecondary.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No budgets set',
            style: TextStyle(color: _textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to set a spending limit',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Copy from last month button
          FutureBuilder<bool>(
            future: provider
                .hasBudgetsForMonth(provider.getPreviousMonth(_monthKey)),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return OutlinedButton.icon(
                  onPressed: () => _copyFromPreviousMonth(provider),
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('Copy from last month'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    side: BorderSide(
                      color: _accentColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _copyFromPreviousMonth(BudgetProvider provider) async {
    final prevMonth = provider.getPreviousMonth(_monthKey);
    await provider.copyBudgetsFromMonth(prevMonth);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Budgets copied from last month!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
    }
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetProvider provider,
    Budget budget,
  ) {
    final spent = provider.getSpent(budget.category);
    final progress = provider.getProgress(budget);
    final color = _progressColor(progress);
    final icon =
        _categoryIcons[budget.category] ?? Icons.more_horiz_rounded;
    final formatter =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final remaining = budget.limit - spent;

    return Dismissible(
      key: ValueKey(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _expenseColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: _expenseColor),
      ),
      onDismissed: (_) {
        provider.deleteBudget(budget.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleted ${budget.category} budget',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
      },
      child: GestureDetector(
        onTap: () => _showEditBudgetSheet(context, budget),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
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
                          budget.category,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remaining >= 0
                              ? '${formatter.format(remaining)} remaining'
                              : '${formatter.format(-remaining)} over',
                          style: TextStyle(
                            color:
                                remaining >= 0 ? _textSecondary : _expenseColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatter.format(spent)} / ${formatter.format(budget.limit)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),

              // Percentage
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(progress * 100).toInt()}% used',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Budget Bottom Sheet ──
  void _showEditBudgetSheet(BuildContext context, Budget budget) {
    final limitController =
        TextEditingController(text: budget.limit.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF152238),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit ${budget.category} Budget',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: _expenseColor),
                      tooltip: 'Delete Budget',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (budget.id != null) {
                          Provider.of<BudgetProvider>(context, listen: false).deleteBudget(budget.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Deleted ${budget.category} budget',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
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
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Limit',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                                symbol: '₹', decimalDigits: 0)
                            .format(budget.limit),
                        style: const TextStyle(
                          color: _accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // New limit field
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'New Monthly Limit',
                    hintStyle:
                        const TextStyle(color: _textSecondary),
                    prefixText: '₹ ',
                    prefixStyle:
                        const TextStyle(color: _textPrimary),
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
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final limit = double.tryParse(
                          limitController.text.trim());

                      if (limit == null || limit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Please fill these: Please enter a valid limit',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
                        return;
                      }

                      final updated = budget.copyWith(limit: limit);
                      Provider.of<BudgetProvider>(
                        context,
                        listen: false,
                      ).updateBudget(updated);

                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Update Budget',
                      style: TextStyle(
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
  }

  void _showAddBudgetSheet(BuildContext context) {
    String? selectedCategory;
    bool categoryError = false;
    final limitController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF152238),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
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
                          color:
                              _textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Budget for ${DateFormat('MMMM').format(_selectedMonth)}',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
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
                          style: const TextStyle(
                              color: _textPrimary),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _textSecondary,
                          ),
                          items:
                              _expenseCategories.map((cat) {
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

                    // Limit field
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      style:
                          const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Monthly Limit',
                        hintStyle: const TextStyle(
                            color: _textSecondary),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                            color: _textPrimary),
                        filled: true,
                        fillColor: _bgColor,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (selectedCategory == null || selectedCategory!.isEmpty) {
                            setState(() {
                              categoryError = true;
                            });
                          }

                          final limit = double.tryParse(
                              limitController.text.trim());

                          if (selectedCategory == null || limit == null || limit <= 0) {
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
                                            : 'Please fill these: Monthly Limit is required',
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

                          final budget = Budget(
                            category: selectedCategory!,
                            limit: limit,
                            month: _monthKey,
                          );

                          Provider.of<BudgetProvider>(
                            context,
                            listen: false,
                          ).addBudget(budget);

                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Set Budget',
                          style: TextStyle(
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
