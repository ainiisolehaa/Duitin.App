import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/budget.dart';
import 'package:duitin/models/budget_detail.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/providers/budget_provider.dart';
import 'package:duitin/repositories/budget_repository.dart';
import 'package:duitin/repositories/transaction_repository.dart';

// Mock BudgetRepository
class MockBudgetRepo extends BudgetRepository {
  final List<Budget> _db = [];
  int _counter = 1;

  @override
  Future<int> insertBudget(Budget budget) async {
    final idx = _db.indexWhere(
      (b) =>
          b.userId == budget.userId &&
          b.category == budget.category &&
          b.month == budget.month &&
          b.year == budget.year,
    );
    if (idx != -1) {
      _db[idx] = budget.copyWith(id: _db[idx].id);
      return _db[idx].id!;
    }
    final id = _counter++;
    _db.add(budget.copyWith(id: id));
    return id;
  }

  @override
  Future<List<Budget>> getBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _db
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .toList();
  }

  @override
  Future<double> getTotalBudgetByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _db
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .fold<double>(0.0, (sum, b) => sum + b.amount);
  }

  @override
  Future<int> deleteBudget(int id) async {
    _db.removeWhere((b) => b.id == id);
    return 1;
  }
}

// Mock TransactionRepository
class MockTxRepo extends TransactionRepository {
  final List<Transaction> _txs = [];

  void add(Transaction tx) => _txs.add(tx);

  @override
  Future<Map<String, double>> getExpenseSummaryByCategory({
    required int userId,
    required int month,
    required int year,
  }) async {
    final Map<String, double> summary = {};
    for (final t in _txs) {
      if (t.userId == userId &&
          t.type == TransactionType.expense &&
          t.date.month == month &&
          t.date.year == year) {
        summary[t.category] = (summary[t.category] ?? 0) + t.amount;
      }
    }
    return summary;
  }
}

