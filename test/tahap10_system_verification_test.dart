import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:duitin/models/user.dart';
import 'package:duitin/models/transaction.dart';
import 'package:duitin/models/budget.dart';
import 'package:duitin/models/budget_detail.dart';
import 'package:duitin/models/statistic_data.dart';

import 'package:duitin/providers/auth_provider.dart';
import 'package:duitin/providers/theme_provider.dart';
import 'package:duitin/providers/transaction_provider.dart';
import 'package:duitin/providers/budget_provider.dart';
import 'package:duitin/providers/statistics_provider.dart';

import 'package:duitin/repositories/auth_repository.dart';
import 'package:duitin/repositories/transaction_repository.dart';
import 'package:duitin/repositories/budget_repository.dart';

import 'package:duitin/screens/splash_screen.dart';
import 'package:duitin/screens/login_screen.dart';
import 'package:duitin/screens/register_screen.dart';
import 'package:duitin/screens/home_screen.dart';
import 'package:duitin/screens/transaction_form_screen.dart';
import 'package:duitin/screens/transaction_detail_screen.dart';
import 'package:duitin/screens/transaction_list_screen.dart';
import 'package:duitin/screens/statistics_screen.dart';
import 'package:duitin/screens/budget_screen.dart';
import 'package:duitin/screens/profile_screen.dart';

// ── Mock Repositories untuk Verifikasi Sistem ──

class MockAuthRepo extends AuthRepository {
  final Map<int, User> users = {};
  int _counter = 1;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normEmail = email.toLowerCase().trim();
    for (final u in users.values) {
      if (u.email == normEmail) {
        return AuthResult(
          success: false,
          errorMessage: 'Email sudah terdaftar. Silakan gunakan email lain.',
        );
      }
    }
    final user = User(
      id: _counter++,
      name: name.trim(),
      email: normEmail,
      password: 'hashed_$password',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    users[user.id!] = user;
    return AuthResult(success: true, user: user);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normEmail = email.toLowerCase().trim();
    for (final u in users.values) {
      if (u.email == normEmail) {
        if (u.password == 'hashed_$password') {
          return AuthResult(success: true, user: u);
        }
        return AuthResult(success: false, errorMessage: 'Password salah.');
      }
    }
    return AuthResult(
      success: false,
      errorMessage: 'Email belum terdaftar. Silakan daftar terlebih dahulu.',
    );
  }

  @override
  Future<User?> getUserById(int id) async => users[id];

  @override
  Future<bool> updateUser(User user) async {
    if (user.id != null && users.containsKey(user.id)) {
      users[user.id!] = user;
      return true;
    }
    return false;
  }
}

class MockTxRepo extends TransactionRepository {
  final List<Transaction> transactions = [];
  int _counter = 1;

  @override
  Future<int> insertTransaction(Transaction tx) async {
    final id = _counter++;
    final created = tx.copyWith(id: id);
    transactions.add(created);
    return id;
  }

