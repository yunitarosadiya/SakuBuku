import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/transactions/data/models/transaction_model.dart';

class DatabaseHelper {
  static const String _dbName = 'sakubuku.db';
  static const int _dbVersion = 1;
  static const String tableTransactions = 'transactions';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Buat tabel transactions
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        receipt_image_path TEXT,
        receipt_size_bytes INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // Buat Indexing untuk kueri cepat instan (<2ms)
    await db.execute('CREATE INDEX idx_trans_date ON $tableTransactions(date DESC)');
    await db.execute('CREATE INDEX idx_trans_type ON $tableTransactions(type)');
    await db.execute('CREATE INDEX idx_trans_category ON $tableTransactions(category)');
  }

  // --- CRUD Operations ---

  Future<int> insertTransaction(TransactionModel item) async {
    final db = await database;
    return await db.insert(
      tableTransactions,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(TransactionModel item) async {
    final db = await database;
    if (item.id == null) return 0;
    return await db.update(
      tableTransactions,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  Future<List<TransactionModel>> getAllTransactions({int? limit, int? offset}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsToday() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfMonth, endOfMonth],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // --- Financial Summary & Analytics ---

  /// Mengambil total saldo keseluruhan (sepanjang waktu)
  Future<Map<String, double>> getTotalBalanceSummary() async {
    final db = await database;
    final resIncome = await db.rawQuery(
      "SELECT SUM(amount) as total FROM $tableTransactions WHERE type = 'INCOME'"
    );
    final resExpense = await db.rawQuery(
      "SELECT SUM(amount) as total FROM $tableTransactions WHERE type = 'EXPENSE'"
    );

    final double totalIncome = (resIncome.first['total'] as num?)?.toDouble() ?? 0.0;
    final double totalExpense = (resExpense.first['total'] as num?)?.toDouble() ?? 0.0;
    final double currentBalance = totalIncome - totalExpense;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'currentBalance': currentBalance,
    };
  }

  /// Mengambil ringkasan pemasukan & pengeluaran untuk bulan tertentu
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final resIncome = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $tableTransactions 
      WHERE type = 'INCOME' AND date >= ? AND date <= ?
    ''', [startOfMonth, endOfMonth]);

    final resExpense = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $tableTransactions 
      WHERE type = 'EXPENSE' AND date >= ? AND date <= ?
    ''', [startOfMonth, endOfMonth]);

    final double monthlyIncome = (resIncome.first['total'] as num?)?.toDouble() ?? 0.0;
    final double monthlyExpense = (resExpense.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
      'monthlyNet': monthlyIncome - monthlyExpense,
    };
  }

  /// Tren pengeluaran 7 hari terakhir (untuk mini line chart)
  Future<List<Map<String, dynamic>>> getDailyExpenseTrend(int days) async {
    final db = await database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    final res = await db.rawQuery('''
      SELECT substr(date, 1, 10) as day_date, SUM(amount) as total 
      FROM $tableTransactions 
      WHERE type = 'EXPENSE' AND date >= ? 
      GROUP BY day_date 
      ORDER BY day_date ASC
    ''', [startDate.toIso8601String()]);

    return res;
  }

  /// Breakdown pengeluaran per kategori (untuk pie chart)
  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required int year,
    required int month,
    String type = 'EXPENSE',
  }) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final res = await db.rawQuery('''
      SELECT category, SUM(amount) as total, COUNT(*) as count 
      FROM $tableTransactions 
      WHERE type = ? AND date >= ? AND date <= ? 
      GROUP BY category 
      ORDER BY total DESC
    ''', [type, startOfMonth, endOfMonth]);

    return res;
  }

  /// Menghitung ukuran file database SQLite dalam byte
  Future<int> getDatabaseFileSize() async {
    if (kIsWeb) return 0;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  /// Menghapus seluruh transaksi (reset database lokal)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableTransactions);
  }
}
