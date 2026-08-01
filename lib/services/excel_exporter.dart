import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/debt_settlement.dart';

class ExcelExporter {
  static Future<void> exportAndShare({
    required List<Transaction> transactions,
    List<Budget>? budgets,
    Map<String, double>? spentMap,
    List<Debt>? debts,
    List<DebtSettlement>? settlements,
    String currencySymbol = '₹',
    int currencyDecimals = 0,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: currencyDecimals);

    // ── Sheet 1: Transactions ──
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
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
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

    txnSheet.setColumnWidth(0, 14);
    txnSheet.setColumnWidth(1, 25);
    txnSheet.setColumnWidth(2, 16);
    txnSheet.setColumnWidth(3, 10);
    txnSheet.setColumnWidth(4, 14);

    // ── Sheet 2: Budget vs Expense ──
    final budgetSheet = excel['Budget vs Expense'];

    final bHeaders = [
      'Category',
      'Budget Limit',
      'Actual Expense (Spent)',
      'Budget vs Expense (Variance)',
      'Status',
      '% Used'
    ];
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

    double grandTotalBudget = 0;
    double grandTotalSpent = 0;

    if (budgets != null && budgets.isNotEmpty) {
      for (int i = 0; i < budgets.length; i++) {
        final b = budgets[i];
        final spent = spentMap?[b.category] ?? 0.0;
        final variance = b.limit - spent; // positive = Under budget, negative = Over budget
        final pctUsed = b.limit > 0 ? (spent / b.limit * 100) : 0.0;
        final status = variance >= 0 ? 'Within Budget' : 'Over Budget';
        final row = i + 1;

        grandTotalBudget += b.limit;
        grandTotalSpent += spent;

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
            .value = DoubleCellValue(variance);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(status);
        budgetSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue('${pctUsed.toStringAsFixed(1)}%');
      }

      final bSummaryRow = budgets.length + 2;
      final totalVariance = grandTotalBudget - grandTotalSpent;
      final totalPct = grandTotalBudget > 0 ? (grandTotalSpent / grandTotalBudget * 100) : 0.0;
      final totalStatus = totalVariance >= 0 ? 'Within Budget' : 'Over Budget';

      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow))
          .value = TextCellValue('OVERALL SUMMARY');
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow))
          .cellStyle = CellStyle(bold: true);

      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow + 1))
          .value = TextCellValue('Total Budget Limit');
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: bSummaryRow + 1))
          .value = DoubleCellValue(grandTotalBudget);

      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow + 2))
          .value = TextCellValue('Total Actual Expense');
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: bSummaryRow + 2))
          .value = DoubleCellValue(grandTotalSpent);

      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow + 3))
          .value = TextCellValue('Total Variance');
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: bSummaryRow + 3))
          .value = DoubleCellValue(totalVariance);

      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: bSummaryRow + 4))
          .value = TextCellValue('Overall Status');
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: bSummaryRow + 4))
          .value = TextCellValue('$totalStatus (${totalPct.toStringAsFixed(1)}% used)');
    } else {
      budgetSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue('No active budgets configured.');
    }

    budgetSheet.setColumnWidth(0, 18);
    budgetSheet.setColumnWidth(1, 16);
    budgetSheet.setColumnWidth(2, 22);
    budgetSheet.setColumnWidth(3, 26);
    budgetSheet.setColumnWidth(4, 16);
    budgetSheet.setColumnWidth(5, 12);

    // ── Sheet 3: Debts & Settlements ──
    if (debts != null && debts.isNotEmpty) {
      final debtSheet = excel['Debts & Settlements'];

      final dHeaders = [
        'Person Name',
        'Total Amount',
        'Paid Amount',
        'Remaining Amount',
        'Type',
        'Status',
        'Due Date'
      ];
      for (int i = 0; i < dHeaders.length; i++) {
        final cell = debtSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(dHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ExcelColor.fromHexString('#1A2940'),
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int i = 0; i < debts.length; i++) {
        final d = debts[i];
        final row = i + 1;

        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(d.personName);
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = DoubleCellValue(d.totalAmount);
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = DoubleCellValue(d.paidAmount);
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(d.remainingAmount);
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(d.isOwedToMe ? 'They Owe Me' : 'I Owe Them');
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(d.isFullyPaid ? 'Settled' : 'Active');
        debtSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(
                d.dueDate != null ? dateFormat.format(d.dueDate!) : 'None');
      }

      debtSheet.setColumnWidth(0, 18);
      debtSheet.setColumnWidth(1, 14);
      debtSheet.setColumnWidth(2, 14);
      debtSheet.setColumnWidth(3, 16);
      debtSheet.setColumnWidth(4, 14);
      debtSheet.setColumnWidth(5, 12);
      debtSheet.setColumnWidth(6, 14);
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
        subject: 'Personal Finance Full Report',
      );
    }
  }
}
