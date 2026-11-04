import 'package:flutter_test/flutter_test.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/models/budget.dart';
import 'package:duitin/providers/transaction_provider.dart';
import 'package:duitin/providers/budget_provider.dart';
import 'package:duitin/repositories/transaction_repository.dart';
import 'package:duitin/repositories/budget_repository.dart';

// Mock TransactionRepository untuk pengujian CRUD transaksi
class MockTransactionRepository extends TransactionRepository {
  final List<Transaction> _items = [];
  int _counter = 1;

  @override
  Future<int> insertTransaction(Transaction transaction) async {
    final id = _counter++;
    final newTx = transaction.copyWith(id: id);
    _items.add(newTx);
    return id;
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByUserId(int userId) async {
    final list = _items.where((t) => t.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<int> updateTransaction(Transaction transaction) async {
    final index = _items.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _items[index] = transaction;
      return 1;
    }
    return 0;
  }

  @override
  Future<List<String>> getDistinctCategories(int userId) async {
    return _items
        .where((t) => t.userId == userId)
        .map((t) => t.category)
        .toSet()
        .toList();
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final countBefore = _items.length;
    _items.removeWhere((t) => t.id == id);
    return countBefore - _items.length;
  }

  @override
  Future<double> getTotalByType({
    required int userId,
    required TransactionType type,
  }) async {
    return _items
        .where((t) => t.userId == userId && t.type == type)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<Map<String, double>> getExpenseSummaryByCategory({
    required int userId,
    required int month,
    required int year,
  }) async {
    final Map<String, double> summary = {};
    for (final t in _items) {
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

// Mock BudgetRepository
class MockBudgetRepository extends BudgetRepository {
  final List<Budget> _budgets = [];

  @override
  Future<int> insertBudget(Budget budget) async {
    _budgets.add(budget);
    return 1;
  }

  @override
  Future<List<Budget>> getBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _budgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .toList();
  }

  @override
  Future<double> getTotalBudgetByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return _budgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .fold<double>(0.0, (sum, b) => sum + b.amount);
  }
}

void main() {
  group('Tahap 5: Fitur CRUD Transaksi (Tambah, Edit, Detail, Hapus)', () {
    late MockTransactionRepository mockTxRepo;
    late MockBudgetRepository mockBudgetRepo;
    late TransactionProvider txProvider;
    late BudgetProvider budgetProvider;

    const int activeUserId = 101;
    const int otherUserId = 102;

    setUp(() {
      mockTxRepo = MockTransactionRepository();
      mockBudgetRepo = MockBudgetRepository();
      txProvider = TransactionProvider(repository: mockTxRepo);
      budgetProvider = BudgetProvider(repository: mockBudgetRepo);
    });

    test('1. Tambah Transaksi Pemasukan & Pengeluaran berhasil dan terhitung dinamis', () async {
      final now = DateTime.now();

      // Tambah Pemasukan
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Gaji',
        amount: 8000000,
        type: TransactionType.income,
        date: now,
        note: 'Gaji bulanan kantor',
      );

      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.totalIncome, equals(8000000.0));
      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.balance, equals(8000000.0));
      expect(txProvider.transactions.first.note, equals('Gaji bulanan kantor'));

      // Tambah Pengeluaran
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Makanan',
        amount: 45000,
        type: TransactionType.expense,
        date: now,
        note: 'Makan siang ayam geprek',
      );

      expect(txProvider.transactions.length, equals(2));
      expect(txProvider.totalIncome, equals(8000000.0));
      expect(txProvider.totalExpense, equals(45000.0));
      expect(txProvider.balance, equals(8000000 - 45000));
      expect(txProvider.expenseSummary['Makanan'], equals(45000.0));
    });

    test('2. Edit Transaksi mengubah nilai dan memperbarui saldo serta ringkasan secara instan', () async {
      final now = DateTime.now();

      // Buat transaksi awal
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Transportasi',
        amount: 50000,
        type: TransactionType.expense,
        date: now,
        note: 'Ojek online',
      );

      final originalTx = txProvider.transactions.first;
      expect(originalTx.amount, equals(50000.0));
      expect(txProvider.totalExpense, equals(50000.0));

      // Edit transaksi: ubah amount jadi 75000 dan ubah catatan
      final updatedTx = originalTx.copyWith(
        amount: 75000,
        note: 'Ojek online + tip',
        updatedAt: DateTime.now(),
      );

      await txProvider.updateTransaction(updatedTx);

      // Verifikasi data setelah edit
      expect(txProvider.transactions.first.amount, equals(75000.0));
      expect(txProvider.transactions.first.note, equals('Ojek online + tip'));
      expect(txProvider.totalExpense, equals(75000.0));
      expect(txProvider.balance, equals(-75000.0));
      expect(txProvider.expenseSummary['Transportasi'], equals(75000.0));
    });

    test('3. Edit Tipe Transaksi (Pengeluaran menjadi Pemasukan)', () async {
      final now = DateTime.now();

      // Tambah salah catat sebagai pengeluaran
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Bonus',
        amount: 500000,
        type: TransactionType.expense,
        date: now,
      );

      expect(txProvider.totalExpense, equals(500000.0));
      expect(txProvider.totalIncome, equals(0.0));

      // Edit tipe menjadi pemasukan
      final tx = txProvider.transactions.first;
      final correctedTx = tx.copyWith(type: TransactionType.income);
      await txProvider.updateTransaction(correctedTx);

      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.totalIncome, equals(500000.0));
      expect(txProvider.balance, equals(500000.0));
    });

    test('4. Hapus Transaksi menghapus data dari DB dan mengembalikan saldo', () async {
      final now = DateTime.now();

      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Gaji',
        amount: 5000000,
        type: TransactionType.income,
        date: now,
      );
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Belanja',
        amount: 1500000,
        type: TransactionType.expense,
        date: now,
      );

      expect(txProvider.transactions.length, equals(2));
      expect(txProvider.balance, equals(3500000.0));

      // Ambil transaksi belanja untuk dihapus
      final expenseTx = txProvider.transactions.firstWhere((t) => t.category == 'Belanja');
      await txProvider.deleteTransaction(expenseTx.id!, activeUserId);

      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.totalExpense, equals(0.0));
      expect(txProvider.balance, equals(5000000.0));
      expect(txProvider.expenseSummary['Belanja'], isNull);
    });

    test('5. Isolasi Transaksi antar Pengguna (User A vs User B)', () async {
      final now = DateTime.now();

      // Transaksi User A
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Makan A',
        amount: 30000,
        type: TransactionType.expense,
        date: now,
      );

      // Transaksi User B
      await txProvider.addTransaction(
        userId: otherUserId,
        category: 'Makan B',
        amount: 80000,
        type: TransactionType.expense,
        date: now,
      );

      // Load data User A
      await txProvider.loadDashboardData(activeUserId);
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.category, equals('Makan A'));
      expect(txProvider.totalExpense, equals(30000.0));

      // Load data User B
      await txProvider.loadDashboardData(otherUserId);
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.category, equals('Makan B'));
      expect(txProvider.totalExpense, equals(80000.0));
    });

    test('6. Sinkronisasi Anggaran saat transaksi berubah', () async {
      final now = DateTime.now();

      // Pasang anggaran makanan 200.000
      await budgetProvider.setBudget(
        userId: activeUserId,
        category: 'Makanan',
        amount: 200000,
        month: now.month,
        year: now.year,
      );

      // Catat makan siang 50.000
      await txProvider.addTransaction(
        userId: activeUserId,
        category: 'Makanan',
        amount: 50000,
        type: TransactionType.expense,
        date: now,
      );

      expect(txProvider.expenseSummary['Makanan'], equals(50000.0));

      // Edit makan siang menjadi 120.000
      final tx = txProvider.transactions.first;
      await txProvider.updateTransaction(tx.copyWith(amount: 120000));

      expect(txProvider.expenseSummary['Makanan'], equals(120000.0));
    });
  });
}

