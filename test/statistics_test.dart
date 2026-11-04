import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/statistic_data.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/providers/statistics_provider.dart';
import 'package:duitin/repositories/transaction_repository.dart';

// Mock TransactionRepository untuk pengujian kalkulasi statistik fl_chart
class MockStatsTransactionRepository extends TransactionRepository {
  final List<Transaction> _db = [];

  void add(Transaction tx) {
    _db.add(tx);
  }

  void clear() {
    _db.clear();
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _db.where((t) {
      if (t.userId != userId) return false;
      return !t.date.isBefore(startDate) && !t.date.isAfter(endDate);
    }).toList();
  }
}

void main() {
  group('Tahap 7: Statistik Keuangan fl_chart (Mingguan & Bulanan)', () {
    late MockStatsTransactionRepository repository;
    late StatisticsProvider provider;
    const int userId = 1;

    // Tetapkan tanggal referensi: Rabu, 4 November 2026
    final wednesday = DateTime(2026, 11, 4, 12, 0);

    setUp(() {
      repository = MockStatsTransactionRepository();
      provider = StatisticsProvider(repository: repository);
    });

    test('1. Nilai awal statistik kosong saat belum ada transaksi', () async {
      await provider.loadStatistics(userId);

      expect(provider.totalIncome, equals(0.0));
      expect(provider.totalExpense, equals(0.0));
      expect(provider.netSavings, equals(0.0));
      expect(provider.categoryStats, isEmpty);
      // Mingguan memiliki 7 interval hari
      expect(provider.intervalStats.length, equals(7));
      expect(
        provider.intervalStats.every((s) => s.income == 0 && s.expense == 0),
        isTrue,
      );
    });

    test('2. Kalkulasi Arus Kas Mingguan (7 Hari: Sen s/d Min) & Kategori PieChart', () async {
      // Senin (2 Nov 2026): Masuk 1.000.000
      repository.add(
        Transaction(
          userId: userId,
          category: 'Gaji',
          amount: 1000000,
          type: TransactionType.income,
          date: DateTime(2026, 11, 2, 9, 0),
        ),
      );

      // Rabu (4 Nov 2026): Keluar Makanan 50.000
      repository.add(
        Transaction(
          userId: userId,
          category: 'Makanan',
          amount: 50000,
          type: TransactionType.expense,
          date: wednesday,
        ),
      );

      // Rabu (4 Nov 2026): Keluar Transportasi 25.000
      repository.add(
        Transaction(
          userId: userId,
          category: 'Transportasi',
          amount: 25000,
          type: TransactionType.expense,
          date: DateTime(2026, 11, 4, 17, 30),
        ),
      );

      // Jumat (6 Nov 2026): Keluar Makanan 25.000
      repository.add(
        Transaction(
          userId: userId,
          category: 'Makanan',
          amount: 25000,
          type: TransactionType.expense,
          date: DateTime(2026, 11, 6, 19, 0),
        ),
      );

      await provider.loadStatistics(userId);

      // Verifikasi Total
      expect(provider.totalIncome, equals(1000000.0));
      expect(provider.totalExpense, equals(100000.0));
      expect(provider.netSavings, equals(900000.0));

      // Verifikasi BarChart Interval (Senin index 0, Rabu index 2, Jumat index 4)
      expect(provider.intervalStats[0].income, equals(1000000.0)); // Senin
      expect(
        provider.intervalStats[2].expense,
        equals(75000.0),
      ); // Rabu (50rb + 25rb)
      expect(
        provider.intervalStats[4].expense,
        equals(25000.0),
      ); // Jumat (25rb)

      // Verifikasi PieChart Kategori
      expect(provider.categoryStats.length, equals(2));
      // Makanan total 75.000 (75%)
      final foodStat = provider.categoryStats.firstWhere(
        (c) => c.category == 'Makanan',
      );
      expect(foodStat.amount, equals(75000.0));
      expect(foodStat.percentage, equals(75.0));

      // Transportasi total 25.000 (25%)
      final transStat = provider.categoryStats.firstWhere(
        (c) => c.category == 'Transportasi',
      );
      expect(transStat.amount, equals(25000.0));
      expect(transStat.percentage, equals(25.0));
    });

    test(
      '3. Beralih ke Periode Bulanan (4 Interval Minggu) & Kalkulasi Akurat',
      () async {
        // Minggu 1 (4 Nov): Keluar 100.000
        repository.add(
          Transaction(
            userId: userId,
            category: 'Makanan',
            amount: 100000,
            type: TransactionType.expense,
            date: DateTime(2026, 11, 4),
          ),
        );

        // Minggu 2 (10 Nov): Masuk 2.000.000, Keluar Belanja 300.000
        repository.add(
          Transaction(
            userId: userId,
            category: 'Gaji',
            amount: 2000000,
            type: TransactionType.income,
            date: DateTime(2026, 11, 10),
          ),
        );
        repository.add(
          Transaction(
            userId: userId,
            category: 'Belanja',
            amount: 300000,
            type: TransactionType.expense,
            date: DateTime(2026, 11, 12),
          ),
        );

        // Ganti periode ke Bulanan
        await provider.setPeriod(StatPeriod.monthly, userId);

        expect(provider.period, equals(StatPeriod.monthly));
        expect(provider.intervalStats.length, equals(4)); // 4 interval minggu

        // Mgg 1 (1-7): Keluar 100rb
        expect(provider.intervalStats[0].expense, equals(100000.0));

        // Mgg 2 (8-14): Masuk 2jt, Keluar 300rb
        expect(provider.intervalStats[1].income, equals(2000000.0));
        expect(provider.intervalStats[1].expense, equals(300000.0));

        // Kategori PieChart: Belanja (300rb, 75%) dan Makanan (100rb, 25%)
        expect(provider.categoryStats.length, equals(2));
        expect(provider.categoryStats.first.category, equals('Belanja'));
        expect(provider.categoryStats.first.percentage, equals(75.0));
      },
    );

    test(
      '4. Navigasi Offset Periode (Mundur / Maju Minggu atau Bulan)',
      () async {
        await provider.setPeriod(StatPeriod.monthly, userId);
        final initialMonth = provider.referenceDate.month;

        // Mundur 1 bulan
        await provider.changeDateOffset(-1, userId);
        expect(provider.referenceDate.month, equals(initialMonth - 1));

        // Maju 2 bulan
        await provider.changeDateOffset(2, userId);
        expect(provider.referenceDate.month, equals(initialMonth + 1));
      },
    );

    test('5. Reaktivitas: Data grafik langsung berubah saat transaksi baru ditambahkan', () async {
      await provider.loadStatistics(userId);
      expect(provider.totalExpense, equals(0.0));

      // Tambah transaksi baru ke repositori
      repository.add(
        Transaction(
          userId: userId,
          category: 'Tagihan',
          amount: 150000,
          type: TransactionType.expense,
          date: DateTime(2026, 11, 4),
        ),
      );

      // Reload
      await provider.loadStatistics(userId);
      expect(provider.totalExpense, equals(150000.0));
      expect(provider.categoryStats.first.category, equals('Tagihan'));
      expect(provider.categoryStats.first.amount, equals(150000.0));
    });
  });
}
