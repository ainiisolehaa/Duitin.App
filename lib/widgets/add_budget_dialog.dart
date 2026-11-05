import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../utils/format_helper.dart';
import '../utils/category_constants.dart';

/// Dialog untuk memasang atau memperbarui batas anggaran per kategori.
class AddBudgetDialog extends StatefulWidget {
  final int userId;
  final String? initialCategory;
  final double? initialAmount;

  const AddBudgetDialog({
    super.key,
    required this.userId,
    this.initialCategory,
    this.initialAmount,
  });

  static Future<void> show(
    BuildContext context, {
    required int userId,
    String? initialCategory,
    double? initialAmount,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddBudgetDialog(
        userId: userId,
        initialCategory: initialCategory,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _selectedCategory;

  // Anggaran hanya untuk kategori pengeluaran
  final List<String> _categories = CategoryConstants.expenseCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? _categories.first;
    _amountController = TextEditingController(
      text: widget.initialAmount != null
          ? FormatHelper.formatThousand(widget.initialAmount!)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = FormatHelper.parseThousand(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal anggaran harus lebih dari 0')),
      );
      return;
    }

    final now = DateTime.now();
    final provider = context.read<BudgetProvider>();

    final success = await provider.setBudget(
      userId: widget.userId,
      category: _selectedCategory,
      amount: amount,
      month: now.month,
      year: now.year,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Anggaran gagal disimpan. Coba lagi.',
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

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Anggaran "$_selectedCategory" sebesar ${FormatHelper.formatRupiah(amount)} disimpan!',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.savings_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Atur Anggaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulan: ${FormatHelper.formatMonthYear(now.month, now.year)}',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(
                        FormatHelper.getCategoryIcon(cat),
                        size: 18,
                        color: FormatHelper.getCategoryColor(cat),
                      ),
                      const SizedBox(width: 10),
                      Text(cat),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Nominal Batas Anggaran
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Batas Anggaran (Rp)',
                prefixText: 'Rp ',
                hintText: '500.000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal tidak boleh kosong';
                }
                final numVal = FormatHelper.parseThousand(val);
                if (numVal <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _saveBudget, child: const Text('Simpan')),
      ],
    );
  }
}
