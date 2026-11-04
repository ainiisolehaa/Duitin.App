import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';

/// Repository untuk operasi CRUD pada tabel users.
class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ──────────── CREATE ────────────

  /// Tambah user baru. Mengembalikan ID user yang baru dibuat.
  Future<int> insertUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ──────────── READ ────────────

  /// Ambil user berdasarkan ID. Mengembalikan null jika tidak ditemukan.
  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Ambil semua users.
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => User.fromMap(map)).toList();
  }

  /// Ambil user berdasarkan email.
  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ──────────── UPDATE ────────────

  /// Update data user. Mengembalikan jumlah baris yang diperbarui.
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ──────────── DELETE ────────────

  /// Hapus user berdasarkan ID. Juga menghapus semua transaksi
  /// dan budget terkait (CASCADE).
  /// Mengembalikan jumlah baris yang dihapus.
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Hitung jumlah user yang terdaftar.
  Future<int> getUserCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
