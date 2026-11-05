import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/user_avatar.dart';
import '../widgets/set_initial_balance_dialog.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

/// Dashboard Keuangan Utama (Home Screen).
///
/// Menampilkan:
/// 1. Total Saldo, Pemasukan, dan Pengeluaran (BalanceCard)
/// 2. Ringkasan Anggaran Bulanan vs Pengeluaran Riil (BudgetSummaryCard)
/// 3. Daftar Transaksi Terbaru (RecentTransactionsList)
///
/// Semua data terhubung langsung ke SQLite dan dihitung dinamis
/// untuk user yang sedang login. Perubahan data langsung memperbarui tampilan.
class HomeScreen extends StatefulWidget {
  /// Callback untuk berpindah tab lewat bottom navigation.
  final void Function(int index)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId != null) {
      await Future.wait([
        context.read<TransactionProvider>().loadDashboardData(userId),
        context.read<BudgetProvider>().loadCurrentMonthBudgets(userId),
        context.read<StatisticsProvider>().loadStatistics(userId),
      ]);
    }
  }

  Future<void> _openAddTransaction(int userId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(userId: userId)),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openTransactionDetail(Transaction tx, int userId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TransactionDetailScreen(transaction: tx, userId: userId),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  void _openAddBudget(int userId) {
    AddBudgetDialog.show(context, userId: userId);
  }

  Future<void> _handleDeleteTransaction(Transaction tx, int userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final success = await txProvider.deleteTransaction(tx.id!, userId);
    if (!success) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            txProvider.errorMessage ?? 'Transaksi gagal dihapus. Coba lagi.',
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

    await budgetProvider.loadCurrentMonthBudgets(userId);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Transaksi "${tx.category}" berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final userId = auth.userId ?? 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer2<TransactionProvider, BudgetProvider>(
        builder: (context, txProvider, budgetProvider, child) {
          final isNewUser =
              txProvider.transactions.isEmpty && txProvider.balance == 0;

          return RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Sapaan Pengguna (Halo, [Nama]!) ──
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Halo, ${user?.name ?? 'Pengguna'}! 👋',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Kelola & pantau keuanganmu hari ini',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => widget.onNavigateTab?.call(4),
                          child: Tooltip(
                            message: 'Buka Profil & Pengaturan',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: UserAvatar(user: user, radius: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Banner Selamat Datang & Isi Saldo untuk Pengguna Baru ──
                  if (isNewUser)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.65,
                            ),
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Baru pertama kali di Duitin?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Atur saldo awal dompetmu agar pencatatan keuangan akurat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => SetInitialBalanceDialog.show(
                              context,
                              userId: userId,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Isi Saldo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── 1. Kartu Total Saldo, Pemasukan, & Pengeluaran ──
                  BalanceCard(
                    balance: txProvider.balance,
                    totalIncome: txProvider.totalIncome,
                    totalExpense: txProvider.totalExpense,
                    onTopUp: () =>
                        SetInitialBalanceDialog.show(context, userId: userId),
                  ),
                  const SizedBox(height: 22),

                  // ── 2. Ringkasan Anggaran Bulanan ──
                  BudgetSummaryCard(
                    budgets: budgetProvider.budgets,
                    totalBudget: budgetProvider.totalBudget,
                    expenseSummary: txProvider.expenseSummary,
                    onAddBudget: () => _openAddBudget(userId),
                    onViewDetails: () => widget.onNavigateTab?.call(3),
                  ),
                  const SizedBox(height: 22),

                  // ── 3. Transaksi Terbaru ──
                  RecentTransactionsList(
                    transactions: txProvider.recentTransactions,
                    onDelete: (tx) => _handleDeleteTransaction(tx, userId),
                    onDetailTap: (tx) => _openTransactionDetail(tx, userId),
                    onAddTransaction: () => _openAddTransaction(userId),
                    onViewAll: () => widget.onNavigateTab?.call(1),
                  ),
                  const SizedBox(
                    height: 90,
                  ), // Ruang ekstra untuk floating button
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(userId),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Catat Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
