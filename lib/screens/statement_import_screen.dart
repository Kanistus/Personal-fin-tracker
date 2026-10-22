import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/categorization_engine.dart';
import '../services/statement_importer.dart';

class StatementImportScreen extends StatefulWidget {
  const StatementImportScreen({super.key});

  @override
  State<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends State<StatementImportScreen> {
  static const Color _bgColor = Color(0xFF0F1B2D);
  static const Color _cardColor = Color(0xFF1A2940);
  static const Color _accentColor = Color(0xFF3498DB);
  static const Color _incomeColor = Color(0xFF2ECC71);
  static const Color _expenseColor = Color(0xFFE74C3C);
  static const Color _warningColor = Color(0xFFF39C12);
  static const Color _textPrimary = Color(0xFFECF0F1);
  static const Color _textSecondary = Color(0xFF8899AA);

  StatementImportResult? _importResult;
  String? _selectedFileName;
  final Set<int> _selectedIndices = {};
  bool _isLoading = false;

  Future<void> _pickAndParseFile() async {
    try {
      setState(() => _isLoading = true);
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      String content;

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception('Cannot read selected file');
      }

      if (!mounted) return;
      final txnProvider = Provider.of<TransactionProvider>(context, listen: false);
      final parsed = StatementImporter.parseCsv(
        csvContent: content,
        existingTransactions: txnProvider.transactions,
      );

      setState(() {
        _selectedFileName = file.name;
        _importResult = parsed;
        _selectedIndices.clear();
        for (int i = 0; i < parsed.transactions.length; i++) {
          if (!parsed.transactions[i].isDuplicate) {
            _selectedIndices.add(i);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $e'),
            backgroundColor: _expenseColor,
          ),
        );
      }
    }
  }

  Future<void> _importSelected() async {
    if (_importResult == null || _selectedIndices.isEmpty) return;

    final txnProvider = Provider.of<TransactionProvider>(context, listen: false);
    int imported = 0;

    for (final index in _selectedIndices) {
      if (index < _importResult!.transactions.length) {
        final item = _importResult!.transactions[index];
        await txnProvider.addTransaction(item.toTransaction());
        imported++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text('Successfully imported $imported transactions!'),
            ],
          ),
          backgroundColor: _incomeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Bank Statement Import',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentColor))
          : _importResult == null
              ? _buildPickFileState()
              : _buildPreviewState(currencyProvider),
      bottomNavigationBar: _importResult != null && _selectedIndices.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _incomeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _importSelected,
                  icon: const Icon(Icons.file_download_done_rounded, size: 22),
                  label: Text(
                    'Import ${_selectedIndices.length} Selected Transactions',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPickFileState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: _accentColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Import Bank Statement (CSV)',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select a CSV statement downloaded from your bank or payment app. Finance Vault will automatically extract amounts, merchants, dates, predict categories, and check for duplicates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _pickAndParseFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Choose CSV File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState(CurrencyProvider currencyProvider) {
    final result = _importResult!;
    final items = result.transactions;

    if (result.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: _expenseColor, size: 48),
              const SizedBox(height: 14),
              Text(result.errorMessage!, style: const TextStyle(color: _textPrimary, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _pickAndParseFile, child: const Text('Pick Another File')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header summary
        Container(
          padding: const EdgeInsets.all(16),
          color: _cardColor,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFileName ?? 'Statement',
                      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items.length} detected • ${_selectedIndices.length} selected${result.duplicateCount > 0 ? " • ${result.duplicateCount} duplicate(s)" : ""}',
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickAndParseFile,
                child: const Text('Change', style: TextStyle(color: _accentColor)),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isChecked = _selectedIndices.contains(index);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: item.isDuplicate
                      ? Border.all(color: _warningColor.withValues(alpha: 0.5))
                      : null,
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  value: isChecked,
                  activeColor: _accentColor,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIndices.add(index);
                      } else {
                        _selectedIndices.remove(index);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.isIncome ? '+' : '-'} ${currencyProvider.symbol}${NumberFormat('#,##0.00').format(item.amount)}',
                        style: TextStyle(
                          color: item.isIncome ? _incomeColor : _expenseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.tryParse(item.date) ?? DateTime.now()),
                        style: const TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      // Category chip
                      InkWell(
                        onTap: () => _pickCategoryForRow(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(color: _accentColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (item.isDuplicate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Duplicate',
                            style: TextStyle(color: _warningColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _pickCategoryForRow(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF152238),
      builder: (ctx) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: CategorizationEngine.allCategories.length,
          itemBuilder: (context, i) {
            final cat = CategorizationEngine.allCategories[i];
            return ListTile(
              title: Text(cat, style: const TextStyle(color: _textPrimary)),
              onTap: () {
                setState(() {
                  _importResult!.transactions[index] = _importResult!.transactions[index].copyWith(category: cat);
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }
}
