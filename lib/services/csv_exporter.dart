import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class CsvExporter {
  static Future<void> exportAndShare(List<Transaction> transactions) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Header row
    final List<List<String>> rows = [
      ['Date', 'Title', 'Category', 'Type', 'Amount'],
    ];

    // Data rows
    for (final txn in transactions) {
      rows.add([
        dateFormat.format(txn.date),
        txn.title,
        txn.category,
        txn.isIncome ? 'Income' : 'Expense',
        txn.amount.toStringAsFixed(2),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    // Write to temp file
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/transactions_$timestamp.csv');
    await file.writeAsString(csvData);

    // Share via system share sheet
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Personal Finance Transactions',
    );
  }
}
