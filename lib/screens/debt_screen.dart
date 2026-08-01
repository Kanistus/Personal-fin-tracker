import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _warningColor = Color(0xFFF39C12);
  static const Color _purpleColor = Color(0xFF9B59B6);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).loadDebts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Debts',
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
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'They Owe'),
                Tab(text: 'I Owe'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 12),
              // Summary card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummaryCard(provider),
              ),
              const SizedBox(height: 12),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDebtList(provider.activeDebts, provider),
                    _buildDebtList(
                      provider.debtsOwedToMe
                          .where((d) => !d.isFullyPaid)
                          .toList(),
                      provider,
                    ),
                    _buildDebtList(
                      provider.debtsIOwe
                          .where((d) => !d.isFullyPaid)
                          .toList(),
                      provider,
                    ),
                    _buildHistoryTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        onPressed: () => _showAddDebtSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSummaryCard(DebtProvider provider) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final net = provider.netPosition;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: net >= 0
              ? [const Color(0xFF1B4332), const Color(0xFF2D6A4F)]
              : [const Color(0xFF3D1E1E), const Color(0xFF5C2E2E)],
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
                  color: (net >= 0 ? _incomeColor : _expenseColor)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  net >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: net >= 0 ? _incomeColor : _expenseColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Net Position',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatter.format(net.abs()),
            style: TextStyle(
              color: net >= 0 ? _incomeColor : _expenseColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            net >= 0
                ? 'People owe you more'
                : 'You owe others more',
            style: TextStyle(
              color: _textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'They Owe Me',
                  formatter.format(provider.totalOwedToMe),
                  _incomeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'I Owe Them',
                  formatter.format(provider.totalIOwe),
                  _expenseColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Settled',
                  '${provider.settledDebts.length}',
                  _purpleColor,
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

  Widget _buildDebtList(List<Debt> debts, DebtProvider provider) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_rounded,
                color: _textSecondary.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No active debts',
              style: TextStyle(color: _textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add a debt entry',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        return _buildDebtCard(context, debts[index], provider);
      },
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    Debt debt,
    DebtProvider provider,
  ) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    final color = debt.isOwedToMe ? _incomeColor : _expenseColor;
    final progressColor = _getProgressColor(debt.progress);

    return Dismissible(
      key: ValueKey(debt.id),
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
        provider.deleteDebt(debt.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleted debt: ${debt.personName}',
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
        onTap: () => _showDebtDetailSheet(context, debt, provider),
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
              // Header row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        debt.personName.isNotEmpty
                            ? debt.personName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                debt.isOwedToMe ? 'They owe me' : 'I owe',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (debt.dueDate != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.event_rounded,
                                color: _isDueOrOverdue(debt.dueDate!)
                                    ? _warningColor
                                    : _textSecondary,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                dateFormat.format(debt.dueDate!),
                                style: TextStyle(
                                  color: _isDueOrOverdue(debt.dueDate!)
                                      ? _warningColor
                                      : _textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(debt.remainingAmount),
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (debt.paidAmount > 0)
                        Text(
                          'of ${formatter.format(debt.totalAmount)}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Direct Edit button
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.edit_outlined, color: _accentColor, size: 20),
                    tooltip: 'Edit Debt',
                    onPressed: () => _showAddDebtSheet(context, debtToEdit: debt),
                  ),
                  // Direct Delete button
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.delete_outline_rounded, color: _expenseColor, size: 20),
                    tooltip: 'Delete Debt',
                    onPressed: () {
                      if (debt.id != null) {
                        provider.deleteDebt(debt.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Deleted debt: ${debt.personName}',
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

              // Description
              if (debt.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  debt.description,
                  style: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Progress bar
              if (debt.paidAmount > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: debt.progress,
                    backgroundColor: progressColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(debt.progress * 100).toInt()}% paid',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${formatter.format(debt.paidAmount)} paid',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(DebtProvider provider) {
    final settlements = provider.allSettlements;
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (settlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                color: _textSecondary.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No settlement history yet',
              style: TextStyle(color: _textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Payments and settled debts will appear here',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: settlements.length,
      itemBuilder: (context, index) {
        final settlement = settlements[index];
        final debt = provider.debts.firstWhere(
          (d) => d.id == settlement.debtId,
          orElse: () => Debt(
            personName: 'Unknown',
            totalAmount: 0,
            isOwedToMe: true,
            description: '',
            createdDate: DateTime.now(),
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _incomeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _incomeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${settlement.note} • ${dateFormat.format(settlement.date)}',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${debt.isOwedToMe ? '+' : '-'} ${formatter.format(settlement.amount)}',
                style: TextStyle(
                  color: debt.isOwedToMe ? _incomeColor : _expenseColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isDueOrOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now().add(const Duration(days: 3)));
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return _incomeColor;
    if (progress >= 0.5) return _warningColor;
    return _accentColor;
  }

  // ── Debt Detail / Payment Sheet ──
  void _showDebtDetailSheet(
    BuildContext context,
    Debt debt,
    DebtProvider provider,
  ) {
    final paymentController = TextEditingController();
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    final settlementDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final settlements = provider.getSettlementsForDebt(debt.id!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF152238),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
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

                  // Header with Edit & Delete options
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.personName,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (debt.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                debt.description,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showAddDebtSheet(context, debtToEdit: debt);
                        },
                        icon: const Icon(Icons.edit_rounded, color: _accentColor),
                        tooltip: 'Edit Debt',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (debt.id != null) {
                            provider.deleteDebt(debt.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Deleted debt: ${debt.personName}',
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
                        icon: const Icon(Icons.delete_rounded, color: _expenseColor),
                        tooltip: 'Delete Debt',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Total Amount',
                            formatter.format(debt.totalAmount)),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                            'Paid', formatter.format(debt.paidAmount)),
                        const SizedBox(height: 10),
                        _buildInfoRow('Remaining',
                            formatter.format(debt.remainingAmount)),
                        if (debt.dueDate != null) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            'Due Date',
                            dateFormat.format(debt.dueDate!),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          'Created',
                          dateFormat.format(debt.createdDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settlement History section
                  const Text(
                    'Settlement History',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (settlements.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No settlement payments recorded yet',
                        style: TextStyle(color: _textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: settlements.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: Color(0xFF1F2D42), height: 1),
                        itemBuilder: (context, index) {
                          final s = settlements[index];
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded,
                                    color: _incomeColor, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.note,
                                        style: const TextStyle(
                                          color: _textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        settlementDateFormat.format(s.date),
                                        style: const TextStyle(
                                          color: _textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatter.format(s.amount),
                                  style: const TextStyle(
                                    color: _incomeColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  if (!debt.isFullyPaid) ...[
                    // Payment input
                    TextField(
                      controller: paymentController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Payment Amount',
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

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
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
                                final amount = double.tryParse(
                                    paymentController.text.trim());
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Please enter a valid payment amount',
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
                                provider.recordPayment(debt, amount);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Recorded payment of ₹${NumberFormat('#,##0').format(amount)} for ${debt.personName}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
                              child: const Text(
                                'Record Payment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _incomeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              provider.markAsSettled(debt);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${debt.personName}\'s debt has been fully settled! 🎉',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
                            child: const Text(
                              'Settle',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Settled banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _incomeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _incomeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: _incomeColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'This debt is fully settled',
                            style: TextStyle(
                              color: _incomeColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Add / Edit Debt Sheet ──
  void _showAddDebtSheet(BuildContext context, {Debt? debtToEdit}) {
    final bool isEditing = debtToEdit != null;
    bool isOwedToMe = debtToEdit?.isOwedToMe ?? true;
    final nameController =
        TextEditingController(text: debtToEdit?.personName ?? '');
    final amountController = TextEditingController(
        text: debtToEdit != null ? debtToEdit.totalAmount.toStringAsFixed(0) : '');
    final descController =
        TextEditingController(text: debtToEdit?.description ?? '');
    DateTime? selectedDueDate = debtToEdit?.dueDate;

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
                          color: _textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit Debt' : 'Add Debt',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Direction toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => isOwedToMe = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: isOwedToMe
                                      ? _incomeColor
                                          .withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'They Owe Me',
                                    style: TextStyle(
                                      color: isOwedToMe
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
                              onTap: () =>
                                  setState(() => isOwedToMe = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isOwedToMe
                                      ? _expenseColor
                                          .withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'I Owe Them',
                                    style: TextStyle(
                                      color: !isOwedToMe
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
                    const SizedBox(height: 12),

                    // Person name
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Person Name',
                        hintStyle:
                            const TextStyle(color: _textSecondary),
                        prefixIcon: const Icon(
                            Icons.person_rounded,
                            color: _textSecondary),
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

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Amount',
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
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Description (e.g. "Lunch money")',
                        hintStyle:
                            const TextStyle(color: _textSecondary),
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

                    // Due date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() => selectedDueDate = picked);
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
                              Icons.event_rounded,
                              color: _textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedDueDate != null
                                  ? 'Due: ${DateFormat('dd MMM yyyy').format(selectedDueDate!)}'
                                  : 'Set Due Date (optional)',
                              style: TextStyle(
                                color: selectedDueDate != null
                                    ? _textPrimary
                                    : _textSecondary,
                              ),
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
                              isOwedToMe ? _incomeColor : _expenseColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amount = double.tryParse(
                              amountController.text.trim());
                          final desc = descController.text.trim();

                          if (name.isEmpty ||
                              amount == null ||
                              amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Please fill these: Name and valid amount are required',
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

                          final debt = Debt(
                            id: isEditing ? debtToEdit.id : null,
                            personName: name,
                            totalAmount: amount,
                            paidAmount: isEditing ? debtToEdit.paidAmount : 0.0,
                            isOwedToMe: isOwedToMe,
                            description: desc,
                            dueDate: selectedDueDate,
                            createdDate: isEditing
                                ? debtToEdit.createdDate
                                : DateTime.now(),
                          );

                          final provider = Provider.of<DebtProvider>(
                            context,
                            listen: false,
                          );

                          if (isEditing) {
                            provider.updateDebt(debt);
                          } else {
                            provider.addDebt(debt);
                          }

                          Navigator.of(context).pop();
                        },
                        child: Text(
                          isEditing
                              ? 'Update Debt'
                              : (isOwedToMe ? 'Add - They Owe Me' : 'Add - I Owe'),
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
