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
import 'login_screen.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_list_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';

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
  const HomeScreen({super.key});

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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari Duitin?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  void _openTransactionList(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionListScreen(userId: userId)),
    );
  }

  void _openStatistics(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatisticsScreen(userId: userId)),
    );
  }

  void _openBudgetScreen(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BudgetScreen(userId: userId)),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
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
    final userId = user?.id ?? 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Halo, ${user?.name ?? 'Pengguna'}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.savings_rounded),
            tooltip: 'Anggaran Bulanan',
            onPressed: () => _openBudgetScreen(userId),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistik Keuangan',
            onPressed: () => _openStatistics(userId),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Semua Transaksi',
            onPressed: () => _openTransactionList(userId),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Menu Lainnya',
            onSelected: (value) {
              if (value == 'profile') {
                _openProfile();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Profil & Pengaturan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Keluar Akun', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
                    onViewDetails: () => _openBudgetScreen(userId),
                  ),
                  const SizedBox(height: 22),

                  // ── 3. Transaksi Terbaru ──
                  RecentTransactionsList(
                    transactions: txProvider.recentTransactions,
                    onDelete: (tx) => _handleDeleteTransaction(tx, userId),
                    onDetailTap: (tx) => _openTransactionDetail(tx, userId),
                    onAddTransaction: () => _openAddTransaction(userId),
                    onViewAll: () => _openTransactionList(userId),
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
