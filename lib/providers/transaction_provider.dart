import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Provider untuk mengelola state transaksi.
///
/// Menyediakan daftar transaksi, pencarian, filter komprehensif langsung ke SQLite,
/// ringkasan keuangan (saldo, pemasukan, pengeluaran), dan method CRUD.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  List<String> _userCategories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _expenseSummary = {};
  bool _isLoading = false;
  bool _isFilterLoading = false;
  String? _errorMessage;

  TransactionProvider({TransactionRepository? repository})
    : _repository = repository ?? TransactionRepository();

  // ──────────── GETTERS ────────────

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Transaction> get filteredTransactions =>
      List.unmodifiable(_filteredTransactions);
  List<String> get userCategories => List.unmodifiable(_userCategories);

  /// Transaksi terbaru (maksimal 5 transaksi teratas).
  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;
  Map<String, double> get expenseSummary => Map.unmodifiable(_expenseSummary);
  bool get isLoading => _isLoading;
  bool get isFilterLoading => _isFilterLoading;
  String? get errorMessage => _errorMessage;

  // ──────────── METHODS ────────────

  /// Muat data lengkap dashboard untuk user tertentu (transaksi, total, summary pengeluaran bulanan).
  Future<void> loadDashboardData(int userId) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      _transactions = await _repository.getTransactionsByUserId(userId);
      _filteredTransactions = List.from(_transactions);
      try {
        _userCategories = await _repository.getDistinctCategories(userId);
      } catch (_) {
        _userCategories = _transactions.map((t) => t.category).toSet().toList();
      }
      _totalIncome = await _repository.getTotalByType(
        userId: userId,
        type: TransactionType.income,
      );
      _totalExpense = await _repository.getTotalByType(
        userId: userId,
        type: TransactionType.expense,
      );
      _expenseSummary = await _repository.getExpenseSummaryByCategory(
        userId: userId,
        month: now.month,
        year: now.year,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data transaksi: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Muat semua transaksi milik user tertentu.
  Future<void> loadTransactions(int userId) async {
    await loadDashboardData(userId);
  }

  /// Filter transaksi langsung dari SQLite dengan kombinasi pencarian, tipe, kategori, dan rentang tanggal.
  Future<void> filterTransactions({
    required int userId,
    String? searchQuery,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isFilterLoading = true;
    notifyListeners();

    try {
      _filteredTransactions = await _repository.getTransactionsFiltered(
        userId: userId,
        searchQuery: searchQuery,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memfilter transaksi: $e';
    } finally {
      _isFilterLoading = false;
      notifyListeners();
    }
  }

  /// Muat daftar kategori unik yang pernah digunakan oleh pengguna.
  Future<void> loadUserCategories(int userId) async {
    try {
      _userCategories = await _repository.getDistinctCategories(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat kategori: $e';
    }
  }

  /// Tambah transaksi baru dan langsung perbarui state dashboard.
  ///
  /// Mengembalikan `true` jika transaksi berhasil disimpan.
  Future<bool> addTransaction({
    required int userId,
    required String category,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? note,
  }) async {
    _setLoading(true);
    try {
      final transaction = Transaction(
        userId: userId,
        category: category,
        amount: amount,
        type: type,
        date: date,
        note: note,
      );
      await _repository.insertTransaction(transaction);
      _errorMessage = null;
      await loadDashboardData(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah transaksi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update transaksi yang sudah ada dan langsung perbarui state dashboard.
  ///
  /// Mengembalikan `true` jika transaksi berhasil diperbarui.
  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      await _repository.updateTransaction(transaction);
      _errorMessage = null;
      await loadDashboardData(transaction.userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal update transaksi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Hapus transaksi berdasarkan ID dan langsung perbarui state dashboard.
  ///
  /// Mengembalikan `true` jika transaksi berhasil dihapus.
  Future<bool> deleteTransaction(int id, int userId) async {
    _setLoading(true);
    try {
      await _repository.deleteTransaction(id);
      _errorMessage = null;
      await loadDashboardData(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus transaksi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Muat transaksi berdasarkan rentang tanggal.
  Future<void> loadTransactionsByDateRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    try {
      _transactions = await _repository.getTransactionsByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat transaksi: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Muat ringkasan pengeluaran per kategori untuk bulan tertentu.
  Future<void> loadExpenseSummary({
    required int userId,
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    try {
      _expenseSummary = await _repository.getExpenseSummaryByCategory(
        userId: userId,
        month: month,
        year: year,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat ringkasan: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Ambil saldo terkini untuk user.
  Future<double> getBalance(int userId) async {
    return await _repository.getBalance(userId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
