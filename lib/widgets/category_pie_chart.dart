import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/statistic_data.dart';
import '../utils/format_helper.dart';

/// Grafik Lingkaran Pengeluaran Berdasarkan Kategori (PieChart fl_chart).
class CategoryPieChart extends StatefulWidget {
  final List<CategoryStat> categoryStats;
  final double totalExpense;

  const CategoryPieChart({
    super.key,
    required this.categoryStats,
    required this.totalExpense,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.categoryStats;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengeluaran per Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                FormatHelper.formatRupiah(widget.totalExpense),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (stats.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada pengeluaran pada periode ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Donut PieChart
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 48,
                      sections: List.generate(stats.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final radius = isTouched ? 42.0 : 36.0;
                        final stat = stats[i];

                        return PieChartSectionData(
                          color: stat.color,
                          value: stat.amount,
                          title: isTouched
                              ? '${stat.percentage.toStringAsFixed(1)}%'
                              : stat.percentage >= 10
                                  ? '${stat.percentage.toStringAsFixed(0)}%'
                                  : '',
                          radius: radius,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${stats.length} Pos',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daftar Rincian Kategori & Nominal
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              separatorBuilder: (_, _) => const Divider(height: 14),
              itemBuilder: (context, i) {
                final stat = stats[i];
                final isSelected = i == _touchedIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == i ? -1 : i;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: stat.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          FormatHelper.getCategoryIcon(stat.category),
                          size: 18,
                          color: stat.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stat.category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              FormatHelper.formatRupiah(stat.amount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${stat.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

