import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class ExcelExporter {
  static Future<void> exportAndShare({
    required List<Transaction> transactions,
    List<Budget>? budgets,
    Map<String, double>? spentMap,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    // ── Transactions Sheet ──
    excel.rename('Sheet1', 'Transactions');
    final txnSheet = excel['Transactions'];

    // Header row
    final headers = ['Date', 'Title', 'Category', 'Type', 'Amount'];
    for (int i = 0; i < headers.length; i++) {
      final cell = txnSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1A2940'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Data rows
    double totalIncome = 0;
    double totalExpense = 0;
    for (int i = 0; i < transactions.length; i++) {
      final txn = transactions[i];
      final row = i + 1;

      txnSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(dateFormat.format(txn.date));
      txnSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(txn.title);
      txnSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(txn.category);
      txnSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(txn.isIncome ? 'Income' : 'Expense');
      txnSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(txn.amount);

      if (txn.isIncome) {
        totalIncome += txn.amount;
      } else {
        totalExpense += txn.amount;
      }
    }

    // Summary row
    final summaryRow = transactions.length + 2;
    txnSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .value = TextCellValue('SUMMARY');
    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: summaryRow))
        .cellStyle = CellStyle(bold: true);

    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: summaryRow + 1))
        .value = TextCellValue('Total Income');
    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: summaryRow + 1))
        .value = TextCellValue(currencyFormat.format(totalIncome));

    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: summaryRow + 2))
        .value = TextCellValue('Total Expense');
    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: summaryRow + 2))
        .value = TextCellValue(currencyFormat.format(totalExpense));

    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: summaryRow + 3))
        .value = TextCellValue('Balance');
    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: summaryRow + 3))
        .value =
        TextCellValue(currencyFormat.format(totalIncome - totalExpense));
    txnSheet
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: summaryRow + 3))
        .cellStyle = CellStyle(bold: true);

    // Set column widths
    txnSheet.setColumnWidth(0, 14);
    txnSheet.setColumnWidth(1, 25);
    txnSheet.setColumnWidth(2, 16);
    txnSheet.setColumnWidth(3, 10);
    txnSheet.setColumnWidth(4, 14);

    // ── Budget Sheet (if budgets available) ──
    if (budgets != null && budgets.isNotEmpty) {
      final budgetSheet = excel['Budgets'];

      final bHeaders = ['Category', 'Budget Limit', 'Spent', 'Remaining', '% Used'];
      for (int i = 0; i < bHeaders.length; i++) {
        final cell = budgetSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(bHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ExcelColor.fromHexString('#1A2940'),
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int i = 0; i < budgets.length; i++) {
        final b = budgets[i];
        final spent = spentMap?[b.category] ?? 0.0;
        final remaining = b.limit - spent;
        final pctUsed = b.limit > 0 ? (spent / b.limit * 100) : 0.0;
        final row = i + 1;

        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(b.category);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = DoubleCellValue(b.limit);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = DoubleCellValue(spent);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(remaining);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue('${pctUsed.toStringAsFixed(1)}%');
      }

      budgetSheet.setColumnWidth(0, 18);
      budgetSheet.setColumnWidth(1, 14);
      budgetSheet.setColumnWidth(2, 14);
      budgetSheet.setColumnWidth(3, 14);
      budgetSheet.setColumnWidth(4, 10);
    }

    // Save and share
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${dir.path}/finance_report_$timestamp.xlsx';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Personal Finance Report',
      );
    }
  }
}
