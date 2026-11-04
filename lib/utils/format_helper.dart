import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper untuk format mata uang Rupiah dan tanggal.
class FormatHelper {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka ke format Rupiah: "Rp 150.000"
  static String formatRupiah(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Format tanggal singkat: "04 Nov 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  /// Format tanggal lengkap: "Rabu, 04 November 2026"
  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format waktu: "14:30 WIB"
  static String formatTime(DateTime date) {
    return '${DateFormat('HH:mm').format(date)} WIB';
  }

  /// Format tanggal dengan jam: "04 Nov 2026, 14:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  /// Format nama bulan dan tahun: "November 2026"
  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  /// Dapatkan icon representatif berdasarkan nama kategori.
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'makanan':
      case 'makan':
      case 'kuliner':
        return Icons.restaurant_rounded;
      case 'transportasi':
      case 'transport':
      case 'bensin':
        return Icons.directions_car_rounded;
      case 'belanja':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'hiburan':
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'pendidikan':
      case 'kuliah':
      case 'buku':
        return Icons.school_rounded;
      case 'kesehatan':
      case 'obat':
        return Icons.medical_services_rounded;
      case 'tagihan':
      case 'listrik':
      case 'air':
      case 'internet':
        return Icons.receipt_long_rounded;
      case 'gaji':
      case 'salary':
        return Icons.payments_rounded;
      case 'bonus':
      case 'hadiah':
        return Icons.card_giftcard_rounded;
      case 'investasi':
        return Icons.trending_up_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Dapatkan warna representatif berdasarkan nama kategori.
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'makanan':
      case 'makan':
      case 'kuliner':
        return Colors.orange;
      case 'transportasi':
      case 'transport':
      case 'bensin':
        return Colors.blue;
      case 'belanja':
      case 'shopping':
        return Colors.purple;
      case 'hiburan':
      case 'entertainment':
        return Colors.pink;
      case 'pendidikan':
      case 'kuliah':
      case 'buku':
        return Colors.indigo;
      case 'kesehatan':
      case 'obat':
        return Colors.redAccent;
      case 'tagihan':
      case 'listrik':
      case 'air':
      case 'internet':
        return Colors.amber.shade800;
      case 'gaji':
      case 'salary':
        return Colors.teal;
      case 'bonus':
      case 'hadiah':
        return Colors.green;
      case 'investasi':
        return Colors.cyan;
      default:
        return Colors.blueGrey;
    }
  }
}
