import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/format_helper.dart';
import 'transaction_form_screen.dart';

/// Halaman Detail Transaksi.
///
/// Menampilkan informasi lengkap transaksi (nominal, kategori, jenis,
/// tanggal, waktu, catatan, dan metadata waktu).
/// Menyediakan opsi Edit dan Hapus transaksi dengan konfirmasi.
class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  final int userId;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.userId,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Transaction _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          userId: widget.userId,
          transaction: _transaction,
        ),
      ),
    );

    if (result == true && mounted) {
      // Ambil transaksi yang sudah diperbarui dari provider
      final txProvider = context.read<TransactionProvider>();
      final updated = txProvider.transactions.firstWhere(
        (t) => t.id == _transaction.id,
        orElse: () => _transaction,
      );
      setState(() {
        _transaction = updated;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus transaksi "${_transaction.category}" sebesar ${FormatHelper.formatRupiah(_transaction.amount)}?',
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

    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    await txProvider.deleteTransaction(_transaction.id!, widget.userId);
    await budgetProvider.loadCurrentMonthBudgets(widget.userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi "${_transaction.category}" berhasil dihapus'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = _transaction.isIncome;
    final categoryColor = FormatHelper.getCategoryColor(_transaction.category);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Transaksi',
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red,
            tooltip: 'Hapus Transaksi',
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Kartu Utama (Hero Amount & Category) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  // Icon Kategori
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FormatHelper.getCategoryIcon(_transaction.category),
                      size: 38,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kategori
                  Text(
                    _transaction.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Badge Tipe
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nominal Besar
                  Text(
                    '${isIncome ? '+' : '-'} ${FormatHelper.formatRupiah(_transaction.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Rincian Informasi Transaksi ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tanggal
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal',
                    value: FormatHelper.formatFullDate(_transaction.date),
                  ),
                  const Divider(height: 24),

                  // Waktu
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Waktu',
                    value: FormatHelper.formatTime(_transaction.date),
                  ),
                  const Divider(height: 24),

                  // Keterangan / Catatan
                  _buildDetailRow(
                    context,
                    icon: Icons.notes_rounded,
                    label: 'Keterangan',
                    value: _transaction.note?.isNotEmpty == true
                        ? _transaction.note!
                        : 'Tidak ada keterangan',
                    valueColor: _transaction.note?.isNotEmpty == true
                        ? null
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const Divider(height: 24),

                  // Metadata Dibuat
                  _buildDetailRow(
                    context,
                    icon: Icons.history_rounded,
                    label: 'Dicatat pada',
                    value: FormatHelper.formatDateTime(_transaction.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Tombol Edit & Hapus Bawah ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _handleEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Transaksi'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

