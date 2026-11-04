import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/statistic_data.dart';
import '../utils/format_helper.dart';

/// Grafik Batang Perbandingan Pemasukan dan Pengeluaran (BarChart fl_chart).
class IncomeExpenseBarChart extends StatelessWidget {
  final List<IntervalStat> stats;
  final double maxY;

  const IncomeExpenseBarChart({
    super.key,
    required this.stats,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adjustedMaxY = maxY <= 0 ? 100000.0 : maxY * 1.25;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arus Kas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildLegendItem(
                    color: Colors.green.shade600,
                    label: 'Pemasukan',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    color: Colors.red.shade600,
                    label: 'Pengeluaran',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Area Grafik
          SizedBox(
            height: 210,
            child: stats.isEmpty
                ? const Center(child: Text('Belum ada data transaksi'))
                : BarChart(
                    BarChartData(
                      maxY: adjustedMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final stat = stats[groupIndex];
                            final isIncome = rodIndex == 0;
                            return BarTooltipItem(
                              '${stat.label}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: isIncome
                                      ? 'Masuk: ${FormatHelper.formatRupiah(stat.income)}'
                                      : 'Keluar: ${FormatHelper.formatRupiah(stat.expense)}',
                                  style: TextStyle(
                                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= stats.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  stats[index].label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(stats.length, (i) {
                        final stat = stats[i];
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            // Rod 0: Pemasukan (Hijau)
                            BarChartRodData(
                              toY: stat.income,
                              color: Colors.green.shade600,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            // Rod 1: Pengeluaran (Merah)
                            BarChartRodData(
                              toY: stat.expense,
                              color: Colors.red.shade600,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

