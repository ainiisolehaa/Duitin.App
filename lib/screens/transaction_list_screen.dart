import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/format_helper.dart';
import '../utils/category_constants.dart';
import '../widgets/category_chip_item.dart';
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

/// Enum preset periode tanggal untuk filter cepat.
enum DateFilterPreset {
  all('Semua'),
  today('Hari Ini'),
  thisWeek('Minggu Ini'),
  thisMonth('Bulan Ini'),
  custom('Kustom...');

  final String label;
  const DateFilterPreset(this.label);
}

/// Halaman Riwayat Transaksi Lengkap.
///
/// Menyediakan fitur:
/// 1. Pencarian teks (kategori atau catatan)
/// 2. Filter jenis transaksi (Semua, Pengeluaran, Pemasukan)
/// 3. Filter kategori transaksi
/// 4. Filter periode tanggal (Semua, Hari Ini, Minggu Ini, Bulan Ini, Rentang Kustom)
///
/// Semua filter dieksekusi bersamaan langsung pada SQLite melalui TransactionRepository.
class TransactionListScreen extends StatefulWidget {
  final int userId;

  const TransactionListScreen({super.key, required this.userId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();

  /// Perangkat input yang diizinkan menggeser baris filter secara horizontal.
  static const Set<PointerDeviceKind> _dragDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  // State filter yang aktif
  TransactionType? _selectedType;
  String _selectedCategory = 'Semua';
  DateFilterPreset _selectedDatePreset = DateFilterPreset.all;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter();
      context.read<TransactionProvider>().loadUserCategories(widget.userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  /// Eksekusi filter langsung ke database SQLite melalui provider.
  void _applyFilter() {
    final query = _searchController.text.trim();
    context.read<TransactionProvider>().filterTransactions(
      userId: widget.userId,
      searchQuery: query.isEmpty ? null : query,
      type: _selectedType,
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  /// Reset semua filter ke kondisi awal.
  void _resetFilter() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedCategory = 'Semua';
      _selectedDatePreset = DateFilterPreset.all;
      _startDate = null;
      _endDate = null;
    });
    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _applyFilter();
  }

  /// Ubah preset tanggal dan hitung rentang tanggalnya.
  Future<void> _onDatePresetChanged(DateFilterPreset preset) async {
    final now = DateTime.now();

    if (preset == DateFilterPreset.custom) {
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : DateTimeRange(
                start: now.subtract(const Duration(days: 7)),
                end: now,
              ),
      );

      if (pickedRange != null) {
        setState(() {
          _selectedDatePreset = DateFilterPreset.custom;
          _startDate = pickedRange.start;
          _endDate = pickedRange.end;
        });
        _applyFilter();
      }
      return;
    }

    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case DateFilterPreset.all:
          _startDate = null;
          _endDate = null;
          break;
        case DateFilterPreset.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case DateFilterPreset.thisWeek:
          // Awal minggu (Senin)
          final weekday = now.weekday;
          _startDate = DateTime(now.year, now.month, now.day - (weekday - 1));
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case DateFilterPreset.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case DateFilterPreset.custom:
          break;
      }
    });

    _applyFilter();
  }

  Future<void> _openDetail(Transaction tx) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TransactionDetailScreen(transaction: tx, userId: widget.userId),
      ),
    );

    if (result == true && mounted) {
      _applyFilter();
    }
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(userId: widget.userId),
      ),
    );

    if (result == true && mounted) {
      _applyFilter();
    }
  }

  bool get _hasActiveFilter {
    return _searchController.text.trim().isNotEmpty ||
        _selectedType != null ||
        _selectedCategory != 'Semua' ||
        _selectedDatePreset != DateFilterPreset.all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, child) {
          final transactions = txProvider.filteredTransactions;

          // Gabungkan kategori bawaan dan kategori pengguna dari database.
          // Gunakan List agar akses per-index saat membangun chip tetap O(1).
          final List<String> allCategories = <String>{
            'Semua',
            ...CategoryConstants.allCategories,
            ...txProvider.userCategories,
            // Pastikan kategori yang sedang dipilih selalu tersedia.
            _selectedCategory,
          }.toList();

          // Hitung total dari hasil filter
          double filteredIncome = 0;
          double filteredExpense = 0;
          for (final t in transactions) {
            if (t.isIncome) {
              filteredIncome += t.amount;
            } else {
              filteredExpense += t.amount;
            }
          }
          final double filteredNet = filteredIncome - filteredExpense;

          return Column(
            children: [
              // ── Panel Pencarian & Filter Modern ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Kolom Pencarian Teks & Tombol Reset
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari catatan atau transaksi...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _applyFilter();
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                            ),
                            onChanged: (_) => _applyFilter(),
                          ),
                        ),
                        if (_hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _resetFilter,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Kategori Transaksi — Horizontal Scrolling Chips yang Nyaman
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Kategori:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _selectedCategory,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tombol navigasi cepat geser kiri
                        InkWell(
                          onTap: () {
                            if (_categoryScrollController.hasClients) {
                              _categoryScrollController.animateTo(
                                (_categoryScrollController.offset - 160).clamp(
                                  0.0,
                                  _categoryScrollController
                                      .position
                                      .maxScrollExtent,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Tombol navigasi cepat geser kanan
                        InkWell(
                          onTap: () {
                            if (_categoryScrollController.hasClients) {
                              _categoryScrollController.animateTo(
                                (_categoryScrollController.offset + 160).clamp(
                                  0.0,
                                  _categoryScrollController
                                      .position
                                      .maxScrollExtent,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Daftar chip kategori dengan SingleChildScrollView yang mendukung
                    // gesture drag dari touch, mouse, trackpad, maupun tombol panah.
                    ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: _dragDevices,
                      ),
                      child: SingleChildScrollView(
                        controller: _categoryScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Row(
                          children: allCategories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryChipItem(
                                category: cat,
                                isSelected: _selectedCategory == cat,
                                isAll: cat == 'Semua',
                                onTap: () {
                                  setState(() => _selectedCategory = cat);
                                  _applyFilter();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Filter Jenis Transaksi & Periode Waktu
                    ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: _dragDevices,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Row(
                          children: [
                            // Tipe: Semua
                            FilterChip(
                              label: const Text('Semua Tipe'),
                              selected: _selectedType == null,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedType = null);
                                _applyFilter();
                              },
                            ),
                            const SizedBox(width: 6),

                            // Tipe: Pengeluaran
                            FilterChip(
                              label: const Text('Pengeluaran'),
                              avatar: Icon(
                                Icons.arrow_upward_rounded,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              selected:
                                  _selectedType == TransactionType.expense,
                              selectedColor: Colors.red.withValues(alpha: 0.15),
                              checkmarkColor: Colors.red.shade700,
                              onSelected: (_) {
                                setState(
                                  () => _selectedType = TransactionType.expense,
                                );
                                _applyFilter();
                              },
                            ),
                            const SizedBox(width: 6),

                            // Tipe: Pemasukan
                            FilterChip(
                              label: const Text('Pemasukan'),
                              avatar: Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              selected: _selectedType == TransactionType.income,
                              selectedColor: Colors.green.withValues(
                                alpha: 0.15,
                              ),
                              checkmarkColor: Colors.green.shade700,
                              onSelected: (_) {
                                setState(
                                  () => _selectedType = TransactionType.income,
                                );
                                _applyFilter();
                              },
                            ),
                            const SizedBox(width: 10),

                            // Pembatas vertikal
                            Container(
                              height: 22,
                              width: 1,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 10),

                            // Periode Waktu Chips
                            ...DateFilterPreset.values.map((preset) {
                              final isSelected = _selectedDatePreset == preset;
                              final label =
                                  preset == DateFilterPreset.custom &&
                                      _startDate != null &&
                                      _endDate != null
                                  ? '${FormatHelper.formatDate(_startDate!)} - ${FormatHelper.formatDate(_endDate!)}'
                                  : preset.label;

                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  onSelected: (_) =>
                                      _onDatePresetChanged(preset),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Ringkasan Hasil Filter ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${transactions.length} Transaksi',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Net: ${FormatHelper.formatRupiah(filteredNet)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: filteredNet >= 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        Text(
                          '+${FormatHelper.formatRupiah(filteredIncome)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '-${FormatHelper.formatRupiah(filteredExpense)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Daftar Transaksi atau State Kosong ──
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _applyFilter();
                    await txProvider.loadUserCategories(widget.userId);
                  },
                  child: txProvider.isFilterLoading
                      ? const Center(child: CircularProgressIndicator())
                      : transactions.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(28),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 54,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.35),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Tidak ada transaksi yang cocok',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _hasActiveFilter
                                                ? 'Coba sesuaikan kata kunci pencarian, jenis transaksi, kategori, atau rentang tanggal.'
                                                : 'Belum ada transaksi yang tercatat.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          if (_hasActiveFilter) ...[
                                            const SizedBox(height: 16),
                                            FilledButton.tonalIcon(
                                              onPressed: _resetFilter,
                                              icon: const Icon(
                                                Icons.restart_alt_rounded,
                                                size: 18,
                                              ),
                                              label: const Text('Reset Filter'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: transactions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isIncome = tx.isIncome;
                            final categoryColor = FormatHelper.getCategoryColor(
                              tx.category,
                            );

                            return InkWell(
                              onTap: () => _openDetail(tx),
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
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Icon Kategori
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        FormatHelper.getCategoryIcon(
                                          tx.category,
                                        ),
                                        size: 22,
                                        color: categoryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Kategori & Catatan/Tanggal
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tx.note?.isNotEmpty == true
                                                ? '${tx.note} • ${FormatHelper.formatDate(tx.date)}'
                                                : FormatHelper.formatDate(
                                                    tx.date,
                                                  ),
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

                                    // Nominal
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                          isIncome
                                              ? 'Pemasukan'
                                              : 'Pengeluaran',
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
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        tooltip: 'Catat Transaksi',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
