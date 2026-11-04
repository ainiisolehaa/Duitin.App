import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format_helper.dart';

/// Modal Bottom Sheet untuk menambahkan transaksi pemasukan / pengeluaran.
class AddTransactionBottomSheet extends StatefulWidget {
  final int userId;

  const AddTransactionBottomSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, int userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionBottomSheet(userId: userId),
    );
  }

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _selectedCategory = 'Makanan';
  DateTime _selectedDate = DateTime.now();

  final List<String> _expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Pendidikan',
    'Kesehatan',
    'Tagihan',
    'Lainnya',
  ];

  final List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
    'Hadiah',
    'Penjualan',
    'Lainnya',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategory = type == TransactionType.expense
          ? _expenseCategories.first
          : _incomeCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah nominal harus lebih dari 0')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();
    await provider.addTransaction(
      userId: widget.userId,
      category: _selectedCategory,
      amount: amount,
      type: _type,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == TransactionType.income ? "Pemasukan" : "Pengeluaran"} berhasil dicatat!',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis handle atas
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul Sheet
              const Text(
                'Catat Transaksi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Segmented Button Tipe Transaksi
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) => _onTypeChanged(set.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _type == TransactionType.expense
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  selectedForegroundColor: _type == TransactionType.expense
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 18),

              // Field Nominal
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp)',
                  prefixText: 'Rp ',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pemilihan Kategori
              const Text(
                'Kategori',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  final color = FormatHelper.getCategoryColor(cat);

                  return ChoiceChip(
                    label: Text(cat),
                    avatar: Icon(
                      FormatHelper.getCategoryIcon(cat),
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Tanggal & Catatan Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(FormatHelper.formatDate(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Field Catatan
              TextFormField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Contoh: Makan siang bareng teman',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              Consumer<TransactionProvider>(
                builder: (context, txProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: txProvider.isLoading ? null : _saveTransaction,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: txProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

