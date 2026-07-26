import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);

  static const Map<String, IconData> _categoryIcons = {
    'Salary': Icons.work_rounded,
    'Freelance': Icons.laptop_rounded,
    'Investment': Icons.trending_up_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  static const List<Color> _chartColors = [
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFFEC407A),
  ];

  late DateTime _selectedMonth;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Spending',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: _accentColor,
              unselectedLabelColor: _textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Month selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseTab(),
                _buildIncomeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final expenses = provider.getCategoryExpenses(_monthKey);
        final totalExpense = provider.getMonthlyExpense(_monthKey);
        final totalIncome = provider.getMonthlyIncome(_monthKey);
        final dailySpending = provider.getDailySpending(_monthKey);
        final activeDays = provider.getActiveDaysInMonth(_monthKey);

        if (totalExpense == 0) {
          return _buildEmptyState('No expenses recorded this month');
        }

        // Sort categories by amount (descending)
        final sortedCategories = expenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final avgDaily =
            activeDays > 0 ? totalExpense / activeDays : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          children: [
            // Overview cards
            _buildOverviewRow(
              totalExpense: totalExpense,
              totalIncome: totalIncome,
              avgDaily: avgDaily,
            ),
            const SizedBox(height: 16),

            // Daily spending mini chart
            if (dailySpending.isNotEmpty) ...[
              _buildDailyChart(dailySpending),
              const SizedBox(height: 16),
            ],

            // Category breakdown header
            const Text(
              'Category Breakdown',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Category bars
            ...List.generate(sortedCategories.length, (index) {
              final entry = sortedCategories[index];
              final percentage = totalExpense > 0
                  ? entry.value / totalExpense
                  : 0.0;
              final color =
                  _chartColors[index % _chartColors.length];
              return _buildCategoryBar(
                category: entry.key,
                amount: entry.value,
                percentage: percentage,
                color: color,
                total: totalExpense,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final incomes = provider.getCategoryIncomes(_monthKey);
        final totalIncome = provider.getMonthlyIncome(_monthKey);

        if (totalIncome == 0) {
          return _buildEmptyState('No income recorded this month');
        }

        final sortedCategories = incomes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          children: [
            // Total income card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
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
                          color: _incomeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_downward_rounded,
                            color: _incomeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Total Income',
                        style:
                            TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(totalIncome),
                    style: const TextStyle(
                      color: _incomeColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Income Sources',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(sortedCategories.length, (index) {
              final entry = sortedCategories[index];
              final percentage = totalIncome > 0
                  ? entry.value / totalIncome
                  : 0.0;
              return _buildCategoryBar(
                category: entry.key,
                amount: entry.value,
                percentage: percentage,
                color: _incomeColor,
                total: totalIncome,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildOverviewRow({
    required double totalExpense,
    required double totalIncome,
    required double avgDaily,
  }) {
    final formatter =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final savings = totalIncome - totalExpense;

    return Column(
      children: [
        // Total expense card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D1E1E), Color(0xFF5C2E2E)],
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
                      color: _expenseColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: _expenseColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Total Expenses',
                    style:
                        TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                formatter.format(totalExpense),
                style: const TextStyle(
                  color: _expenseColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg / Day',
                formatter.format(avgDaily),
                Icons.calendar_view_day_rounded,
                _accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Savings',
                formatter.format(savings),
                savings >= 0
                    ? Icons.savings_rounded
                    : Icons.warning_rounded,
                savings >= 0 ? _incomeColor : _expenseColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style:
                    const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildDailyChart(Map<int, double> dailySpending) {
    final maxSpend = dailySpending.values
        .fold(0.0, (max, v) => v > max ? v : max);
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Spending',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daysInMonth, (index) {
                final day = index + 1;
                final amount = dailySpending[day] ?? 0.0;
                final heightFraction =
                    maxSpend > 0 ? (amount / maxSpend) : 0.0;

                return Expanded(
                  child: Tooltip(
                    message: 'Day $day: ₹${amount.toStringAsFixed(0)}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: amount > 0
                            ? _accentColor
                                .withValues(alpha: 0.3 + heightFraction * 0.7)
                            : _bgColor.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      height: amount > 0
                          ? (heightFraction * 70).clamp(4.0, 70.0)
                          : 4.0,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  color: _textSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
              Text(
                '$daysInMonth',
                style: TextStyle(
                  color: _textSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar({
    required String category,
    required double amount,
    required double percentage,
    required Color color,
    required double total,
  }) {
    final formatter =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final icon = _categoryIcons[category] ?? Icons.more_horiz_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
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
                child: Text(
                  category,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(amount),
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_rounded,
              color: _textSecondary.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: _textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add transactions to see analysis',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
