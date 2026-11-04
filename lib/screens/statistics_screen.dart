import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/statistic_data.dart';
import '../providers/statistics_provider.dart';
import '../utils/format_helper.dart';
import '../widgets/income_expense_bar_chart.dart';
import '../widgets/category_pie_chart.dart';

/// Halaman Statistik Keuangan Interaktif berbasis fl_chart.
///
/// Menyediakan:
/// 1. Pilihan periode Mingguan dan Bulanan
/// 2. Grafik batang arus kas pemasukan vs pengeluaran
/// 3. Grafik lingkaran proporsi pengeluaran berdasarkan kategori
/// 4. Ringkasan tabungan bersih (Net Savings)
class StatisticsScreen extends StatefulWidget {
  final int userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics(widget.userId);
    });
  }

  String _formatPeriodTitle(StatPeriod period, DateTime refDate) {
    if (period == StatPeriod.weekly) {
      final monday = DateTime(
        refDate.year,
        refDate.month,
        refDate.day - (refDate.weekday - 1),
      );
      final sunday = monday.add(const Duration(days: 6));
      return '${FormatHelper.formatDate(monday)} - ${FormatHelper.formatDate(sunday)}';
    } else {
      return FormatHelper.formatMonthYear(refDate.month, refDate.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Statistik Keuangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, statProvider, child) {
          return RefreshIndicator(
            onRefresh: () => statProvider.loadStatistics(widget.userId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Pemilih Periode (Mingguan / Bulanan) ──
                  Center(
                    child: SegmentedButton<StatPeriod>(
                      segments: const [
                        ButtonSegment(
                          value: StatPeriod.weekly,
                          label: Text('Mingguan'),
                          icon: Icon(
                            Icons.calendar_view_week_rounded,
                            size: 18,
                          ),
                        ),
                        ButtonSegment(
                          value: StatPeriod.monthly,
                          label: Text('Bulanan'),
                          icon: Icon(Icons.calendar_month_rounded, size: 18),
                        ),
                      ],
                      selected: {statProvider.period},
                      onSelectionChanged: (set) {
                        statProvider.setPeriod(set.first, widget.userId);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 2. Navigasi Geser Periode (Sebelumnya / Selanjutnya) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Periode Sebelumnya',
                          onPressed: () =>
                              statProvider.changeDateOffset(-1, widget.userId),
                        ),
                        Text(
                          _formatPeriodTitle(
                            statProvider.period,
                            statProvider.referenceDate,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Periode Selanjutnya',
                          onPressed: () =>
                              statProvider.changeDateOffset(1, widget.userId),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Kartu Ringkasan Periode ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Pemasukan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                FormatHelper.formatRupiah(
                                  statProvider.totalIncome,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 14),

                        // Pengeluaran
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                FormatHelper.formatRupiah(
                                  statProvider.totalExpense,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 14),

                        // Tabungan Bersih
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.savings_rounded,
                                    size: 14,
                                    color: statProvider.netSavings >= 0
                                        ? Colors.teal
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Selisih',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                FormatHelper.formatRupiah(
                                  statProvider.netSavings,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statProvider.netSavings >= 0
                                      ? Colors.teal.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (statProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // ── 4. Grafik Batang Arus Kas (Income vs Expense) ──
                    IncomeExpenseBarChart(
                      stats: statProvider.intervalStats,
                      maxY: statProvider.maxIntervalValue,
                    ),
                    const SizedBox(height: 20),

                    // ── 5. Grafik Lingkaran Pengeluaran per Kategori ──
                    CategoryPieChart(
                      categoryStats: statProvider.categoryStats,
                      totalExpense: statProvider.totalExpense,
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
