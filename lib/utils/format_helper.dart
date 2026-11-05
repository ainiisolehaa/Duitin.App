import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Format angka ke format ribuan dengan titik tanpa 'Rp': "1.000.000"
  static String formatThousand(num amount) {
    return NumberFormat.decimalPattern('id_ID').format(amount);
  }

  /// Parse string berformat ribuan (contoh: "1.000.000") menjadi double murni
  static double parseThousand(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
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
        return Icons.card_giftcard_rounded;
      case 'hadiah':
        return Icons.redeem_rounded;
      case 'investasi':
        return Icons.trending_up_rounded;
      case 'penjualan':
        return Icons.storefront_rounded;
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
        return Colors.green;
      case 'hadiah':
        return Colors.deepOrange;
      case 'investasi':
        return Colors.cyan;
      case 'penjualan':
        return Colors.lime.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}

/// Formatter otomatis saat mengetik input angka agar selalu ada pemisah titik ribuan.
/// Contoh: mengetik 1000000 otomatis menjadi 1.000.000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya digit angka murni
    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(cleanDigits);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
