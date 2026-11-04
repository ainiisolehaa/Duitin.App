import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../utils/format_helper.dart';

/// Kartu ringkasan anggaran bulanan (Budget Summary).
///
/// Menghitung total anggaran vs pengeluaran aktual per kategori
/// secara dinamis untuk bulan berjalan.
class BudgetSummaryCard extends StatelessWidget {
  final List<Budget> budgets;
  final double totalBudget;
  final Map<String, double> expenseSummary;
  final VoidCallback onAddBudget;
  final VoidCallback? onViewDetails;

  const BudgetSummaryCard({
    super.key,
    required this.budgets,
    required this.totalBudget,
    required this.expenseSummary,
    required this.onAddBudget,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Hitung total pengeluaran untuk semua kategori yang dianggarkan
    double totalSpentForBudgets = 0;
    for (final budget in budgets) {
      final spent = expenseSummary[budget.category] ?? 0;
      totalSpentForBudgets += spent;
    }

    final double percentage = totalBudget > 0
        ? (totalSpentForBudgets / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final bool isOverBudget = totalBudget > 0 && totalSpentForBudgets > totalBudget;
    final double remainingBudget = totalBudget - totalSpentForBudgets;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Judul & Tombol Tambah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.pie_chart_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anggaran Bulan Ini',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              FormatHelper.formatMonthYear(now.month, now.year),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onViewDetails != null) ...[
                      TextButton(
                        onPressed: onViewDetails,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text(
                          'Detail',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: onAddBudget,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Atur',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (budgets.isEmpty) ...[
              // Tampilan saat belum ada anggaran
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 38,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada anggaran bulan ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur batas pengeluaran per kategori agar keuanganmu tetap terkontrol.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Ringkasan Anggaran Keseluruhan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terpakai ${FormatHelper.formatRupiah(totalSpentForBudgets)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? Colors.red : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'dari ${FormatHelper.formatRupiah(totalBudget)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? Colors.red
                        : percentage > 0.8
                            ? Colors.orange
                            : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Info Sisa Anggaran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}% terpakai',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverBudget ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    isOverBudget
                        ? 'Melebihi budget ${FormatHelper.formatRupiah(totalSpentForBudgets - totalBudget)}'
                        : 'Sisa ${FormatHelper.formatRupiah(remainingBudget)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverBudget ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Daftar Anggaran Per Kategori
              Column(
                children: budgets.map((b) {
                  final spent = expenseSummary[b.category] ?? 0;
                  final catPercentage = (spent / b.amount).clamp(0.0, 1.0);
                  final catOver = spent > b.amount;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FormatHelper.getCategoryIcon(b.category),
                              size: 16,
                              color: FormatHelper.getCategoryColor(b.category),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${FormatHelper.formatRupiah(spent)} / ${FormatHelper.formatRupiah(b.amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: catOver
                                    ? Colors.red
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: catPercentage,
                            minHeight: 5,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              catOver
                                  ? Colors.red
                                  : FormatHelper.getCategoryColor(b.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

