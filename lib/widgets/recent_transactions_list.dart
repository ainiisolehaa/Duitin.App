import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/format_helper.dart';

/// Daftar transaksi terbaru untuk dashboard.
class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onDelete;
  final Function(Transaction) onDetailTap;
  final VoidCallback onAddTransaction;
  final VoidCallback onViewAll;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onDetailTap,
    required this.onAddTransaction,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
                      Icons.history_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Transaksi Terbaru',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (transactions.isNotEmpty) ...[
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (transactions.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.25,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Belum ada transaksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat pemasukan atau pengeluaranmu hari ini untuk melihat ringkasan keuangan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: onAddTransaction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah Transaksi'),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isIncome = tx.isIncome;
              final categoryColor = FormatHelper.getCategoryColor(tx.category);

              return Dismissible(
                key: Key('tx_${tx.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Transaksi?'),
                      content: Text(
                        'Transaksi "${tx.category}" sebesar ${FormatHelper.formatRupiah(tx.amount)} akan dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => onDelete(tx),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onDetailTap(tx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon Kategori
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              FormatHelper.getCategoryIcon(tx.category),
                              size: 22,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nama Kategori & Catatan/Tanggal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.category,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx.note?.isNotEmpty == true
                                      ? '${tx.note} • ${FormatHelper.formatDate(tx.date)}'
                                      : FormatHelper.formatDate(tx.date),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Jumlah Nominal
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} ${FormatHelper.formatRupiah(tx.amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isIncome
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isIncome ? 'Pemasukan' : 'Pengeluaran',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isIncome
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
