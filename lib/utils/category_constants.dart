/// Sumber kebenaran tunggal untuk daftar kategori di seluruh aplikasi Duitin.
///
/// Digunakan oleh:
/// - [TransactionFormScreen] (Form Catat Transaksi)
/// - [TransactionListScreen] (Halaman Riwayat Transaksi)
/// - [AddBudgetDialog] (Dialog Atur Anggaran)
class CategoryConstants {
  CategoryConstants._();

  /// Kategori-kategori pengeluaran bawaan (8 kategori).
  static const List<String> expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Pendidikan',
    'Kesehatan',
    'Lainnya',
  ];

  /// Kategori-kategori pemasukan bawaan (6 kategori).
  static const List<String> incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
    'Hadiah',
    'Penjualan',
    'Lainnya',
  ];

  /// Gabungan seluruh kategori bawaan (13 kategori teratur, 'Lainnya' di posisi akhir).
  static List<String> get allCategories {
    final list = <String>[];
    for (final c in expenseCategories) {
      if (c != 'Lainnya' && !list.contains(c)) {
        list.add(c);
      }
    }
    for (final c in incomeCategories) {
      if (c != 'Lainnya' && !list.contains(c)) {
        list.add(c);
      }
    }
    list.add('Lainnya');
    return list;
  }
}
