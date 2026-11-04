import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/models/budget.dart';
import 'package:duitin/providers/transaction_provider.dart';
import 'package:duitin/providers/budget_provider.dart';
import 'package:duitin/repositories/transaction_repository.dart';
import 'package:duitin/repositories/budget_repository.dart';

// Fake TransactionRepository untuk pengujian tanpa file SQLite fisik
class FakeTransactionRepository extends TransactionRepository {
  final List<Transaction> _mockTransactions = [];
  int _idCounter = 1;

  @override
  Future<int> insertTransaction(Transaction transaction) async {
    final id = _idCounter++;
    final item = transaction.copyWith(id: id);
    _mockTransactions.add(item);
    return id;
  }

  @override
  Future<List<Transaction>> getTransactionsByUserId(int userId) async {
    final list = _mockTransactions.where((t) => t.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<double> getTotalByType({
    required int userId,
    required TransactionType type,
  }) async {
    return _mockTransactions
        .where((t) => t.userId == userId && t.type == type)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Future<Map<String, double>> getExpenseSummaryByCategory({
    required int userId,
    required int month,
    required int year,
  }) async {
    final Map<String, double> summary = {};
    for (final t in _mockTransactions) {
      if (t.userId == userId &&
          t.type == TransactionType.expense &&
          t.date.month == month &&
          t.date.year == year) {
        summary[t.category] = (summary[t.category] ?? 0) + t.amount;
      }
    }
    return summary;
  }

  @override
  Future<List<String>> getDistinctCategories(int userId) async {
    return _mockTransactions
        .where((t) => t.userId == userId)
        .map((t) => t.category)
        .toSet()
        .toList();
  }

  @override
  Future<int> deleteTransaction(int id) async {
    _mockTransactions.removeWhere((t) => t.id == id);
    return 1;
  }

  @override
  Future<double> getBalance(int userId) async {
    final income = await getTotalByType(userId: userId, type: TransactionType.income);
    final expense = await getTotalByType(userId: userId, type: TransactionType.expense);
    return income - expense;
  }
}

// Fake BudgetRepository untuk pengujian tanpa file SQLite fisik
class FakeBudgetRepository extends BudgetRepository {
  final List<Budget> _mockBudgets = [];
  int _idCounter = 1;

  @override
  Future<int> insertBudget(Budget budget) async {
    final existingIndex = _mockBudgets.indexWhere(
      (b) =>
          b.userId == budget.userId &&
          b.category == budget.category &&
          b.month == budget.month &&
          b.year == budget.year,
    );
    if (existingIndex != -1) {
      _mockBudgets[existingIndex] = budget.copyWith(id: _mockBudgets[existingIndex].id);
      return _mockBudgets[existingIndex].id!;
    }
    final id = _idCounter++;
    _mockBudgets.add(budget.copyWith(id: id));
    return id;
  }

  @override
  Future<List<Budget>> getBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _mockBudgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .toList();
  }

  @override
  Future<double> getTotalBudgetByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _mockBudgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .fold<double>(0.0, (sum, b) => sum + b.amount);
  }
}

void main() {
  group('Dashboard Financial Calculations & Dynamic Updates', () {
    late FakeTransactionRepository fakeTxRepo;
    late FakeBudgetRepository fakeBudgetRepo;
    late TransactionProvider txProvider;
    late BudgetProvider budgetProvider;

    const int userIdA = 1;
    const int userIdB = 2;

    setUp(() {
      fakeTxRepo = FakeTransactionRepository();
      fakeBudgetRepo = FakeBudgetRepository();
      txProvider = TransactionProvider(repository: fakeTxRepo);
      budgetProvider = BudgetProvider(repository: fakeBudgetRepo);
    });

    test('Saldo awal user adalah 0', () async {
      await txProvider.loadDashboardData(userIdA);

      expect(txProvider.totalIncome, equals(0.0));
      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.balance, equals(0.0));
      expect(txProvider.transactions, isEmpty);
      expect(txProvider.recentTransactions, isEmpty);
    });

    test('Penambahan pemasukan dan pengeluaran menghitung saldo secara dinamis', () async {
      final now = DateTime.now();

      // 1. Tambah Pemasukan (Gaji: Rp 5.000.000)
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Gaji',
        amount: 5000000,
        type: TransactionType.income,
        date: now,
        note: 'Gaji Bulanan',
      );

      expect(txProvider.totalIncome, equals(5000000.0));
      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.balance, equals(5000000.0));
      expect(txProvider.transactions.length, equals(1));

      // 2. Tambah Pengeluaran (Makanan: Rp 50.000)
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Makanan',
        amount: 50000,
        type: TransactionType.expense,
        date: now,
        note: 'Makan Siang',
      );

      // Saldo otomatis diperbarui: 5.000.000 - 50.000 = 4.950.000
      expect(txProvider.totalIncome, equals(5000000.0));
      expect(txProvider.totalExpense, equals(5000000 - 4950000));
      expect(txProvider.balance, equals(4950000.0));
      expect(txProvider.transactions.length, equals(2));

      // 3. Tambah Pengeluaran kedua (Transportasi: Rp 20.000)
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Transportasi',
        amount: 20000,
        type: TransactionType.expense,
        date: now,
      );

