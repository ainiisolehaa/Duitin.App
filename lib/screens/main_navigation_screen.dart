import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'transaction_list_screen.dart';
import 'statistics_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';

/// Layar Utama dengan Bottom Navigation Bar (Navbar) Material 3.
///
/// Menyediakan navigasi instan ke 5 fitur utama:
/// 1. Beranda (Dashboard Keuangan)
/// 2. Transaksi (Daftar Riwayat & Multi-Filter)
/// 3. Statistik (Grafik Keuangan FL Chart)
/// 4. Anggaran (Target Bulanan & Peringatan Batas)
/// 5. Profil (Preferensi Tema & Informasi Akun)
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    if (index >= 0 && index < 5 && _currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId ?? 0;

    // Mempertahankan state masing-masing tab menggunakan IndexedStack
    final screens = [
      const HomeScreen(),
      TransactionListScreen(userId: userId),
      StatisticsScreen(userId: userId),
      BudgetScreen(userId: userId),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
    );
  }
}

