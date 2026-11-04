import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/budget_detail.dart';
import '../repositories/budget_repository.dart';
import '../repositories/transaction_repository.dart';

/// Provider untuk mengelola state anggaran (budget) bulanan.
///
/// Mengkalkulasi:
/// 1. Total nominal anggaran yang dipasang
/// 2. Total pengeluaran aktual bulan berjalan (dari SQLite transaksi)
/// 3. Sisa anggaran (remaining budget)
/// 4. Persentase penggunaan anggaran
/// 5. Indikator dan peringatan batas (Aman, Waspada, Melewati Batas)
class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository;
  final TransactionRepository _txRepository;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  List<Budget> _budgets = [];
  Map<String, double> _monthlyExpenses = {};
  double _totalBudget = 0;
  double _totalActualExpense = 0;
  bool _isLoading = false;
  String? _errorMessage;

  BudgetProvider({
    BudgetRepository? repository,
    TransactionRepository? txRepository,
  }) : _repository = repository ?? BudgetRepository(),
       _txRepository = txRepository ?? TransactionRepository();

  // ──────────── GETTERS ────────────

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  List<Budget> get budgets => List.unmodifiable(_budgets);
  Map<String, double> get monthlyExpenses => Map.unmodifiable(_monthlyExpenses);
  double get totalBudget => _totalBudget;
  double get totalActualExpense => _totalActualExpense;
  double get remainingBudget => _totalBudget - _totalActualExpense;
  double get usagePercentage =>
      _totalBudget > 0 ? (_totalActualExpense / _totalBudget) * 100.0 : 0.0;
  double get progressRatio => (usagePercentage / 100.0).clamp(0.0, 1.0);

  bool get isNearLimit => usagePercentage >= 80.0 && usagePercentage < 100.0;
  bool get isOverBudget =>
      _totalBudget > 0 && _totalActualExpense >= _totalBudget;

  BudgetStatus get overallStatus {
    if (isOverBudget) return BudgetStatus.danger;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Detail rincian anggaran per pos kategori
  List<CategoryBudgetDetail> get categoryDetails {
    return _budgets.map((b) {
      final spent = _monthlyExpenses[b.category] ?? 0.0;
      return CategoryBudgetDetail(budget: b, spent: spent);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ──────────── METHODS ────────────

  /// Muat anggaran dan pengeluaran bulan berjalan untuk user tertentu.
  Future<void> loadCurrentMonthBudgets(int userId) async {
    final now = DateTime.now();
    await loadBudgets(userId: userId, month: now.month, year: now.year);
  }

  /// Geser bulan anggaran (sebelumnya / berikutnya).
  Future<void> changeMonth(int offset, int userId) async {
    int newMonth = _selectedMonth + offset;
    int newYear = _selectedYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    await loadBudgets(userId: userId, month: newMonth, year: newYear);
  }

  /// Muat data anggaran dan pengeluaran riil dari SQLite pada bulan/tahun tertentu.
  Future<void> loadBudgets({
    required int userId,
    required int month,
    required int year,
  }) async {
    _selectedMonth = month;
    _selectedYear = year;
    _setLoading(true);

    try {
      // 1. Ambil anggaran dari SQLite
      _budgets = await _repository.getBudgetsByMonth(
        userId: userId,
        month: month,
        year: year,
      );
      _totalBudget = await _repository.getTotalBudgetByMonth(
        userId: userId,
        month: month,
        year: year,
      );

      // 2. Ambil pengeluaran riil bulan berjalan dari SQLite
      _monthlyExpenses = await _txRepository.getExpenseSummaryByCategory(
        userId: userId,
        month: month,
        year: year,
      );

      // 3. Hitung total pengeluaran untuk pos yang dianggarkan
      double sumExpense = 0;
      for (final b in _budgets) {
        sumExpense += (_monthlyExpenses[b.category] ?? 0.0);
      }
      _totalActualExpense = sumExpense;

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat anggaran: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Tambah atau update batas anggaran kategori tertentu.
  ///
  /// Mengembalikan `true` jika anggaran berhasil disimpan.
  Future<bool> setBudget({
    required int userId,
    required String category,
    required double amount,
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    try {
      final budget = Budget(
        userId: userId,
        category: category,
        amount: amount,
        month: month,
        year: year,
      );
      await _repository.insertBudget(budget);
      _errorMessage = null;
      await loadBudgets(userId: userId, month: month, year: year);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan budget: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update budget yang sudah ada.
  Future<void> updateBudget(Budget budget) async {
    _setLoading(true);
    try {
      await _repository.updateBudget(budget);
      _errorMessage = null;
      await loadBudgets(
        userId: budget.userId,
        month: budget.month,
        year: budget.year,
      );
    } catch (e) {
      _errorMessage = 'Gagal update budget: $e';
      _setLoading(false);
    }
  }

  /// Hapus budget berdasarkan ID.
  ///
  /// Mengembalikan `true` jika anggaran berhasil dihapus.
  Future<bool> deleteBudget(
    int id, {
    required int userId,
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    try {
      await _repository.deleteBudget(id);
      _errorMessage = null;
      await loadBudgets(userId: userId, month: month, year: year);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus budget: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Hapus semua budget pada bulan/tahun tertentu.
  Future<void> deleteAllBudgetsForMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    try {
      await _repository.deleteBudgetsByMonth(
        userId: userId,
        month: month,
        year: year,
      );
      _errorMessage = null;
      await loadBudgets(userId: userId, month: month, year: year);
    } catch (e) {
      _errorMessage = 'Gagal menghapus budget: $e';
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