      // Total pengeluaran: 70.000, Saldo: 4.930.000
      expect(txProvider.totalExpense, equals(70000.0));
      expect(txProvider.balance, equals(4930000.0));
    });

    test('recentTransactions hanya menampilkan maksimal 5 transaksi terbaru berurutan', () async {
      final baseDate = DateTime.now();

      // Tambahkan 7 transaksi berturut-turut
      for (int i = 1; i <= 7; i++) {
        await txProvider.addTransaction(
          userId: userIdA,
          category: 'Kategori $i',
          amount: i * 10000.0,
          type: TransactionType.expense,
          date: baseDate.add(Duration(minutes: i)),
        );
      }

      expect(txProvider.transactions.length, equals(7));
      expect(txProvider.recentTransactions.length, equals(5));

      // Transaksi terbaru harus yang tanggalnya paling akhir (Kategori 7)
      expect(txProvider.recentTransactions.first.category, equals('Kategori 7'));
    });

    test('Penghapusan transaksi langsung memperbarui saldo dan daftar transaksi', () async {
      final now = DateTime.now();

      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Bonus',
        amount: 1000000,
        type: TransactionType.income,
        date: now,
      );

      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Belanja',
        amount: 300000,
        type: TransactionType.expense,
        date: now,
      );

      expect(txProvider.balance, equals(700000.0));
      final txToDelete = txProvider.transactions.firstWhere((t) => t.category == 'Belanja');

      // Hapus transaksi belanja
      await txProvider.deleteTransaction(txToDelete.id!, userIdA);

      // Saldo kembali menjadi 1.000.000
      expect(txProvider.balance, equals(1000000.0));
      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.transactions.length, equals(1));
    });

    test('Data transaksi terisolasi antar pengguna (userIdA tidak bocor ke userIdB)', () async {
      final now = DateTime.now();

      // Transaksi milik User A
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Gaji A',
        amount: 10000000,
        type: TransactionType.income,
        date: now,
      );

      // Transaksi milik User B
      await txProvider.addTransaction(
        userId: userIdB,
        category: 'Gaji B',
        amount: 3000000,
        type: TransactionType.income,
        date: now,
      );

      // Cek data User A
      await txProvider.loadDashboardData(userIdA);
      expect(txProvider.totalIncome, equals(10000000.0));
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.category, equals('Gaji A'));

      // Cek data User B
      await txProvider.loadDashboardData(userIdB);
      expect(txProvider.totalIncome, equals(3000000.0));
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.category, equals('Gaji B'));
    });

    test('Anggaran bulanan dan pengeluaran riil per kategori terhitung akurat', () async {
      final now = DateTime.now();

      // 1. Pasang anggaran makanan: 500.000 untuk bulan berjalan
      await budgetProvider.setBudget(
        userId: userIdA,
        category: 'Makanan',
        amount: 500000,
        month: now.month,
        year: now.year,
      );

      // 2. Pasang anggaran transportasi: 200.000 untuk bulan berjalan
      await budgetProvider.setBudget(
        userId: userIdA,
        category: 'Transportasi',
        amount: 200000,
        month: now.month,
        year: now.year,
      );

      expect(budgetProvider.totalBudget, equals(700000.0));
      expect(budgetProvider.budgets.length, equals(2));

      // 3. Catat pengeluaran makanan 150.000 dan transportasi 50.000
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Makanan',
        amount: 150000,
        type: TransactionType.expense,
        date: now,
      );
      await txProvider.addTransaction(
        userId: userIdA,
        category: 'Transportasi',
        amount: 50000,
        type: TransactionType.expense,
        date: now,
      );

      // 4. Verifikasi ringkasan pengeluaran bulanan
      expect(txProvider.expenseSummary['Makanan'], equals(150000.0));
      expect(txProvider.expenseSummary['Transportasi'], equals(50000.0));
    });
  });
}

