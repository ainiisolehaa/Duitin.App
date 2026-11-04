import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Helper untuk mengisi database dengan data dummy realistis seorang mahasiswa.
///
/// Profil: Dimas Pratama (Mahasiswa)
/// Email: mahasiswa@duitin.id
/// Password: password123
///
/// Mencakup pemasukan (uang saku, beasiswa, part-time), pengeluaran harian
/// anak kost/kuliah (kost, makan, bensin, nugas, fotokopi, kuota),
/// serta anggaran bulanan dengan berbagai status (Aman & Waspada).
class DataSeeder {
  static const String studentName = 'Dimas Pratama';
  static const String studentEmail = 'mahasiswa@duitin.id';
  static const String studentPassword = 'password123';

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Cek dan masukkan data dummy mahasiswa jika belum ada di database.
  static Future<int> seedStudentData({bool forceReset = false}) async {
    final db = await DatabaseHelper.instance.database;

    // Cek apakah akun mahasiswa sudah ada
    final existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [studentEmail.toLowerCase()],
    );

    if (existingUsers.isNotEmpty && !forceReset) {
      return existingUsers.first['id'] as int;
    }

    int userId;
    final now = DateTime.now();

    if (existingUsers.isNotEmpty && forceReset) {
      userId = existingUsers.first['id'] as int;
      await db.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
    } else {
      // 1. Buat Akun Mahasiswa
      final hashedPassword = _hashPassword(studentPassword);
      final joinDate = DateTime(now.year, now.month, 1);

      userId = await db.insert('users', {
        'name': studentName,
        'email': studentEmail.toLowerCase(),
        'password': hashedPassword,
        'currency': 'IDR',
        'created_at': joinDate.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
    }

    final currentMonth = now.month;
    final currentYear = now.year;

    // 2. Data Anggaran Bulanan Mahasiswa
    final budgets = [
      {'category': 'Makanan', 'amount': 900000.0},
      {'category': 'Tagihan', 'amount': 1000000.0},
      {'category': 'Belanja', 'amount': 400000.0},
      {'category': 'Pendidikan', 'amount': 250000.0},
      {'category': 'Transportasi', 'amount': 150000.0},
      {'category': 'Hiburan', 'amount': 150000.0},
    ];

    for (final b in budgets) {
      await db.insert('budgets', {
        'user_id': userId,
        'category': b['category'],
        'amount': b['amount'],
        'month': currentMonth,
        'year': currentYear,
        'created_at': DateTime(currentYear, currentMonth, 1).millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Data Transaksi Realistis Mahasiswa Bulan Berjalan
    final List<Map<String, dynamic>> transactions = [
      // ── Pemasukan ──
      {
        'category': 'Gaji',
        'amount': 2500000.0,
        'type': 0, // Income
        'date': DateTime(currentYear, currentMonth, 1, 9, 30),
        'note': 'Kiriman uang saku bulanan dari orang tua',
      },
      {
        'category': 'Gaji',
        'amount': 750000.0,
        'type': 0,
        'date': DateTime(currentYear, currentMonth, 5, 14, 0),
        'note': 'Gaji part-time asisten laboratorium kampus',
      },
      {
        'category': 'Bonus',
        'amount': 1000000.0,
        'type': 0,
        'date': DateTime(currentYear, currentMonth, 10, 10, 15),
        'note': 'Pencairan beasiswa prestasi semester ini',
      },

      // ── Pengeluaran ──
      {
        'category': 'Tagihan',
        'amount': 850000.0,
        'type': 1, // Expense
        'date': DateTime(currentYear, currentMonth, 1, 11, 0),
        'note': 'Bayar sewa kamar kost bulanan',
      },
      {
        'category': 'Belanja',
        'amount': 215000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 2, 16, 45),
        'note': 'Belanja bulanan sabun, deterjen, & mie instan',
      },
      {
        'category': 'Pendidikan',
        'amount': 120000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 3, 10, 20),
        'note': 'Beli buku referensi pemrograman & modul praktikum',
      },
      {
        'category': 'Makanan',
        'amount': 22000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 4, 12, 30),
        'note': 'Makan siang ayam geprek di kantin kampus',
      },
      {
        'category': 'Transportasi',
        'amount': 35000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 5, 8, 15),
        'note': 'Isi bensin motor Pertalite full tank',
      },
      {
        'category': 'Tagihan',
        'amount': 85000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 6, 19, 0),
        'note': 'Paket data internet 50GB untuk kuliah online & riset',
      },
      {
        'category': 'Hiburan',
        'amount': 32000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 7, 20, 30),
        'note': 'Kopi susu & nugas bareng teman kelompok di cafe',
      },
      {
        'category': 'Makanan',
        'amount': 20000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 8, 18, 45),
        'note': 'Makan malam nasi goreng di dekat kost',
      },
      {
        'category': 'Pendidikan',
        'amount': 45000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 9, 11, 10),
        'note': 'Fotokopi materi kuliah & jilid laporan tugas besar',
      },
      {
        'category': 'Kesehatan',
        'amount': 35000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 10, 15, 0),
        'note': 'Beli vitamin C & obat flu di apotek',
      },
      {
        'category': 'Makanan',
        'amount': 18000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 11, 12, 15),
        'note': 'Makan siang soto ayam & es teh manis',
      },
      {
        'category': 'Transportasi',
        'amount': 35000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 12, 17, 30),
        'note': 'Isi bensin motor untuk mobilitas kampus',
      },
      {
        'category': 'Hiburan',
        'amount': 55000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 13, 21, 0),
        'note': 'Nonton bioskop akhir pekan bareng teman kuliah',
      },
      {
        'category': 'Makanan',
        'amount': 25000.0,
        'type': 1,
        'date': DateTime(currentYear, currentMonth, 14, 19, 15),
        'note': 'Makan malam pecel lele sambal lamongan',
      },
    ];

    for (final tx in transactions) {
      final date = tx['date'] as DateTime;
      await db.insert('transactions', {
        'user_id': userId,
        'category': tx['category'],
        'amount': tx['amount'],
        'type': tx['type'],
        'date': date.millisecondsSinceEpoch,
        'note': tx['note'],
        'created_at': date.millisecondsSinceEpoch,
        'updated_at': date.millisecondsSinceEpoch,
      });
    }

    return userId;
  }
}

