import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/providers/transaction_provider.dart';
import 'package:duitin/repositories/transaction_repository.dart';

// Mock TransactionRepository yang mengimplementasikan getTransactionsFiltered persis seperti SQLite query
class FilterMockTransactionRepository extends TransactionRepository {
  final List<Transaction> _db = [];
  int _counter = 1;

  @override
  Future<int> insertTransaction(Transaction transaction) async {
    final id = _counter++;
    _db.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  Future<List<Transaction>> getTransactionsByUserId(int userId) async {
    final list = _db.where((t) => t.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<String>> getDistinctCategories(int userId) async {
    final set = _db
        .where((t) => t.userId == userId)
        .map((t) => t.category)
        .toSet();
    final list = set.toList()..sort();
    return list;
  }

  @override
  Future<List<Transaction>> getTransactionsFiltered({
    required int userId,
    String? searchQuery,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _db.where((t) {
      if (t.userId != userId) return false;

      // 1. Filter Pencarian Teks
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchCategory = t.category.toLowerCase().contains(q);
        final matchNote = t.note?.toLowerCase().contains(q) ?? false;
        if (!matchCategory && !matchNote) return false;
      }

      // 2. Filter Jenis Transaksi
      if (type != null && t.type != type) return false;

      // 3. Filter Kategori
      if (category != null &&
          category.trim().isNotEmpty &&
          category != 'Semua') {
        if (t.category.toLowerCase() != category.toLowerCase().trim()) {
          return false;
        }
      }

      // 4. Filter Rentang Tanggal
      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        if (t.date.isBefore(start)) return false;
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
        if (t.date.isAfter(end)) return false;
      }

      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}

void main() {
  group('Tahap 6: Riwayat Transaksi Langsung dari SQLite dengan Pencarian & Multi-Filter', () {
    late FilterMockTransactionRepository repository;
    late TransactionProvider provider;
    const int userId = 1;

    final today = DateTime(2026, 11, 4, 12, 0);
    final yesterday = DateTime(2026, 11, 3, 10, 30);
    final lastWeek = DateTime(2026, 10, 28, 15, 0);

    setUp(() async {
      repository = FilterMockTransactionRepository();
      provider = TransactionProvider(repository: repository);

      // Data sampel untuk pengujian riwayat & filter
      await repository.insertTransaction(
        Transaction(
          userId: userId,
          category: 'Makanan',
          amount: 25000,
          type: TransactionType.expense,
          date: today,
          note: 'Nasi padang siang',
        ),
      );

      await repository.insertTransaction(
        Transaction(
          userId: userId,
          category: 'Transportasi',
          amount: 15000,
          type: TransactionType.expense,
          date: today,
          note: 'Kereta komuter',
        ),
      );

      await repository.insertTransaction(
        Transaction(
          userId: userId,
          category: 'Makanan',
          amount: 50000,
          type: TransactionType.expense,
          date: yesterday,
          note: 'Makan malam cafe',
        ),
      );

      await repository.insertTransaction(
        Transaction(
          userId: userId,
          category: 'Gaji',
          amount: 6000000,
          type: TransactionType.income,
          date: yesterday,
          note: 'Gaji bulanan',
        ),
      );

      await repository.insertTransaction(
        Transaction(
          userId: userId,
          category: 'Bonus',
          amount: 500000,
          type: TransactionType.income,
          date: lastWeek,
          note: 'Bonus proyek selesai',
        ),
      );
    });

    test('1. Memuat seluruh riwayat transaksi tanpa filter', () async {
      await provider.filterTransactions(userId: userId);

      expect(provider.filteredTransactions.length, equals(5));
      // Urutan harus tanggal terbaru di atas
      expect(provider.filteredTransactions.first.date.day, equals(today.day));
    });

    test('2. Filter berdasarkan Pencarian Teks (Search Query)', () async {
      // Cari catatan "padang"
      await provider.filterTransactions(userId: userId, searchQuery: 'padang');
      expect(provider.filteredTransactions.length, equals(1));
      expect(provider.filteredTransactions.first.note, contains('Nasi padang'));

      // Cari kategori "Makanan"
      await provider.filterTransactions(userId: userId, searchQuery: 'Makanan');
      expect(provider.filteredTransactions.length, equals(2));
    });

    test('3. Filter berdasarkan Jenis Transaksi (Income / Expense)', () async {
      // Filter Pengeluaran
      await provider.filterTransactions(
        userId: userId,
        type: TransactionType.expense,
      );
      expect(provider.filteredTransactions.length, equals(3));
      expect(provider.filteredTransactions.every((t) => t.isExpense), isTrue);

      // Filter Pemasukan
      await provider.filterTransactions(
        userId: userId,
        type: TransactionType.income,
      );
      expect(provider.filteredTransactions.length, equals(2));
      expect(provider.filteredTransactions.every((t) => t.isIncome), isTrue);
    });

    test('4. Filter berdasarkan Kategori Spesifik', () async {
      await provider.filterTransactions(
        userId: userId,
        category: 'Transportasi',
      );

      expect(provider.filteredTransactions.length, equals(1));
      expect(
        provider.filteredTransactions.first.category,
        equals('Transportasi'),
      );
    });

    test('5. Filter berdasarkan Periode Rentang Tanggal', () async {
      // Filter hanya transaksi hari ini (4 November 2026)
      await provider.filterTransactions(
        userId: userId,
        startDate: DateTime(2026, 11, 4),
        endDate: DateTime(2026, 11, 4),
      );

      expect(provider.filteredTransactions.length, equals(2));
      expect(
        provider.filteredTransactions.every((t) => t.date.day == 4),
        isTrue,
      );
    });

    test('6. Kombinasi Filter: Pencarian + Jenis + Kategori + Periode Tanggal digunakan bersamaan', () async {
      // Cari: jenis = Pengeluaran, kategori = Makanan, tanggal = hari ini, teks = padang
      await provider.filterTransactions(
        userId: userId,
        searchQuery: 'padang',
        type: TransactionType.expense,
        category: 'Makanan',
        startDate: DateTime(2026, 11, 4),
        endDate: DateTime(2026, 11, 4),
      );

      expect(provider.filteredTransactions.length, equals(1));
      final tx = provider.filteredTransactions.first;
      expect(tx.category, equals('Makanan'));
      expect(tx.type, equals(TransactionType.expense));
      expect(tx.note, equals('Nasi padang siang'));
      expect(tx.amount, equals(25000.0));
    });

    test(
      '7. Filter menghasilkan state kosong jika tidak ada yang cocok',
      () async {
        await provider.filterTransactions(
          userId: userId,
          searchQuery: 'KataKunciTidakAda',
        );

        expect(provider.filteredTransactions, isEmpty);
      },
    );

    test('8. Mendapatkan daftar kategori unik dari SQLite', () async {
      final categories = await repository.getDistinctCategories(userId);

      expect(
        categories,
        containsAll(['Makanan', 'Transportasi', 'Gaji', 'Bonus']),
      );
      expect(categories.length, equals(4));
    });
  });
}
