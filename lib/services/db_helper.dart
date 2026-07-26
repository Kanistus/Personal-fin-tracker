import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/debt.dart';

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
      version: 3,
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
      },
    );
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
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }
}
