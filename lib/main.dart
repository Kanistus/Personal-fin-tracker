import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/currency_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/spending_screen.dart';
import 'screens/debt_screen.dart';
import 'screens/more_screen.dart';
import 'services/sms_bridge.dart';
import 'models/auto_transaction.dart';
import 'models/transaction.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersonalFinApp());
}

class PersonalFinApp extends StatelessWidget {
  const PersonalFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadTransactions(),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider()..loadBudgets(),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider()..loadDebts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider()..loadCurrency(),
        ),
      ],
      child: MaterialApp(
        title: 'Fintracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3498DB),
        ),
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  StreamSubscription<AutoTransaction>? _smsSubscription;

  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _textSecondary = Color(0xFF8899AA);

  @override
  void initState() {
    super.initState();
    _initSmsTracking();
  }

  void _initSmsTracking() {
    SmsBridge.initialize();

    // Process any SMS that arrived while app was closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final queued = await SmsBridge.processQueuedSms();
      for (final auto in queued) {
        final saved = await provider.processAndAddAutoTransaction(auto);
        if (saved != null && mounted) {
          _showAutoDetectedSnackbar(saved);
        }
      }
    });

    // Listen for live SMS while app is open
    _smsSubscription = SmsBridge.transactionStream.listen((auto) async {
      if (!mounted) return;
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final saved = await provider.processAndAddAutoTransaction(auto);
      if (saved != null && mounted) {
        _showAutoDetectedSnackbar(saved);
      }
    });
  }

  void _showAutoDetectedSnackbar(Transaction txn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sms_rounded, color: Color(0xFF2ECC71), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-detected: ₹${txn.amount.toStringAsFixed(txn.amount.truncateToDouble() == txn.amount ? 0 : 2)} at ${txn.title} (${txn.category})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFF1C40F),
          onPressed: () {
            if (txn.id != null) {
              Provider.of<TransactionProvider>(context, listen: false)
                  .deleteTransaction(txn.id!);
            }
          },
        ),
        backgroundColor: const Color(0xFF1A2940),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2ECC71), width: 1),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    SpendingScreen(),
    BudgetScreen(),
    DebtScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: _bgColor,
          selectedItemColor: _accentColor,
          unselectedItemColor: _textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Spending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_rounded),
              label: 'Debts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
