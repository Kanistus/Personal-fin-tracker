import 'dart:async';
import 'package:flutter/services.dart';
import '../models/auto_transaction.dart';
import 'transaction_parser.dart';
import 'categorization_engine.dart';

class SmsBridge {
  static const MethodChannel _channel = MethodChannel('com.personalfin/sms');

  static final StreamController<AutoTransaction> _transactionStreamController =
      StreamController<AutoTransaction>.broadcast();

  static Stream<AutoTransaction> get transactionStream =>
      _transactionStreamController.stream;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final Map<dynamic, dynamic>? data =
            call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          _handleRawSms(Map<String, dynamic>.from(data));
        }
      }
    });
  }

  static Future<bool> isSmsPermissionGranted() async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('isSmsPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestSmsPermission() async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('requestSmsPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AutoTransaction>> processQueuedSms() async {
    try {
      final List<dynamic>? queued =
          await _channel.invokeMethod<List<dynamic>>('getQueuedSms');
      final List<AutoTransaction> transactions = [];

      if (queued != null && queued.isNotEmpty) {
        for (final item in queued) {
          final map = Map<String, dynamic>.from(item as Map);
          final txn = _parseSmsToAutoTransaction(map);
          if (txn != null) {
            transactions.add(txn);
          }
        }
        await _channel.invokeMethod('clearQueuedSms');
      }

      return transactions;
    } catch (_) {
      return [];
    }
  }

  static void _handleRawSms(Map<String, dynamic> data) {
    final txn = _parseSmsToAutoTransaction(data);
    if (txn != null) {
      _transactionStreamController.add(txn);
    }
  }

  static AutoTransaction? _parseSmsToAutoTransaction(Map<String, dynamic> data) {
    final sender = data['sender'] as String? ?? 'SMS';
    final body = data['body'] as String? ?? '';
    final timestamp = data['timestamp'] as int? ??
        DateTime.now().millisecondsSinceEpoch;

    final parsed = TransactionParser.parse(body, 'sms');

    if (!parsed.isValid || parsed.amount == null || parsed.amount! <= 0) {
      return null;
    }

    final catResult = CategorizationEngine.categorize(
      merchant: parsed.merchant ?? sender,
      description: body,
      transactionType: parsed.transactionType,
    );

    return AutoTransaction(
      amount: parsed.amount!,
      merchant: parsed.merchant?.isNotEmpty == true
          ? parsed.merchant!
          : sender,
      rawNotification: body,
      sourceApp: 'sms',
      transactionType: parsed.transactionType,
      category: catResult.category,
      confidence: catResult.confidence,
      status: 'auto_saved',
      upiRef: parsed.upiRef,
      date: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}
