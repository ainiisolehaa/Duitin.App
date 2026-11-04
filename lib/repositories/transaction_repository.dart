import 'package:sqflite/sqflite.dart' hide Transaction;

import '../database/database_helper.dart';
import '../models/transaction.dart';

/// Repository untuk operasi CRUD dan query transaksi pada SQLite.
class TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ──────────── CREATE ────────────

  /// Tambah transaksi baru. Mengembalikan ID transaksi.
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────── READ ────────────

  /// Ambil transaksi berdasarkan ID.
  Future<Transaction?> getTransactionById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  /// Ambil semua transaksi milik user tertentu (terbaru di atas).
  Future<List<Transaction>> getTransactionsByUserId(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Ambil transaksi dengan kombinasi filter dan pencarian langsung dari SQLite.
  ///
  /// Mendukung pencarian teks (kategori/catatan), jenis transaksi (income/expense),
  /// filter kategori, dan rentang tanggal yang dapat digunakan bersamaan.
  Future<List<Transaction>> getTransactionsFiltered({
    required int userId,
    String? searchQuery,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = ['user_id = ?'];
    final List<dynamic> whereArgs = [userId];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(category LIKE ? OR note LIKE ?)');
      final pattern = '%${searchQuery.trim()}%';
      whereArgs.add(pattern);
      whereArgs.add(pattern);
    }

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.index);
    }

    if (category != null && category.trim().isNotEmpty && category != 'Semua') {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }

    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      whereClauses.add('date >= ?');
      whereArgs.add(start.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      whereClauses.add('date <= ?');
      whereArgs.add(end.millisecondsSinceEpoch);
    }

    final whereString = whereClauses.join(' AND ');
    final maps = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Ambil daftar kategori unik yang pernah digunakan oleh user.
  Future<List<String>> getDistinctCategories(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM transactions WHERE user_id = ? ORDER BY category ASC',
      [userId],
    );
    return results.map((r) => r['category'] as String).toList();
  }

  /// Ambil transaksi milik user pada rentang tanggal tertentu.
  Future<List<Transaction>> getTransactionsByDateRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Ambil transaksi berdasarkan kategori untuk user tertentu.
  Future<List<Transaction>> getTransactionsByCategory({
    required int userId,
    required String category,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Ambil transaksi berdasarkan tipe (income/expense).
  Future<List<Transaction>> getTransactionsByType({
    required int userId,
    required TransactionType type,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, type.index],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Hitung total amount berdasarkan tipe (income/expense) untuk user.
  Future<double> getTotalByType({
    required int userId,
    required TransactionType type,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total '
      'FROM transactions WHERE user_id = ? AND type = ?',
      [userId, type.index],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Hitung total pengeluaran per kategori pada bulan/tahun tertentu.
  Future<Map<String, double>> getExpenseSummaryByCategory({
    required int userId,
    required int month,
    required int year,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total '
      'FROM transactions '
      'WHERE user_id = ? AND type = ? AND date >= ? AND date <= ? '
      'GROUP BY category',
      [
        userId,
        TransactionType.expense.index,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
    );

    final Map<String, double> summary = {};
    for (final row in result) {
      summary[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return summary;
  }

  /// Hitung saldo (total pemasukan - total pengeluaran) untuk user.
  Future<double> getBalance(int userId) async {
    final totalIncome = await getTotalByType(
      userId: userId,
      type: TransactionType.income,
    );
    final totalExpense = await getTotalByType(
      userId: userId,
      type: TransactionType.expense,
    );
    return totalIncome - totalExpense;
  }

  // ──────────── UPDATE ────────────

  /// Update transaksi. Mengembalikan jumlah baris yang diperbarui.
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transactions',
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ──────────── DELETE ────────────

  /// Hapus transaksi berdasarkan ID.
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua transaksi milik user tertentu.
  Future<int> deleteAllTransactionsByUserId(int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Hitung jumlah transaksi untuk user.
  Future<int> getTransactionCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
