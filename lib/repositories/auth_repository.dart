import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

/// Hasil operasi autentikasi.
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({required this.success, this.user, this.errorMessage});
}

/// Repository untuk operasi autentikasi lokal (dummy).
///
/// Menggunakan SQLite untuk menyimpan data pengguna.
/// Password di-hash menggunakan SHA-256 sebelum disimpan.
class AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Hash password menggunakan SHA-256.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Daftarkan pengguna baru.
  ///
  /// Validasi:
  /// - Email belum terdaftar
  /// - Semua field terisi
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Cek apakah email sudah terdaftar
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (existing.isNotEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Email sudah terdaftar. Silakan gunakan email lain.',
        );
      }

      // Hash password dan simpan user
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now();
      final user = User(
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password: hashedPassword,
        createdAt: now,
        updatedAt: now,
      );

      final id = await db.insert('users', user.toMap());

      return AuthResult(
        success: true,
        user: user.copyWith(id: id, updatedAt: now),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Terjadi kesalahan saat mendaftar: $e',
      );
    }
  }

  /// Login dengan email dan password.
  ///
  /// Validasi:
  /// - Email terdaftar
  /// - Password cocok
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Cari user berdasarkan email
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );

      if (results.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Email belum terdaftar. Silakan daftar terlebih dahulu.',
        );
      }

      final user = User.fromMap(results.first);

      // Verifikasi password
      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return AuthResult(
          success: false,
          errorMessage: 'Password salah. Silakan coba lagi.',
        );
      }

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Terjadi kesalahan saat login: $e',
      );
    }
  }

  /// Ambil user berdasarkan ID (untuk restore sesi).
  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Update data user (misalnya nama atau informasi akun).
  Future<bool> updateUser(User user) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }
}

