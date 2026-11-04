import 'package:flutter/material.dart';

/// Jenis periode waktu untuk grafik statistik.
enum StatPeriod {
  weekly('Mingguan'),
  monthly('Bulanan');

  final String label;
  const StatPeriod(this.label);
}

/// Data ringkasan pendapatan dan pengeluaran per interval waktu (hari atau minggu).
class IntervalStat {
  final String label; // e.g. "Sen", "Sel" atau "M1", "M2"
  final double income;
  final double expense;
  final DateTime? date;

  IntervalStat({
    required this.label,
    required this.income,
    required this.expense,
    this.date,
  });

  double get maxAmount => income > expense ? income : expense;
}

/// Data statistik per kategori untuk PieChart.
class CategoryStat {
  final String category;
  final double amount;
  final double percentage; // 0.0 - 100.0
  final Color color;

  CategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

