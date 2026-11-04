import 'package:flutter/material.dart';

import 'budget.dart';

/// Status batas penggunaan anggaran.
enum BudgetStatus {
  safe('Aman', Colors.teal),
  warning('Mendekati Batas', Colors.orange),
  danger('Melewati Batas', Colors.red);

  final String label;
  final Color color;
  const BudgetStatus(this.label, this.color);
}

/// Model kalkulasi detail anggaran per kategori vs pengeluaran aktual.
class CategoryBudgetDetail {
  final Budget budget;
  final double spent;

  CategoryBudgetDetail({required this.budget, required this.spent});

  String get category => budget.category;
  double get amount => budget.amount;
  double get remaining => amount - spent;
  double get percentage => amount > 0 ? (spent / amount) * 100.0 : 0.0;
  double get progressRatio => (percentage / 100.0).clamp(0.0, 1.0);

  BudgetStatus get status {
    if (spent >= amount) return BudgetStatus.danger;
    if (percentage >= 80.0) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  bool get isOverBudget => spent >= amount;
  bool get isNearLimit => percentage >= 80.0 && !isOverBudget;
}
