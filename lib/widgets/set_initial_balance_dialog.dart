import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/statistics_provider.dart';
import '../utils/format_helper.dart';

/// Dialog untuk mengatur atau mengisi saldo awal pengguna baru.
///
/// Menyimpan saldo sebagai transaksi pemasukan dengan kategori 'Saldo Awal'
/// sehingga langsung memperbarui total saldo dan ringkasan keuangan.
class SetInitialBalanceDialog extends StatefulWidget {
  final int userId;

  const SetInitialBalanceDialog({super.key, required this.userId});

  static Future<bool?> show(BuildContext context, {required int userId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetInitialBalanceDialog(userId: userId),
    );
  }

  @override
  State<SetInitialBalanceDialog> createState() =>
      _SetInitialBalanceDialogState();
}

class _SetInitialBalanceDialogState extends State<SetInitialBalanceDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(
    text: 'Saldo awal dompet/rekening',
  );
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<double> _quickAmounts = [
    100000,
    500000,
    1000000,
    2500000,
    5000000,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = FormatHelper.formatThousand(amount);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = FormatHelper.parseThousand(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal saldo yang valid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final txProvider = context.read<TransactionProvider>();
      final success = await txProvider.addTransaction(
        userId: widget.userId,
        category: 'Saldo Awal',
        amount: amount,
        type: TransactionType.income,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : 'Saldo awal dompet/rekening',
      );

      if (!mounted) return;

      if (success) {
        // Refresh dashboard & statistik
        await Future.wait([
          txProvider.loadDashboardData(widget.userId),
          context.read<BudgetProvider>().loadCurrentMonthBudgets(widget.userId),
          context.read<StatisticsProvider>().loadStatistics(widget.userId),
        ]);

        if (!mounted) return;
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saldo awal ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount)} berhasil diisi!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(txProvider.errorMessage ?? 'Gagal mengisi saldo.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF00796B),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atur & Isi Saldo Awal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Masukkan saldo awal dompet atau rekeningmu',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Nominal
            const Text(
              'Nominal Saldo (Rp)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00796B),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                ),
                hintText: '0',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal saldo tidak boleh kosong';
                }
                final num = FormatHelper.parseThousand(val);
                if (num <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Shortcut Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickAmounts.map((amt) {
                final formatted = FormatHelper.formatThousand(amt);
                return ActionChip(
                  label: Text(
                    '+Rp $formatted',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _selectQuickAmount(amt),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Catatan
            const Text(
              'Keterangan / Sumber Dana',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Contoh: Tabungan BCA / Uang Saku',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'Simpan Saldo Awal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
