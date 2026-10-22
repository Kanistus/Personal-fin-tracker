import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'categorization_engine.dart';

class StatementTransaction {
  final String date;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final bool isDuplicate;
  final String? rawRow;

  StatementTransaction({
    required this.date,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    this.isDuplicate = false,
    this.rawRow,
  });

  Transaction toTransaction() {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return Transaction(
      title: title,
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: parsedDate,
    );
  }

  StatementTransaction copyWith({
    String? category,
    bool? isDuplicate,
  }) {
    return StatementTransaction(
      date: date,
      title: title,
      amount: amount,
      isIncome: isIncome,
      category: category ?? this.category,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      rawRow: rawRow,
    );
  }
}

class StatementImportResult {
  final List<StatementTransaction> transactions;
  final int totalRows;
  final int validCount;
  final int duplicateCount;
  final String? errorMessage;

  StatementImportResult({
    required this.transactions,
    required this.totalRows,
    required this.validCount,
    required this.duplicateCount,
    this.errorMessage,
  });
}

class StatementImporter {
  /// Parse a CSV file string into structured transactions.
  static StatementImportResult parseCsv({
    required String csvContent,
    List<Transaction> existingTransactions = const [],
  }) {
    try {
      const converter = CsvToListConverter(shouldParseNumbers: false);
      final rows = converter.convert(csvContent);

      if (rows.isEmpty) {
        return StatementImportResult(
          transactions: [],
          totalRows: 0,
          validCount: 0,
          duplicateCount: 0,
          errorMessage: 'CSV file is empty',
        );
      }

      // Find header row (usually contains keywords like date, description, amount, debit, credit)
      int headerIndex = -1;
      int dateCol = -1;
      int descCol = -1;
      int debitCol = -1;
      int creditCol = -1;
      int amountCol = -1;
      int typeCol = -1;

      for (int i = 0; i < rows.length && i < 10; i++) {
        final row = rows[i].map((e) => e.toString().toLowerCase().trim()).toList();
        for (int j = 0; j < row.length; j++) {
          final cell = row[j];
          if (cell.contains('date') || cell.contains('txn date') || cell.contains('value date')) {
            dateCol = j;
          } else if (cell.contains('desc') || cell.contains('narration') || cell.contains('particular') || cell.contains('remark')) {
            descCol = j;
          } else if (cell.contains('debit') || cell.contains('withdrawal')) {
            debitCol = j;
          } else if (cell.contains('credit') || cell.contains('deposit')) {
            creditCol = j;
          } else if (cell.contains('amount') || cell.contains('txn amount')) {
            amountCol = j;
          } else if (cell == 'type' || cell == 'cr/dr' || cell == 'dr/cr') {
            typeCol = j;
          }
        }

        if (dateCol != -1 && (descCol != -1 || amountCol != -1 || debitCol != -1)) {
          headerIndex = i;
          break;
        }
      }

      // Fallback default column indexes if header wasn't clearly recognized
      if (headerIndex == -1) {
        headerIndex = 0;
        dateCol = 0;
        descCol = 1;
        amountCol = 2;
      }

      final List<StatementTransaction> parsed = [];
      int dupes = 0;

      for (int i = headerIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

        final dateStr = (dateCol >= 0 && dateCol < row.length) ? row[dateCol].toString().trim() : '';
        final descStr = (descCol >= 0 && descCol < row.length) ? row[descCol].toString().trim() : 'Transaction';

        double amount = 0.0;
        bool isIncome = false;

        if (debitCol >= 0 && creditCol >= 0) {
          final debitStr = debitCol < row.length ? row[debitCol].toString().trim() : '';
          final creditStr = creditCol < row.length ? row[creditCol].toString().trim() : '';

          final debitVal = _parseAmount(debitStr);
          final creditVal = _parseAmount(creditStr);

          if (creditVal > 0) {
            amount = creditVal;
            isIncome = true;
          } else if (debitVal > 0) {
            amount = debitVal;
            isIncome = false;
          }
        } else if (amountCol >= 0 && amountCol < row.length) {
          final val = _parseAmount(row[amountCol].toString());
          amount = val.abs();

          if (typeCol >= 0 && typeCol < row.length) {
            final typeStr = row[typeCol].toString().toLowerCase();
            isIncome = typeStr.contains('cr') || typeStr.contains('credit') || typeStr.contains('deposit');
          } else {
            // Check if amount was negative
            isIncome = row[amountCol].toString().contains('+');
          }
        }

        if (amount <= 0) continue;

        final parsedDate = _parseDate(dateStr);
        final dateIso = parsedDate.toIso8601String();

        // Categorize
        final catResult = CategorizationEngine.categorize(
          merchant: descStr,
          transactionType: isIncome ? 'income' : 'expense',
        );

        // Duplicate check
        bool isDup = false;
        for (final existing in existingTransactions) {
          final sameAmount = (existing.amount - amount).abs() < 0.01;
          final sameType = existing.isIncome == isIncome;
          final diffDays = (existing.date.difference(parsedDate).inHours).abs() < 48;
          if (sameAmount && sameType && diffDays) {
            isDup = true;
            dupes++;
            break;
          }
        }

        parsed.add(StatementTransaction(
          date: dateIso,
          title: descStr.length > 50 ? descStr.substring(0, 50) : descStr,
          amount: amount,
          isIncome: isIncome,
          category: catResult.category,
          isDuplicate: isDup,
          rawRow: row.join(','),
        ));
      }

      return StatementImportResult(
        transactions: parsed,
        totalRows: rows.length - (headerIndex + 1),
        validCount: parsed.length,
        duplicateCount: dupes,
      );
    } catch (e) {
      return StatementImportResult(
        transactions: [],
        totalRows: 0,
        validCount: 0,
        duplicateCount: 0,
        errorMessage: 'Failed to parse statement: $e',
      );
    }
  }

  static double _parseAmount(String val) {
    if (val.trim().isEmpty) return 0.0;
    final cleaned = val.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime _parseDate(String val) {
    if (val.trim().isEmpty) return DateTime.now();

    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd MMM yyyy',
      'dd/MM/yy',
      'dd-MM-yy',
      'MM/dd/yyyy',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(val.trim());
      } catch (_) {}
    }

    return DateTime.tryParse(val) ?? DateTime.now();
  }
}
