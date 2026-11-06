import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_detail.dart';
import '../providers/budget_provider.dart';
import '../utils/format_helper.dart';
import '../widgets/add_budget_dialog.dart';

/// Halaman Pengelolaan Anggaran Bulanan (Budget Screen).
///
/// Menampilkan:
/// 1. Pilihan navigasi bulan (sebelumnya / berikutnya)
/// 2. Total nominal anggaran, pengeluaran riil, sisa anggaran, dan persentase penggunaan
/// 3. Banner peringatan dinamis saat anggaran mendekati atau melewati batas
/// 4. Rincian anggaran per kategori dengan progress bar & opsi edit/hapus
class BudgetScreen extends StatefulWidget {
  final int userId;

  const BudgetScreen({super.key, required this.userId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadCurrentMonthBudgets(widget.userId);
    });
  }

  void _openAddBudget({String? initialCategory, double? initialAmount}) {
    AddBudgetDialog.show(
      context,
      userId: widget.userId,
      initialCategory: initialCategory,
      initialAmount: initialAmount,
    );
  }

  Future<void> _handleDeleteCategoryBudget(CategoryBudgetDetail item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggaran?'),
        content: Text(
          'Batas anggaran untuk pos "${item.category}" sebesar ${FormatHelper.formatRupiah(item.amount)} akan dihapus.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<BudgetProvider>();
    final success = await provider.deleteBudget(
      item.budget.id!,
      userId: widget.userId,
      month: provider.selectedMonth,
      year: provider.selectedYear,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Anggaran gagal dihapus. Coba lagi.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Anggaran "${item.category}" berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final month = budgetProvider.selectedMonth;
          final year = budgetProvider.selectedYear;
          final totalBudget = budgetProvider.totalBudget;
          final totalSpent = budgetProvider.totalActualExpense;
          final remaining = budgetProvider.remainingBudget;
          final percentage = budgetProvider.usagePercentage;
          final progressRatio = budgetProvider.progressRatio;
          final isOver = budgetProvider.isOverBudget;
          final isWarning = budgetProvider.isNearLimit;
          final categoryDetails = budgetProvider.categoryDetails;

          return RefreshIndicator(
            onRefresh: () => budgetProvider.loadBudgets(
              userId: widget.userId,
              month: month,
              year: year,
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Navigasi Pilihan Bulan ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Bulan Sebelumnya',
                          onPressed: () =>
                              budgetProvider.changeMonth(-1, widget.userId),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              FormatHelper.formatMonthYear(month, year),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Bulan Selanjutnya',
                          onPressed: () =>
                              budgetProvider.changeMonth(1, widget.userId),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Kartu Utama Ringkasan Anggaran Bulanan ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isOver
                            ? Colors.red.shade300
                            : isWarning
                            ? Colors.orange.shade300
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                        width: isOver || isWarning ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isOver
                                      ? Colors.red
                                      : isWarning
                                      ? Colors.orange
                                      : theme.colorScheme.primary)
                                  .withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Anggaran',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isOver
                                            ? Colors.red
                                            : isWarning
                                            ? Colors.orange
                                            : Colors.teal)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOver
                                        ? Icons.warning_rounded
                                        : isWarning
                                        ? Icons.priority_high_rounded
                                        : Icons.check_circle_rounded,
                                    size: 14,
                                    color: isOver
                                        ? Colors.red.shade700
                                        : isWarning
                                        ? Colors.orange.shade800
                                        : Colors.teal.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOver
                                        ? 'Melewati Batas'
                                        : isWarning
                                        ? 'Mendekati Batas'
                                        : 'Aman',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOver
                                          ? Colors.red.shade700
                                          : isWarning
                                          ? Colors.orange.shade800
                                          : Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Nominal Anggaran
                        Text(
                          FormatHelper.formatRupiah(totalBudget),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Progress Bar Besar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 12,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver
                                  ? Colors.red.shade600
                                  : isWarning
                                  ? Colors.orange.shade600
                                  : Colors.teal.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Informasi Pengeluaran & Sisa
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terpakai (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  FormatHelper.formatRupiah(totalSpent),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOver
                                        ? Colors.red.shade700
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isOver
                                      ? 'Kelebihan Anggaran'
                                      : 'Sisa Anggaran',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  FormatHelper.formatRupiah(remaining.abs()),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isOver
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Banner Peringatan Dinamis ──
                  if (totalBudget > 0) ...[
                    if (isOver) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peringatan: Anggaran Terlampaui!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pengeluaran Anda telah melewati batas anggaran sebesar ${FormatHelper.formatRupiah(remaining.abs())}. Disarankan untuk membatasi pengeluaran non-esensial.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isWarning) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade800,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perhatian: Mendekati Batas Anggaran!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pengeluaran telah mencapai ${percentage.toStringAsFixed(1)}% dari batas yang ditentukan. Tersisa ${FormatHelper.formatRupiah(remaining)} untuk bulan ini.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Colors.teal.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pengeluaran bulan ini terkendali dengan baik (${percentage.toStringAsFixed(1)}% terpakai).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // ── 4. Rincian Batas Anggaran per Kategori ──
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pos Anggaran Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (categoryDetails.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada anggaran untuk bulan ini',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tentukan batas pengeluaran untuk kategori seperti Makanan, Transportasi, atau Belanja agar pengeluaran tetap terkontrol.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => _openAddBudget(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Pasang Anggaran Pertama'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoryDetails.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = categoryDetails[i];
                        final catColor = FormatHelper.getCategoryColor(
                          item.category,
                        );
                        final itemStatus = item.status;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: itemStatus == BudgetStatus.danger
                                  ? Colors.red.shade300
                                  : itemStatus == BudgetStatus.warning
                                  ? Colors.orange.shade300
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      FormatHelper.getCategoryIcon(
                                        item.category,
                                      ),
                                      size: 22,
                                      color: catColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          itemStatus == BudgetStatus.danger
                                              ? 'Terlampaui ${FormatHelper.formatRupiah(item.remaining.abs())}'
                                              : 'Sisa ${FormatHelper.formatRupiah(item.remaining)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                itemStatus ==
                                                    BudgetStatus.danger
                                                ? Colors.red.shade700
                                                : itemStatus ==
                                                      BudgetStatus.warning
                                                ? Colors.orange.shade800
                                                : Colors.teal.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _openAddBudget(
                                          initialCategory: item.category,
                                          initialAmount: item.amount,
                                        );
                                      } else if (val == 'delete') {
                                        _handleDeleteCategoryBudget(item);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Ubah Anggaran'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Hapus Anggaran',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Progress Bar Kategori
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: item.progressRatio,
                                  minHeight: 8,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    itemStatus == BudgetStatus.danger
                                        ? Colors.red.shade600
                                        : itemStatus == BudgetStatus.warning
                                        ? Colors.orange.shade600
                                        : catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Nominal Real vs Budget
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.percentage.toStringAsFixed(0)}% terpakai',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: itemStatus == BudgetStatus.danger
                                          ? Colors.red.shade700
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(
                                    '${FormatHelper.formatRupiah(item.spent)} / ${FormatHelper.formatRupiah(item.amount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBudget(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Atur Anggaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
