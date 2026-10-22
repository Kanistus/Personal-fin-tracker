import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auto_transaction.dart';
import '../models/merchant_rule.dart';
import '../models/tracking_setting.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../services/transaction_parser.dart';
import '../services/categorization_engine.dart';
import '../services/duplicate_detector.dart';
import '../services/notification_bridge.dart';
import 'transaction_provider.dart';

class AutoTrackingProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  static const String _prefAutoTrackingEnabled = 'auto_tracking_enabled';
  static const String _prefAutoApproveHighConfidence = 'auto_approve_high_confidence';

  bool _isAutoTrackingEnabled = true;
  bool _autoApproveHighConfidence = true;
  bool _isNotificationAccessGranted = false;
  bool _isLoading = false;

  List<AutoTransaction> _pendingTransactions = [];
  List<AutoTransaction> _allAutoTransactions = [];
  List<MerchantRule> _merchantRules = [];
  List<TrackingSetting> _trackingSettings = [];
  AutoTransaction? _lastDetectedTransaction;

  bool get isAutoTrackingEnabled => _isAutoTrackingEnabled;
  bool get autoApproveHighConfidence => _autoApproveHighConfidence;
  bool get isNotificationAccessGranted => _isNotificationAccessGranted;
  bool get isLoading => _isLoading;

  List<AutoTransaction> get pendingTransactions => _pendingTransactions;
  List<AutoTransaction> get allAutoTransactions => _allAutoTransactions;
  List<MerchantRule> get merchantRules => _merchantRules;
  List<TrackingSetting> get trackingSettings => _trackingSettings;
  AutoTransaction? get lastDetectedTransaction => _lastDetectedTransaction;
  int get pendingCount => _pendingTransactions.length;

  Future<void> initialize(TransactionProvider? transactionProvider) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isAutoTrackingEnabled = prefs.getBool(_prefAutoTrackingEnabled) ?? true;
    _autoApproveHighConfidence = prefs.getBool(_prefAutoApproveHighConfidence) ?? true;

    await refreshPermission();
    await loadData();

    // Hook up real-time notification listener
    NotificationBridge.initialize(onNotification: (notification) {
      processNotification(notification, transactionProvider);
    });

    // Process any notifications queued while app was closed
    await processQueuedNotifications(transactionProvider);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPermission() async {
    _isNotificationAccessGranted = await NotificationBridge.isNotificationAccessGranted();
    notifyListeners();
  }

  Future<void> loadData() async {
    _pendingTransactions = await _dbHelper.getPendingAutoTransactions();
    _allAutoTransactions = await _dbHelper.getAutoTransactions();
    _merchantRules = await _dbHelper.getMerchantRules();
    _trackingSettings = await _dbHelper.getTrackingSettings();

    if (_allAutoTransactions.isNotEmpty) {
      _lastDetectedTransaction = _allAutoTransactions.first;
    }
    notifyListeners();
  }

  Future<void> setAutoTrackingEnabled(bool enabled) async {
    _isAutoTrackingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoTrackingEnabled, enabled);
    notifyListeners();
  }

  Future<void> setAutoApproveHighConfidence(bool enabled) async {
    _autoApproveHighConfidence = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoApproveHighConfidence, enabled);
    notifyListeners();
  }

  Future<void> toggleAppTracking(TrackingSetting setting, bool enabled) async {
    final updated = setting.copyWith(enabled: enabled);
    await _dbHelper.updateTrackingSetting(updated);
    _trackingSettings = await _dbHelper.getTrackingSettings();
    notifyListeners();
  }

  /// Process an incoming notification dictionary from Android listener
  Future<void> processNotification(
    Map<String, dynamic> notification,
    TransactionProvider? transactionProvider,
  ) async {
    if (!_isAutoTrackingEnabled) return;

    final packageName = notification['packageName'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final text = notification['text'] as String? ?? '';
    final bigText = notification['bigText'] as String? ?? '';
    final subText = notification['subText'] as String? ?? '';

    // Check if app is enabled in tracking settings
    final isAllowed = _trackingSettings.any((s) => s.packageName == packageName && s.enabled);
    if (!isAllowed) return;

    // Combine text fields for parsing
    final combinedText = '$title. $text. $bigText. $subText'.trim();
    final parsed = TransactionParser.parse(combinedText, packageName);

    if (!parsed.isValid || parsed.amount == null || parsed.amount! <= 0) {
      return;
    }

    final amount = parsed.amount!;
    final merchant = parsed.merchant?.isNotEmpty == true
        ? parsed.merchant!
        : (title.isNotEmpty ? title : 'Merchant');
    final type = parsed.transactionType;

    // Smart Categorization
    final catResult = CategorizationEngine.categorize(
      merchant: merchant,
      transactionType: type,
      description: combinedText,
      merchantRules: _merchantRules,
    );

    // Duplicate detection
    final manualTxns = transactionProvider?.transactions ?? [];
    final candidateAuto = AutoTransaction(
      amount: amount,
      merchant: merchant,
      rawNotification: combinedText,
      sourceApp: packageName,
      transactionType: type,
      category: catResult.category,
      confidence: catResult.confidence,
      upiRef: parsed.upiRef,
      date: DateTime.now(),
      status: 'pending_review',
    );

    final dupCheck = DuplicateDetector.checkAll(
      newTxn: candidateAuto,
      autoTransactions: _allAutoTransactions,
      manualTransactions: manualTxns,
    );

    String status = 'pending_review';
    int? linkedTxnId;

    if (dupCheck.isDuplicate) {
      status = 'duplicate';
    } else if (catResult.isHighConfidence && _autoApproveHighConfidence && transactionProvider != null) {
      // Auto-save high confidence transactions
      final isIncome = type == 'income' || type == 'refund';
      final newManual = Transaction(
        title: merchant,
        amount: amount,
        isIncome: isIncome,
        category: catResult.category,
        date: candidateAuto.date,
      );
      await transactionProvider.addTransaction(newManual);
      status = 'auto_saved';

      // Find ID of newly created manual transaction if possible
      if (transactionProvider.transactions.isNotEmpty) {
        linkedTxnId = transactionProvider.transactions.first.id;
      }
    }

    final toSave = candidateAuto.copyWith(
      status: status,
      linkedTransactionId: linkedTxnId,
      duplicateGroupId: dupCheck.hasMatch ? DuplicateDetector.generateDuplicateGroupId() : null,
    );

    await _dbHelper.insertAutoTransaction(toSave);
    await loadData();
  }

  Future<void> processQueuedNotifications(TransactionProvider? transactionProvider) async {
    final queued = await NotificationBridge.getQueuedNotifications();
    if (queued.isEmpty) return;

    for (final notif in queued) {
      await processNotification(notif, transactionProvider);
    }
    await NotificationBridge.clearQueuedNotifications();
  }

  /// User approves a pending transaction
  Future<void> approveTransaction(
    AutoTransaction autoTxn,
    TransactionProvider transactionProvider, {
    String? category,
    double? amount,
    String? merchant,
  }) async {
    final finalCategory = category ?? autoTxn.category;
    final finalAmount = amount ?? autoTxn.amount;
    final finalTitle = merchant ?? autoTxn.merchant;
    final isIncome = autoTxn.transactionType == 'income' || autoTxn.transactionType == 'refund';

    // 1. Create main transaction
    final newManual = Transaction(
      title: finalTitle,
      amount: finalAmount,
      isIncome: isIncome,
      category: finalCategory,
      date: autoTxn.date,
    );
    await transactionProvider.addTransaction(newManual);

    // 2. Update auto-transaction status
    final updatedAuto = autoTxn.copyWith(
      status: 'confirmed',
      category: finalCategory,
      amount: finalAmount,
      merchant: finalTitle,
    );
    await _dbHelper.updateAutoTransaction(updatedAuto);

    // 3. Save merchant rule if user changed or specified category
    if (finalCategory != 'Other' && finalTitle.isNotEmpty) {
      await saveMerchantRule(finalTitle, finalCategory, autoTxn.transactionType);
    }

    await loadData();
  }

  /// User rejects an auto-detected transaction
  Future<void> rejectTransaction(AutoTransaction autoTxn) async {
    final updated = autoTxn.copyWith(status: 'rejected');
    await _dbHelper.updateAutoTransaction(updated);
    await loadData();
  }

  /// Approve all pending transactions in one tap
  Future<void> approveAllPending(TransactionProvider transactionProvider) async {
    for (final txn in List.from(_pendingTransactions)) {
      await approveTransaction(txn, transactionProvider);
    }
  }

  /// Save or update user merchant rule
  Future<void> saveMerchantRule(String merchant, String category, [String type = 'expense']) async {
    final pattern = CategorizationEngine.normalizeMerchant(merchant);
    if (pattern.isEmpty) return;

    final rule = MerchantRule(
      merchantPattern: pattern,
      category: category,
      transactionType: type,
    );
    await _dbHelper.insertMerchantRule(rule);
    _merchantRules = await _dbHelper.getMerchantRules();
    notifyListeners();
  }

  Future<void> deleteMerchantRule(int id) async {
    await _dbHelper.deleteMerchantRule(id);
    _merchantRules = await _dbHelper.getMerchantRules();
    notifyListeners();
  }

  Future<void> deleteAutoTransaction(int id) async {
    await _dbHelper.deleteAutoTransaction(id);
    await loadData();
  }

  Future<void> clearAll() async {
    await _dbHelper.clearAllAutoTransactions();
    await loadData();
  }
}
