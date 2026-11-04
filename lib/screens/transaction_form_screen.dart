import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/format_helper.dart';

/// Halaman Form Tambah dan Edit Transaksi.
///
/// Mendukung mode tambah (`transaction == null`) dan edit (`transaction != null`).
/// Memvalidasi nominal (> 0), kategori, tanggal, dan keterangan transaksi.
class TransactionFormScreen extends StatefulWidget {
  final int userId;
  final Transaction? transaction;

  const TransactionFormScreen({
    super.key,
    required this.userId,
    this.transaction,
  });

  bool get isEditing => transaction != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;

  late TransactionType _type;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedPresetCategory;
  bool _isCustomCategory = false;

  final List<String> _expenseCategories = [
    'Makanan',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Pendidikan',
    'Kesehatan',
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
  void initState() {
    super.initState();
    final tx = widget.transaction;

    if (tx != null) {
      // Mode Edit
      _type = tx.type;
      _amountController = TextEditingController(
        text: tx.amount.toStringAsFixed(0),
      );
      _noteController = TextEditingController(text: tx.note ?? '');
      _selectedDate = tx.date;
      _selectedTime = TimeOfDay.fromDateTime(tx.date);

      final categories = _type == TransactionType.expense
          ? _expenseCategories
          : _incomeCategories;

      if (categories.contains(tx.category)) {
        _selectedPresetCategory = tx.category;
        _isCustomCategory = false;
        _categoryController = TextEditingController(text: tx.category);
      } else {
        _selectedPresetCategory = 'Lainnya';
        _isCustomCategory = true;
        _categoryController = TextEditingController(text: tx.category);
      }
    } else {
      // Mode Tambah
      _type = TransactionType.expense;
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedPresetCategory = _expenseCategories.first;
      _isCustomCategory = false;
      _categoryController = TextEditingController(text: _selectedPresetCategory);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      final defaultList = type == TransactionType.expense
          ? _expenseCategories
          : _incomeCategories;
      _selectedPresetCategory = defaultList.first;
      _isCustomCategory = false;
      _categoryController.text = _selectedPresetCategory!;
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transaksi harus lebih dari 0')),
      );
      return;
    }

    final category = _categoryController.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori tidak boleh kosong')),
      );
      return;
    }

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (widget.isEditing) {
      final updatedTx = widget.transaction!.copyWith(
        category: category,
        amount: amount,
        type: _type,
        date: _selectedDate,
        note: note,
        updatedAt: DateTime.now(),
      );
      await txProvider.updateTransaction(updatedTx);
    } else {
      await txProvider.addTransaction(
        userId: widget.userId,
        category: category,
        amount: amount,
        type: _type,
        date: _selectedDate,
        note: note,
      );
    }

    // Perbarui juga data anggaran agar perhitungan langsung sinkron
    await budgetProvider.loadCurrentMonthBudgets(widget.userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Transaksi "$category" berhasil diperbarui!'
                : '${_type == TransactionType.income ? "Pemasukan" : "Pengeluaran"} berhasil dicatat!',
          ),
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
    final categories = _type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Pemilihan Jenis Transaksi ──
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
                const SizedBox(height: 24),

                // ── 2. Nominal Transaksi ──
                Text(
                  'Nominal Transaksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: !widget.isEditing,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _type == TransactionType.expense
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    helperText: 'Masukkan jumlah uang tanpa titik atau koma',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nominal wajib diisi';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Nominal harus lebih besar dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── 3. Kategori Transaksi ──
                Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = _selectedPresetCategory == cat && !_isCustomCategory;
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
                          _selectedPresetCategory = cat;
                          if (cat == 'Lainnya') {
                            _isCustomCategory = true;
                            _categoryController.text = '';
                          } else {
                            _isCustomCategory = false;
                            _categoryController.text = cat;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // Field Input Kategori Manual jika memilih 'Lainnya' atau kustom
                if (_isCustomCategory) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori Kustom',
                      hintText: 'Contoh: Langganan Spotify, Servis Motor',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama kategori kustom tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // ── 4. Tanggal & Jam ──
                Text(
                  'Waktu Transaksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(FormatHelper.formatDate(_selectedDate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(_selectedTime.format(context)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 5. Keterangan / Catatan ──
                Text(
                  'Keterangan / Catatan (Opsional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLength: 150,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan tambahan (contoh: Makan siang di warteg)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Tombol Simpan ──
                Consumer<TransactionProvider>(
                  builder: (context, txProv, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: txProv.isLoading ? null : _saveTransaction,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: txProv.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.isEditing ? 'Simpan Perubahan' : 'Catat Transaksi',
                                style: const TextStyle(
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
      ),
    );
  }
}