  @override
  Future<List<Transaction>> getTransactionsByUserId(int userId) async {
    return transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<double> getTotalByType({
    required int userId,
    required TransactionType type,
  }) async {
    return transactions
        .where((t) => t.userId == userId && t.type == type)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<Map<String, double>> getExpenseSummaryByCategory({
    required int userId,
    required int month,
    required int year,
  }) async {
    final Map<String, double> map = {};
    for (final t in transactions) {
      if (t.userId == userId &&
          t.type == TransactionType.expense &&
          t.date.month == month &&
          t.date.year == year) {
        map[t.category] = (map[t.category] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  @override
  Future<List<String>> getDistinctCategories(int userId) async {
    return transactions
        .where((t) => t.userId == userId)
        .map((t) => t.category)
        .toSet()
        .toList();
  }

  @override
  Future<int> updateTransaction(Transaction tx) async {
    final index = transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      transactions[index] = tx;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    transactions.removeWhere((t) => t.id == id);
    return 1;
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return transactions.where((t) {
      if (t.userId != userId) return false;
      return !t.date.isBefore(startDate) && !t.date.isAfter(endDate);
    }).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsFiltered({
    required int userId,
    String? searchQuery,
    TransactionType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return transactions.where((t) {
      if (t.userId != userId) return false;

      // 1. Filter Pencarian Teks
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchCategory = t.category.toLowerCase().contains(q);
        final matchNote = t.note?.toLowerCase().contains(q) ?? false;
        if (!matchCategory && !matchNote) return false;
      }

      // 2. Filter Jenis Transaksi
      if (type != null && t.type != type) return false;

      // 3. Filter Kategori
      if (category != null && category.trim().isNotEmpty && category != 'Semua') {
        if (t.category.toLowerCase() != category.toLowerCase().trim()) return false;
      }

      // 4. Filter Rentang Tanggal
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

class MockBudgetRepo extends BudgetRepository {
  final List<Budget> budgets = [];
  int _counter = 1;

  @override
  Future<int> insertBudget(Budget budget) async {
    final id = _counter++;
    final item = budget.copyWith(id: id);
    budgets.add(item);
    return id;
  }

  @override
  Future<List<Budget>> getBudgetsByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return budgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .toList();
  }

  @override
  Future<double> getTotalBudgetByMonth({
    required int userId,
    required int month,
    required int year,
  }) async {
    return budgets
        .where((b) => b.userId == userId && b.month == month && b.year == year)
        .fold<double>(0.0, (sum, b) => sum + b.amount);
  }

  @override
  Future<int> updateBudget(Budget budget) async {
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      budgets[index] = budget;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteBudget(int id) async {
    budgets.removeWhere((b) => b.id == id);
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Tahap 10: Pengujian & Pemeriksaan Menyeluruh Aplikasi Duitin', () {
    late MockAuthRepo authRepo;
    late MockTxRepo txRepo;
    late MockBudgetRepo budgetRepo;

    late AuthProvider authProvider;
    late ThemeProvider themeProvider;
    late TransactionProvider txProvider;
    late BudgetProvider budgetProvider;
    late StatisticsProvider statProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepo = MockAuthRepo();
      txRepo = MockTxRepo();
      budgetRepo = MockBudgetRepo();

      authProvider = AuthProvider(repository: authRepo);
      themeProvider = ThemeProvider();
      txProvider = TransactionProvider(repository: txRepo);
      budgetProvider = BudgetProvider(
        repository: budgetRepo,
        txRepository: txRepo,
      );
      statProvider = StatisticsProvider(repository: txRepo);
    });

    Widget buildApp({required Widget home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<TransactionProvider>.value(value: txProvider),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
          ChangeNotifierProvider<StatisticsProvider>.value(value: statProvider),
        ],
        child: MaterialApp(
          home: home,
        ),
      );
    }

    // ── 1. Navigasi Minimal 5 Halaman (10 Halaman Lengkap) ──
    testWidgets('1. Navigasi aplikasi ke seluruh 10 halaman tanpa error', (tester) async {
      await authProvider.register(
        name: 'Siti Aminah',
        email: 'siti@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      final userId = authProvider.userId!;

      final sampleTx = Transaction(
        id: 1,
        userId: userId,
        category: 'Makanan',
        amount: 25000,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      final screens = <Widget>[
        const LoginScreen(),
        const RegisterScreen(),
        const HomeScreen(),
        TransactionFormScreen(userId: userId),
        TransactionDetailScreen(transaction: sampleTx, userId: userId),
        TransactionListScreen(userId: userId),
        StatisticsScreen(userId: userId),
        BudgetScreen(userId: userId),
        const ProfileScreen(),
        const SplashScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(Container());
        await tester.pumpWidget(buildApp(home: screen));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(screen.runtimeType), findsOneWidget);
        if (screen is SplashScreen) {
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
        }
      }
    });

    // ── 2. Login dan Register ──
    test('2. Pemeriksaan Register, Login, Validasi, dan Sesi', () async {
      // Register
      final regSuccess = await authProvider.register(
        name: 'Rian Hidayat',
        email: 'rian@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(regSuccess, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, equals('Rian Hidayat'));

      // Register duplikat email harus ditolak
      final dupSuccess = await authProvider.register(
        name: 'Rian Palsu',
        email: 'rian@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(dupSuccess, isFalse);
      expect(authProvider.errorMessage, contains('sudah terdaftar'));

      // Logout
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);

      // Login password salah
      final wrongPass = await authProvider.login(
        email: 'rian@example.com',
        password: 'wrongpassword',
      );
      expect(wrongPass, isFalse);
      expect(authProvider.errorMessage, contains('Password salah'));

      // Login akun belum terdaftar
      final noAccount = await authProvider.login(
        email: 'ghost@example.com',
        password: 'password123',
      );
      expect(noAccount, isFalse);
      expect(authProvider.errorMessage, contains('belum terdaftar'));

      // Login berhasil
      final loginSuccess = await authProvider.login(
        email: 'rian@example.com',
        password: 'password123',
      );
      expect(loginSuccess, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
    });

    // ── 3 & 4. CRUD Transaksi & Perhitungan Saldo ──
    test('3 & 4. Pemeriksaan CRUD Transaksi dan Kalkulasi Saldo Dinamis', () async {
      const userId = 101;
      await txProvider.loadDashboardData(userId);
      expect(txProvider.balance, equals(0.0));

      // CREATE: Tambah Pemasukan Rp 5.000.000
      await txProvider.addTransaction(
        userId: userId,
        category: 'Gaji',
        amount: 5000000,
        type: TransactionType.income,
        date: DateTime.now(),
      );
      expect(txProvider.totalIncome, equals(5000000));
      expect(txProvider.totalExpense, equals(0));
      expect(txProvider.balance, equals(5000000));

      // CREATE: Tambah Pengeluaran Rp 1.500.000
      await txProvider.addTransaction(
        userId: userId,
        category: 'Belanja',
        amount: 1500000,
        type: TransactionType.expense,
        date: DateTime.now(),
      );
      expect(txProvider.totalIncome, equals(5000000));
      expect(txProvider.totalExpense, equals(1500000));
      expect(txProvider.balance, equals(3500000));

      // READ: Transaksi tersimpan
      expect(txProvider.transactions.length, equals(2));
      final expenseTx = txProvider.transactions.firstWhere((t) => t.category == 'Belanja');

      // UPDATE: Edit nominal pengeluaran dari 1.500.000 menjadi 2.000.000
      final updatedTx = expenseTx.copyWith(amount: 2000000);
      await txProvider.updateTransaction(updatedTx);
      expect(txProvider.totalExpense, equals(2000000));
      expect(txProvider.balance, equals(3000000));

      // DELETE: Hapus pengeluaran
      await txProvider.deleteTransaction(expenseTx.id!, userId);
      expect(txProvider.totalExpense, equals(0));
      expect(txProvider.balance, equals(5000000));
      expect(txProvider.transactions.length, equals(1));
    });

    // ── 5. Riwayat dan Filter Transaksi ──
    test('5. Pemeriksaan Riwayat, Pencarian & Multi-Filter Bersamaan', () async {
      const userId = 202;
      final now = DateTime.now();

      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Makanan',
        amount: 50000,
        type: TransactionType.expense,
        date: now,
        note: 'Makan siang bakso',
      ));
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Transportasi',
        amount: 20000,
        type: TransactionType.expense,
        date: now,
        note: 'Bensin motor',
      ));
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Gaji',
        amount: 3000000,
        type: TransactionType.income,
        date: now,
        note: 'Gaji bulanan',
      ));

      await txProvider.loadDashboardData(userId);

      // Filter Pencarian Teks
      await txProvider.filterTransactions(userId: userId, searchQuery: 'bakso');
      expect(txProvider.filteredTransactions.length, equals(1));
      expect(txProvider.filteredTransactions.first.category, equals('Makanan'));

      // Filter Jenis Transaksi
      await txProvider.filterTransactions(userId: userId, type: TransactionType.income);
      expect(txProvider.filteredTransactions.length, equals(1));
      expect(txProvider.filteredTransactions.first.category, equals('Gaji'));

      // Filter Kategori
      await txProvider.filterTransactions(userId: userId, category: 'Transportasi');
      expect(txProvider.filteredTransactions.length, equals(1));
      expect(txProvider.filteredTransactions.first.category, equals('Transportasi'));

      // Multi-Filter Bersamaan
      await txProvider.filterTransactions(
        userId: userId,
        searchQuery: 'Bensin',
        type: TransactionType.expense,
        category: 'Transportasi',
      );
      expect(txProvider.filteredTransactions.length, equals(1));
    });

    // ── 6. Statistik Keuangan ──
    test('6. Pemeriksaan Statistik Mingguan dan Bulanan FL Chart', () async {
      const userId = 303;
      final now = DateTime.now();

      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Bonus',
        amount: 1000000,
        type: TransactionType.income,
        date: now,
      ));
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Makanan',
        amount: 200000,
        type: TransactionType.expense,
        date: now,
      ));

      await statProvider.loadStatistics(userId);

      expect(statProvider.totalIncome, equals(1000000));
      expect(statProvider.totalExpense, equals(200000));
      expect(statProvider.netSavings, equals(800000));
      expect(statProvider.categoryStats.any((c) => c.category == 'Makanan'), isTrue);

      // Ganti periode ke Bulanan
      await statProvider.setPeriod(StatPeriod.monthly, userId);
      expect(statProvider.period, equals(StatPeriod.monthly));
      expect(statProvider.totalExpense, equals(200000));
    });

    // ── 7. Anggaran Bulanan & Peringatan Batas ──
    test('7. Pemeriksaan Anggaran Bulanan, Sisa, Persentase & Status Peringatan', () async {
      const userId = 404;
      final now = DateTime.now();

      // Pasang anggaran bulanan Rp 1.000.000
      await budgetRepo.insertBudget(Budget(
        userId: userId,
        category: 'Makanan',
        amount: 1000000,
        month: now.month,
        year: now.year,
      ));

      // Pengeluaran Rp 500.000 (50% -> AMAN)
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Makanan',
        amount: 500000,
        type: TransactionType.expense,
        date: now,
      ));

      await budgetProvider.loadCurrentMonthBudgets(userId);
      expect(budgetProvider.totalBudget, equals(1000000));
      expect(budgetProvider.totalActualExpense, equals(500000));
      expect(budgetProvider.remainingBudget, equals(500000));
      expect(budgetProvider.usagePercentage, closeTo(50.0, 0.1));
      expect(budgetProvider.overallStatus, equals(BudgetStatus.safe));

      // Tambah pengeluaran Rp 350.000 (Total 850.000 -> 85% -> WASPADA/NEAR LIMIT)
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Makanan',
        amount: 350000,
        type: TransactionType.expense,
        date: now,
      ));

