import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/debt_settlement.dart';
import '../models/auto_transaction.dart';
import '../models/merchant_rule.dart';
import '../models/tracking_setting.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'personal_fin.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            isIncome INTEGER NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            budgetLimit REAL NOT NULL,
            month TEXT NOT NULL,
            UNIQUE(category, month)
          )
        ''');
        await db.execute('''
          CREATE TABLE debts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            personName TEXT NOT NULL,
            totalAmount REAL NOT NULL,
            paidAmount REAL NOT NULL DEFAULT 0,
            isOwedToMe INTEGER NOT NULL,
            description TEXT NOT NULL,
            dueDate TEXT,
            createdDate TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE debt_settlements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            debtId INTEGER NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');
        await _createAutoTrackingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE budgets(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT NOT NULL,
              budgetLimit REAL NOT NULL,
              month TEXT NOT NULL,
              UNIQUE(category, month)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE debts(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              personName TEXT NOT NULL,
              totalAmount REAL NOT NULL,
              paidAmount REAL NOT NULL DEFAULT 0,
              isOwedToMe INTEGER NOT NULL,
              description TEXT NOT NULL,
              dueDate TEXT,
              createdDate TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE debt_settlements(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              debtId INTEGER NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              note TEXT
            )
          ''');
        }
        if (oldVersion < 5) {
          await _createAutoTrackingTables(db);
        }
      },
    );
  }

  static Future<void> _createAutoTrackingTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE auto_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        rawNotification TEXT,
        sourceApp TEXT NOT NULL,
        transactionType TEXT NOT NULL DEFAULT 'expense',
        category TEXT NOT NULL DEFAULT 'Other',
        confidence TEXT NOT NULL DEFAULT 'low',
        status TEXT NOT NULL DEFAULT 'pending_review',
        upiRef TEXT,
        date TEXT NOT NULL,
        linkedTransactionId INTEGER,
        duplicateGroupId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE merchant_rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchantPattern TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        transactionType TEXT NOT NULL DEFAULT 'expense',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tracking_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL UNIQUE,
        appName TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        addedAt TEXT NOT NULL
      )
    ''');
  }

  // --- Transactions ---

  Future<int> insertTransaction(Transaction txn) async {
    final db = await database;
    return await db.insert('transactions', txn.toMap());
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction txn) async {
    final db = await database;
    return await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getExpenseByCategory(String category, String month) async {
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT SUM(amount) as total FROM transactions 
         WHERE isIncome = 0 AND category = ? AND date LIKE ?''',
      [category, '$month%'],
    );
    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  // --- Budgets ---

  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> getBudgets(String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // --- Debts ---

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<Debt>> getDebts() async {
    final db = await database;
    final maps = await db.query('debts', orderBy: 'createdDate DESC');
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await database;
    await db.delete('debt_settlements', where: 'debtId = ?', whereArgs: [id]);
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Debt Settlements ---

  Future<int> insertDebtSettlement(DebtSettlement settlement) async {
    final db = await database;
    return await db.insert('debt_settlements', settlement.toMap());
  }

  Future<List<DebtSettlement>> getSettlementsForDebt(int debtId) async {
    final db = await database;
    final maps = await db.query(
      'debt_settlements',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => DebtSettlement.fromMap(map)).toList();
  }

  Future<List<DebtSettlement>> getAllSettlements() async {
    final db = await database;
    final maps = await db.query('debt_settlements', orderBy: 'date DESC');
    return maps.map((map) => DebtSettlement.fromMap(map)).toList();
  }

  // --- Auto Transactions ---

  Future<int> insertAutoTransaction(AutoTransaction txn) async {
    final db = await database;
    return await db.insert('auto_transactions', txn.toMap());
  }

  Future<List<AutoTransaction>> getAutoTransactions({String? status}) async {
    final db = await database;
    final maps = await db.query(
      'auto_transactions',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'date DESC',
    );
    return maps.map((map) => AutoTransaction.fromMap(map)).toList();
  }

  Future<List<AutoTransaction>> getPendingAutoTransactions() async {
    final db = await database;
    final maps = await db.query(
      'auto_transactions',
      where: 'status = ?',
      whereArgs: ['pending_review'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => AutoTransaction.fromMap(map)).toList();
  }

  Future<int> updateAutoTransaction(AutoTransaction txn) async {
    final db = await database;
    return await db.update(
      'auto_transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<int> deleteAutoTransaction(int id) async {
    final db = await database;
    return await db.delete('auto_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllAutoTransactions() async {
    final db = await database;
    return await db.delete('auto_transactions');
  }

  // --- Merchant Rules ---

  Future<int> insertMerchantRule(MerchantRule rule) async {
    final db = await database;
    return await db.insert(
      'merchant_rules',
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MerchantRule>> getMerchantRules() async {
    final db = await database;
    final maps = await db.query('merchant_rules', orderBy: 'merchantPattern ASC');
    return maps.map((map) => MerchantRule.fromMap(map)).toList();
  }

  Future<MerchantRule?> findMerchantRule(String pattern) async {
    final db = await database;
    final maps = await db.query(
      'merchant_rules',
      where: 'merchantPattern = ?',
      whereArgs: [pattern],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MerchantRule.fromMap(maps.first);
  }

  Future<int> deleteMerchantRule(int id) async {
    final db = await database;
    return await db.delete('merchant_rules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Tracking Settings ---

  Future<int> insertTrackingSetting(TrackingSetting setting) async {
    final db = await database;
    return await db.insert(
      'tracking_settings',
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TrackingSetting>> getTrackingSettings() async {
    final db = await database;
    final maps = await db.query('tracking_settings', orderBy: 'appName ASC');
    if (maps.isEmpty) {
      // Initialize with default apps
      for (final app in TrackingSetting.getDefaultApps()) {
        await insertTrackingSetting(app);
      }
      final newMaps = await db.query('tracking_settings', orderBy: 'appName ASC');
      return newMaps.map((map) => TrackingSetting.fromMap(map)).toList();
    }
    return maps.map((map) => TrackingSetting.fromMap(map)).toList();
  }

  Future<int> updateTrackingSetting(TrackingSetting setting) async {
    final db = await database;
    return await db.update(
      'tracking_settings',
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }
}
