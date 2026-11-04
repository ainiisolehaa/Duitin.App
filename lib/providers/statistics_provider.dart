import 'package:flutter/foundation.dart';

import '../models/statistic_data.dart';
import '../repositories/transaction_repository.dart';
import '../utils/format_helper.dart';

/// Provider untuk mengelola kalkulasi dan state visualisasi statistik keuangan.
///
/// Mengambil data aktual dari database lokal SQLite via [TransactionRepository],
/// mendukung periode mingguan dan bulanan, serta merefresh grafik secara otomatis.
class StatisticsProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  StatPeriod _period = StatPeriod.weekly;
  DateTime _referenceDate = DateTime.now();

  List<IntervalStat> _intervalStats = [];
  List<CategoryStat> _categoryStats = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = false;
  String? _errorMessage;

  StatisticsProvider({TransactionRepository? repository})
    : _repository = repository ?? TransactionRepository();

  // ──────────── GETTERS ────────────

  StatPeriod get period => _period;
  DateTime get referenceDate => _referenceDate;
  List<IntervalStat> get intervalStats => List.unmodifiable(_intervalStats);
  List<CategoryStat> get categoryStats => List.unmodifiable(_categoryStats);
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get netSavings => _totalIncome - _totalExpense;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get maxIntervalValue {
    if (_intervalStats.isEmpty) return 100000;
    double maxVal = 0;
    for (final s in _intervalStats) {
      if (s.maxAmount > maxVal) maxVal = s.maxAmount;
    }
    return maxVal > 0 ? maxVal : 100000;
  }

  // ──────────── METHODS ────────────

  /// Ganti jenis periode (Mingguan / Bulanan) dan hitung ulang data.
  Future<void> setPeriod(StatPeriod period, int userId) async {
    _period = period;
    notifyListeners();
    await loadStatistics(userId);
  }

  /// Pindah ke periode sebelumnya atau berikutnya (misal ganti bulan/minggu).
  Future<void> changeDateOffset(int offset, int userId) async {
    if (_period == StatPeriod.weekly) {
      _referenceDate = _referenceDate.add(Duration(days: offset * 7));
    } else {
      _referenceDate = DateTime(
        _referenceDate.year,
        _referenceDate.month + offset,
        1,
      );
    }
    notifyListeners();
    await loadStatistics(userId);
  }

  /// Muat data statistik aktual dari database SQLite sesuai periode yang dipilih.
  Future<void> loadStatistics(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_period == StatPeriod.weekly) {
        await _calculateWeeklyStats(userId);
      } else {
        await _calculateMonthlyStats(userId);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data statistik: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kalkulasi statistik mingguan (Senin s/d Minggu).
  Future<void> _calculateWeeklyStats(int userId) async {
    final now = _referenceDate;
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sunday = DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
      23,
      59,
      59,
      999,
    );

    final transactions = await _repository.getTransactionsByDateRange(
      userId: userId,
      startDate: monday,
      endDate: sunday,
    );

    final List<String> dayLabels = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];
    final List<double> dailyIncomes = List.filled(7, 0.0);
    final List<double> dailyExpenses = List.filled(7, 0.0);
    final Map<String, double> categoryMap = {};

    double sumIncome = 0;
    double sumExpense = 0;

    for (final tx in transactions) {
      final dayIndex = tx.date.weekday - 1; // 1 = Senin -> index 0
      if (dayIndex >= 0 && dayIndex < 7) {
        if (tx.isIncome) {
          dailyIncomes[dayIndex] += tx.amount;
          sumIncome += tx.amount;
        } else {
          dailyExpenses[dayIndex] += tx.amount;
          sumExpense += tx.amount;
          categoryMap[tx.category] =
              (categoryMap[tx.category] ?? 0) + tx.amount;
        }
      }
    }

    _intervalStats = List.generate(7, (i) {
      return IntervalStat(
        label: dayLabels[i],
        income: dailyIncomes[i],
        expense: dailyExpenses[i],
        date: monday.add(Duration(days: i)),
      );
    });

    _totalIncome = sumIncome;
    _totalExpense = sumExpense;
    _categoryStats = _buildCategoryStats(categoryMap, sumExpense);
  }

  /// Kalkulasi statistik bulanan (dibagi per minggu dalam bulan).
  Future<void> _calculateMonthlyStats(int userId) async {
    final now = _referenceDate;
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    final transactions = await _repository.getTransactionsByDateRange(
      userId: userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Bagi bulan menjadi 4 bagian interval (W1: 1-7, W2: 8-14, W3: 15-21, W4: 22-akhir)
    final List<String> weekLabels = ['Mgg 1', 'Mgg 2', 'Mgg 3', 'Mgg 4'];
    final List<double> weeklyIncomes = List.filled(4, 0.0);
    final List<double> weeklyExpenses = List.filled(4, 0.0);
    final Map<String, double> categoryMap = {};

    double sumIncome = 0;
    double sumExpense = 0;

    for (final tx in transactions) {
      final day = tx.date.day;
      int weekIndex;
      if (day <= 7) {
        weekIndex = 0;
      } else if (day <= 14) {
        weekIndex = 1;
      } else if (day <= 21) {
        weekIndex = 2;
      } else {
        weekIndex = 3;
      }

      if (tx.isIncome) {
        weeklyIncomes[weekIndex] += tx.amount;
        sumIncome += tx.amount;
      } else {
        weeklyExpenses[weekIndex] += tx.amount;
        sumExpense += tx.amount;
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
      }
    }

    _intervalStats = List.generate(4, (i) {
      return IntervalStat(
        label: weekLabels[i],
        income: weeklyIncomes[i],
        expense: weeklyExpenses[i],
      );
    });

    _totalIncome = sumIncome;
    _totalExpense = sumExpense;
    _categoryStats = _buildCategoryStats(categoryMap, sumExpense);
  }

  /// Konversi map pengeluaran per kategori menjadi daftar `CategoryStat` lengkap dengan persentase & warna.
  List<CategoryStat> _buildCategoryStats(
    Map<String, double> categoryMap,
    double totalExpense,
  ) {
    if (totalExpense <= 0 || categoryMap.isEmpty) return [];

    final list = categoryMap.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100.0;
      return CategoryStat(
        category: entry.key,
        amount: entry.value,
        percentage: percentage,
        color: FormatHelper.getCategoryColor(entry.key),
      );
    }).toList();

    // Urutkan dari pengeluaran terbesar
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}
