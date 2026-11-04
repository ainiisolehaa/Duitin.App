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
    final userId = context.watch<AuthProvider>().userId ?? 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer2<TransactionProvider, BudgetProvider>(
        builder: (context, txProvider, budgetProvider, child) {
          return RefreshIndicator(
            onRefresh: _loadData,
            color: theme.colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Kartu Total Saldo, Pemasukan, & Pengeluaran ──
                  BalanceCard(
                    balance: txProvider.balance,
                    totalIncome: txProvider.totalIncome,
                    totalExpense: txProvider.totalExpense,
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
