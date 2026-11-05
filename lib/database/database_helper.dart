import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper — Singleton yang mengelola koneksi SQLite.
///
/// Membuat dan mengelola tabel: users, transactions, budgets.
/// Menggunakan foreign key untuk menghubungkan data antar tabel.
///
/// Versi 2: menambahkan kolom `password` dan `UNIQUE(email)` di tabel users.
class DatabaseHelper {
  static const String _databaseName = 'duitin.db';
  static const int _databaseVersion = 3;

  // Singleton pattern
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Mendapatkan instance database (lazy initialization).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inisialisasi database dan buat tabel.
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Aktifkan foreign key support.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Buat semua tabel saat database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    // ── Tabel Users (v3: dengan password, unique email, avatar) ──
    await db.execute('''
      CREATE TABLE users (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        email       TEXT    UNIQUE,
        password    TEXT,
        currency    TEXT    NOT NULL DEFAULT 'IDR',
        avatar      TEXT,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── Tabel Transactions ──
    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL,
        category    TEXT    NOT NULL,
        amount      REAL    NOT NULL,
        type        INTEGER NOT NULL,
        date        INTEGER NOT NULL,
        note        TEXT,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE CASCADE
      )
    ''');

    // ── Tabel Budgets ──
    await db.execute('''
      CREATE TABLE budgets (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL,
        category    TEXT    NOT NULL,
        amount      REAL    NOT NULL,
        month       INTEGER NOT NULL,
        year        INTEGER NOT NULL,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE CASCADE
      )
    ''');

    // ── Indeks untuk mempercepat query ──
    await db.execute(
      'CREATE INDEX idx_transactions_user_id ON transactions (user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions (date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON transactions (type)',
    );
    await db.execute('CREATE INDEX idx_budgets_user_id ON budgets (user_id)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_budgets_unique '
      'ON budgets (user_id, category, month, year)',
    );
  }

  /// Migrasi dari versi sebelumnya.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: tambah kolom password di tabel users
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
      // Tambah unique constraint pada email (via index)
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email)',
      );
    }
    if (oldVersion < 3) {
      // v2 → v3: tambah kolom avatar di tabel users
      await db.execute('ALTER TABLE users ADD COLUMN avatar TEXT');
    }
  }

  /// Tutup koneksi database.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Hapus semua data (untuk testing/reset).
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.delete('users');
  }
}
