import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/transaction_provider.dart';
import 'home_screen.dart';
import 'transaction_list_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';

/// Layar utama dengan Bottom Navigation Bar Material 3.
///
/// Semua halaman dihubungkan lewat bottom navigation:
/// 1. Beranda (Dashboard Keuangan)
/// 2. Transaksi (Daftar Riwayat & Multi-Filter)
/// 3. Statistik (Grafik Keuangan FL Chart)
/// 4. Anggaran (Target Bulanan & Peringatan Batas)
/// 5. Profil (Mata Uang, Tema & Informasi Akun)
///
/// Saat berpindah tab, halaman lain menampilkan tombol kembali ke Beranda.
/// Data tiap tab juga disegarkan agar perubahan langsung terlihat.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const List<String> _tabTitles = [
    'Beranda',
    'Riwayat Transaksi',
    'Statistik Keuangan',
    'Anggaran Bulanan',
    'Profil & Pengaturan',
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Pindah tab sekaligus memuat ulang data yang relevan.
  void _goToTab(int index, int userId) {
    if (index < 0 || index >= _tabTitles.length || _currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (userId == 0) return;

    switch (index) {
      case 0:
        context.read<TransactionProvider>().loadDashboardData(userId);
        context.read<BudgetProvider>().loadCurrentMonthBudgets(userId);
        context.read<StatisticsProvider>().loadStatistics(userId);
        break;
      case 1:
        context.read<TransactionProvider>().loadUserCategories(userId);
        break;
      case 2:
        context.read<StatisticsProvider>().loadStatistics(userId);
        break;
      case 3:
        context.read<BudgetProvider>().loadCurrentMonthBudgets(userId);
        break;
      case 4:
        break;
    }
  }

  void _backToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId ?? 0;

    // Mempertahankan state masing-masing tab menggunakan IndexedStack.
    final screens = [
      HomeScreen(onNavigateTab: (index) => _goToTab(index, userId)),
      TransactionListScreen(userId: userId),
      StatisticsScreen(userId: userId),
      BudgetScreen(userId: userId),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _backToHome();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_currentIndex != 0) _buildBackHeader(),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: screens),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => _goToTab(index, userId),
          elevation: 3,
          height: 68,
          indicatorColor: theme.colorScheme.primaryContainer,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
              tooltip: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
              tooltip: 'Riwayat Transaksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistik',
              tooltip: 'Statistik Keuangan',
            ),
            NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'Anggaran',
              tooltip: 'Anggaran Bulanan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
              tooltip: 'Profil & Pengaturan',
            ),
          ],
        ),
      ),
    );
  }

  /// Header ringkas berisi tombol kembali saat berada di tab selain Beranda.
  Widget _buildBackHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _backToHome,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Kembali ke Beranda',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _tabTitles[_currentIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