      await budgetProvider.loadCurrentMonthBudgets(userId);
      expect(budgetProvider.totalActualExpense, equals(850000));
      expect(budgetProvider.isNearLimit, isTrue);
      expect(budgetProvider.overallStatus, equals(BudgetStatus.warning));

      // Tambah pengeluaran Rp 250.000 (Total 1.100.000 -> 110% -> BAHAYA/OVER BUDGET)
      await txRepo.insertTransaction(Transaction(
        userId: userId,
        category: 'Makanan',
        amount: 250000,
        type: TransactionType.expense,
        date: now,
      ));

      await budgetProvider.loadCurrentMonthBudgets(userId);
      expect(budgetProvider.isOverBudget, isTrue);
      expect(budgetProvider.overallStatus, equals(BudgetStatus.danger));
      expect(budgetProvider.remainingBudget, equals(-100000.0));
    });

    // ── 8. Penyimpanan Lokal ──
    test('8. Pemeriksaan Persistensi Preferensi Tema & Sesi di SharedPreferences', () async {
      // Simpan preferensi tema
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, equals(ThemeMode.dark));

      // Baca dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));

      // Muat ulang provider baru
      final newThemeProvider = ThemeProvider();
      await newThemeProvider.loadThemeMode();
      expect(newThemeProvider.themeMode, equals(ThemeMode.dark));
    });

    // ── 9. Perpindahan Orientasi Layar (Responsivitas) ──
    testWidgets('9. Pemeriksaan Orientasi Layar (Portrait & Landscape tanpa Overflow)', (tester) async {
      await authProvider.register(
        name: 'Dewi Lestari',
        email: 'dewi@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      final userId = authProvider.userId!;

      // 1. Uji Portrait (400 x 800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(home: const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Uji Landscape (800 x 400) pada HomeScreen
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // 3. Uji Landscape pada TransactionFormScreen
      await tester.pumpWidget(buildApp(home: TransactionFormScreen(userId: userId)));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsOneWidget);

      // 4. Uji Landscape pada ProfileScreen
      await tester.pumpWidget(buildApp(home: const ProfileScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    // ── 10. Validasi Input & Error Handling ──
    testWidgets('10. Validasi Formulir Transaksi & Penanganan Error Input', (tester) async {
      await tester.pumpWidget(buildApp(home: const TransactionFormScreen(userId: 1)));
      await tester.pumpAndSettle();

      final simpanButton = find.byType(FilledButton).first;
      await tester.ensureVisible(simpanButton);
      await tester.pumpAndSettle();

      // Submit tanpa nominal -> muncul validasi 'Nominal wajib diisi'
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      expect(find.text('Nominal wajib diisi'), findsOneWidget);

      // Masukkan nominal tidak valid (0) -> muncul 'Nominal harus lebih besar dari 0'
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '0');
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      expect(find.text('Nominal harus lebih besar dari 0'), findsOneWidget);
    });

    // ── 11. Pemisahan Data Antar Pengguna ──
    test('11. Pemisahan Data (Data Isolation) Antara Pengguna A dan Pengguna B', () async {
      const userA = 501;
      const userB = 502;

      // User A memiliki transaksi pemasukan Rp 10.000.000
      await txProvider.addTransaction(
        userId: userA,
        category: 'Gaji',
        amount: 10000000,
        type: TransactionType.income,
        date: DateTime.now(),
      );

      // User B memiliki transaksi pengeluaran Rp 200.000
      await txProvider.addTransaction(
        userId: userB,
        category: 'Makanan',
        amount: 200000,
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      // Load data User A
      await txProvider.loadDashboardData(userA);
      expect(txProvider.totalIncome, equals(10000000));
      expect(txProvider.totalExpense, equals(0));
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.userId, equals(userA));

      // Load data User B -> Tidak boleh ada data User A yang bocor
      await txProvider.loadDashboardData(userB);
      expect(txProvider.totalIncome, equals(0));
      expect(txProvider.totalExpense, equals(200000));
      expect(txProvider.transactions.length, equals(1));
      expect(txProvider.transactions.first.userId, equals(userB));
    });
  });
}