void main() {
  group(
    'Tahap 8: Fitur Anggaran Bulanan, Sisa, Persentase & Peringatan Batas',
    () {
      late MockBudgetRepo budgetRepo;
      late MockTxRepo txRepo;
      late BudgetProvider provider;

      const int userIdA = 1;
      const int userIdB = 2;
      const int testMonth = 11;
      const int testYear = 2026;

      setUp(() {
        budgetRepo = MockBudgetRepo();
        txRepo = MockTxRepo();
        provider = BudgetProvider(repository: budgetRepo, txRepository: txRepo);
      });

      test('1. Anggaran awal kosong sebelum dipasang', () async {
        await provider.loadBudgets(
          userId: userIdA,
          month: testMonth,
          year: testYear,
        );

        expect(provider.totalBudget, equals(0.0));
        expect(provider.totalActualExpense, equals(0.0));
        expect(provider.remainingBudget, equals(0.0));
        expect(provider.usagePercentage, equals(0.0));
        expect(provider.isNearLimit, isFalse);
        expect(provider.isOverBudget, isFalse);
        expect(provider.categoryDetails, isEmpty);
      });

      test('2. Menentukan anggaran bulanan & menghitung pengeluaran aktual serta sisa anggaran', () async {
        // 1. Pasang anggaran Makanan = 1.000.000, Transportasi = 500.000
        await provider.setBudget(
          userId: userIdA,
          category: 'Makanan',
          amount: 1000000,
          month: testMonth,
          year: testYear,
        );
        await provider.setBudget(
          userId: userIdA,
          category: 'Transportasi',
          amount: 500000,
          month: testMonth,
          year: testYear,
        );

        expect(provider.totalBudget, equals(1500000.0));
        expect(provider.budgets.length, equals(2));

        // 2. Tambahkan transaksi pengeluaran bulan berjalan
        txRepo.add(
          Transaction(
            userId: userIdA,
            category: 'Makanan',
            amount: 400000,
            type: TransactionType.expense,
            date: DateTime(testYear, testMonth, 5),
          ),
        );
        txRepo.add(
          Transaction(
            userId: userIdA,
            category: 'Transportasi',
            amount: 200000,
            type: TransactionType.expense,
            date: DateTime(testYear, testMonth, 8),
          ),
        );

        // Muat ulang
        await provider.loadBudgets(
          userId: userIdA,
          month: testMonth,
          year: testYear,
        );

        // Total pengeluaran: 400rb + 200rb = 600rb
        expect(provider.totalActualExpense, equals(600000.0));
        // Sisa anggaran: 1.5jt - 600rb = 900rb
        expect(provider.remainingBudget, equals(900000.0));
        // Persentase penggunaan: 600.000 / 1.500.000 * 100 = 40%
        expect(provider.usagePercentage, equals(40.0));
        // Status aman (< 80%)
        expect(provider.overallStatus, equals(BudgetStatus.safe));
        expect(provider.isNearLimit, isFalse);
        expect(provider.isOverBudget, isFalse);
      });

      test('3. Indikator Peringatan saat anggaran mendekati batas (>= 80% dan < 100%)', () async {
        // Anggaran total: 1.000.000
        await provider.setBudget(
          userId: userIdA,
          category: 'Makanan',
          amount: 1000000,
          month: testMonth,
          year: testYear,
        );

        // Pengeluaran: 850.000 (85%)
        txRepo.add(
          Transaction(
            userId: userIdA,
            category: 'Makanan',
            amount: 850000,
            type: TransactionType.expense,
            date: DateTime(testYear, testMonth, 15),
          ),
        );

        await provider.loadBudgets(
          userId: userIdA,
          month: testMonth,
          year: testYear,
        );

        expect(provider.usagePercentage, equals(85.0));
        expect(provider.remainingBudget, equals(150000.0));
        expect(provider.isNearLimit, isTrue);
        expect(provider.isOverBudget, isFalse);
        expect(provider.overallStatus, equals(BudgetStatus.warning));
      });

      test(
        '4. Indikator Peringatan Bahaya saat anggaran melewati batas (>= 100%)',
        () async {
          // Anggaran total: 500.000
          await provider.setBudget(
            userId: userIdA,
            category: 'Belanja',
            amount: 500000,
            month: testMonth,
            year: testYear,
          );

          // Pengeluaran melebihi batas: 620.000 (124%)
          txRepo.add(
            Transaction(
              userId: userIdA,
              category: 'Belanja',
              amount: 620000,
              type: TransactionType.expense,
              date: DateTime(testYear, testMonth, 20),
            ),
          );

          await provider.loadBudgets(
            userId: userIdA,
            month: testMonth,
            year: testYear,
          );

          expect(provider.usagePercentage, equals(124.0));
          expect(provider.remainingBudget, equals(-120000.0));
          expect(provider.isOverBudget, isTrue);
          expect(provider.isNearLimit, isFalse);
          expect(provider.overallStatus, equals(BudgetStatus.danger));
        },
      );

      test(
        '5. Perhitungan hanya menggunakan transaksi bulan & tahun yang sesuai',
        () async {
          await provider.setBudget(
            userId: userIdA,
            category: 'Makanan',
            amount: 1000000,
            month: testMonth, // November
            year: testYear,
          );

          // Transaksi bulan Oktober (bulan lalu) - TIDAK boleh dihitung di November
          txRepo.add(
            Transaction(
              userId: userIdA,
              category: 'Makanan',
              amount: 500000,
              type: TransactionType.expense,
              date: DateTime(testYear, 10, 25),
            ),
          );

          // Transaksi bulan November
          txRepo.add(
            Transaction(
              userId: userIdA,
              category: 'Makanan',
              amount: 200000,
              type: TransactionType.expense,
              date: DateTime(testYear, 11, 2),
            ),
          );

          await provider.loadBudgets(
            userId: userIdA,
            month: testMonth,
            year: testYear,
          );

          // Hanya 200.000 dari bulan November yang terhitung
          expect(provider.totalActualExpense, equals(200000.0));
          expect(provider.remainingBudget, equals(800000.0));
        },
      );

      test(
        '6. Transaksi Pemasukan tidak dihitung sebagai penggunaan anggaran',
        () async {
          await provider.setBudget(
            userId: userIdA,
            category: 'Gaji',
            amount: 5000000,
            month: testMonth,
            year: testYear,
          );

          // Transaksi Pemasukan (bukan pengeluaran)
          txRepo.add(
            Transaction(
              userId: userIdA,
              category: 'Gaji',
              amount: 5000000,
              type: TransactionType.income,
              date: DateTime(testYear, testMonth, 1),
            ),
          );

          await provider.loadBudgets(
            userId: userIdA,
            month: testMonth,
            year: testYear,
          );

          // Pengeluaran aktual tetap 0 karena tipenya income
          expect(provider.totalActualExpense, equals(0.0));
          expect(provider.usagePercentage, equals(0.0));
        },
      );

      test('7. Isolasi Data Pengguna (User A vs User B)', () async {
        // Anggaran User A
        await provider.setBudget(
          userId: userIdA,
          category: 'Makanan',
          amount: 1000000,
          month: testMonth,
          year: testYear,
        );

        // Anggaran User B
        await provider.setBudget(
          userId: userIdB,
          category: 'Makanan',
          amount: 300000,
          month: testMonth,
          year: testYear,
        );

        // Transaksi User B
        txRepo.add(
          Transaction(
            userId: userIdB,
            category: 'Makanan',
            amount: 300000,
            type: TransactionType.expense,
            date: DateTime(testYear, testMonth, 5),
          ),
        );

        // Cek User A (tidak boleh terpengaruh transaksi User B)
        await provider.loadBudgets(
          userId: userIdA,
          month: testMonth,
          year: testYear,
        );
        expect(provider.totalBudget, equals(1000000.0));
        expect(provider.totalActualExpense, equals(0.0));

        // Cek User B
        await provider.loadBudgets(
          userId: userIdB,
          month: testMonth,
          year: testYear,
        );
        expect(provider.totalBudget, equals(300000.0));
        expect(provider.totalActualExpense, equals(300000.0));
        expect(provider.isOverBudget, isTrue);
      });

      test('8. Navigasi Geser Bulan (changeMonth)', () async {
        await provider.loadBudgets(
          userId: userIdA,
          month: testMonth,
          year: testYear,
        );
        expect(provider.selectedMonth, equals(11));

        // Maju 1 bulan -> Desember 2026
        await provider.changeMonth(1, userIdA);
        expect(provider.selectedMonth, equals(12));
        expect(provider.selectedYear, equals(2026));

        // Maju 1 bulan lagi -> Januari 2027 (pergantian tahun)
        await provider.changeMonth(1, userIdA);
        expect(provider.selectedMonth, equals(1));
        expect(provider.selectedYear, equals(2027));

        // Mundur 1 bulan -> Desember 2026
        await provider.changeMonth(-1, userIdA);
        expect(provider.selectedMonth, equals(12));
        expect(provider.selectedYear, equals(2026));
      });
    },
  );
}
