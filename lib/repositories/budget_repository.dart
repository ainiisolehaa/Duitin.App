import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/budget.dart';

/// Repository untuk operasi CRUD pada tabel budgets.
class BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ──────────── CREATE ────────────

  /// Tambah atau update budget (UPSERT berdasarkan unique constraint:
  /// user_id + category + month + year).
  Future<int> insertBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────── READ ────────────

  /// Ambil budget berdasarkan ID.
  Future<Budget?> getBudgetById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('budgets', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  /// Ambil semua budget milik user pada bulan/tahun tertentu.
  Future<List<Budget>> getBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'user_id = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year],
      orderBy: 'category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  /// Ambil semua budget milik user.
  Future<List<Budget>> getAllBudgetsByUserId(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'year DESC, month DESC, category ASC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  /// Ambil budget spesifik untuk satu kategori pada bulan/tahun tertentu.
  Future<Budget?> getBudgetByCategory({
    required int userId,
    required String category,
    required int month,
    required int year,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'user_id = ? AND category = ? AND month = ? AND year = ?',
      whereArgs: [userId, category, month, year],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  /// Hitung total anggaran bulanan untuk user pada bulan/tahun tertentu.
  Future<double> getTotalBudgetByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total '
      'FROM budgets WHERE user_id = ? AND month = ? AND year = ?',
      [userId, month, year],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ──────────── UPDATE ────────────

  /// Update budget. Mengembalikan jumlah baris yang diperbarui.
  Future<int> updateBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      'budgets',
      budget.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // ──────────── DELETE ────────────

  /// Hapus budget berdasarkan ID.
  Future<int> deleteBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua budget milik user pada bulan/tahun tertentu.
  Future<int> deleteBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'budgets',
      where: 'user_id = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year],
    );
  }

  /// Hitung jumlah budget untuk user.
  Future<int> getBudgetCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM budgets WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
