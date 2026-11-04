import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:duitin/models/user.dart';
import 'package:duitin/providers/auth_provider.dart';
import 'package:duitin/providers/theme_provider.dart';
import 'package:duitin/repositories/auth_repository.dart';
import 'package:duitin/screens/profile_screen.dart';
import 'package:duitin/screens/login_screen.dart';

class FakeAuthRepository extends AuthRepository {
  final Map<int, User> users = {};
  int _idCounter = 1;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = User(
      id: _idCounter++,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password: password,
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
    for (final u in users.values) {
      if (u.email == email.toLowerCase().trim()) {
        return AuthResult(success: true, user: u);
      }
    }
    return AuthResult(success: false, errorMessage: 'User not found');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Tahap 9: ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Default theme adalah ThemeMode.light', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.themeModeName, equals('Terang'));
      expect(provider.themeModeDescription, contains('Tampilan cerah'));
    });

    test('2. setThemeMode mengubah tema ke Light dan menyimpan di SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.themeModeName, equals('Terang'));
      expect(provider.themeIcon, equals(Icons.light_mode_rounded));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('light'));
    });

    test('3. setThemeMode mengubah tema ke Dark dan menyimpan di SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.themeModeName, equals('Gelap'));
      expect(provider.themeIcon, equals(Icons.dark_mode_rounded));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test(
      '4. loadThemeMode mengembalikan tema tersimpan dari SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
        final provider = ThemeProvider();
        await provider.loadThemeMode();

        expect(provider.themeMode, equals(ThemeMode.dark));
        expect(provider.isLoaded, isTrue);
      },
    );
  });

  group('Tahap 9: AuthProvider Profile Updating Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRepo = FakeAuthRepository();
      authProvider = AuthProvider(repository: fakeRepo);
    });

    test('1. Gagal updateProfile jika belum login', () async {
      final success = await authProvider.updateProfile(name: 'Nama Baru');
      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Tidak ada pengguna'));
    });

    test('2. Validasi: Nama kosong menghasilkan pesan error', () async {
      await authProvider.register(
        name: 'Budi Santoso',
        email: 'budi@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      final success = await authProvider.updateProfile(name: '   ');
      expect(success, isFalse);
      expect(authProvider.errorMessage, equals('Nama tidak boleh kosong.'));
    });

    test(
      '3. Validasi: Nama kurang dari 2 karakter menghasilkan error',
      () async {
        await authProvider.register(
          name: 'Budi Santoso',
          email: 'budi@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        );

        final success = await authProvider.updateProfile(name: 'A');
        expect(success, isFalse);
        expect(authProvider.errorMessage, equals('Nama minimal 2 karakter.'));
      },
    );

    test('4. Berhasil mengubah nama profil dan memperbarui state', () async {
      await authProvider.register(
        name: 'Budi Santoso',
        email: 'budi@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      final success = await authProvider.updateProfile(name: 'Budi Hartono');
      expect(success, isTrue);
      expect(authProvider.user?.name, equals('Budi Hartono'));
      expect(
        fakeRepo.users[authProvider.user!.id!]?.name,
        equals('Budi Hartono'),
      );
    });

    test('5. Berhasil mengubah mata uang profil', () async {
      await authProvider.register(
        name: 'Budi Santoso',
        email: 'budi@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      final success = await authProvider.updateProfile(currency: 'usd');
      expect(success, isTrue);
      expect(authProvider.user?.currency, equals('USD'));
      expect(authProvider.user?.name, equals('Budi Santoso'));
      expect(fakeRepo.users[authProvider.user!.id!]?.currency, equals('USD'));
    });
  });

  group('Tahap 9: ProfileScreen Widget Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthProvider authProvider;
    late ThemeProvider themeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRepo = FakeAuthRepository();
      authProvider = AuthProvider(repository: fakeRepo);
      themeProvider = ThemeProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      );
    }

    testWidgets('1. Menampilkan informasi profil akun yang sedang login', (
      tester,
    ) async {
      await authProvider.register(
        name: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Memeriksa informasi profil
      expect(find.text('Ahmad Dahlan'), findsOneWidget);
      expect(find.text('ahmad@example.com'), findsOneWidget);
      expect(find.text('IDR'), findsOneWidget);
      expect(find.text('Ubah Nama'), findsOneWidget);
      expect(find.text('Mata Uang'), findsWidgets);
    });

    testWidgets('2. Menampilkan dan mengubah mata uang profil', (tester) async {
      await authProvider.register(
        name: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('IDR'), findsOneWidget);

      // Buka dialog mata uang lewat tombol "Mata Uang".
      await tester.tap(find.widgetWithText(OutlinedButton, 'Mata Uang'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Mata Uang'), findsOneWidget);

      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      expect(authProvider.user?.currency, equals('USD'));
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets(
      '3. Menampilkan opsi preferensi tema dan membuka dialog pilihan tema',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Tema Aplikasi'), findsOneWidget);
        expect(find.text('Preferensi Tampilan'), findsOneWidget);

        // Buka dialog tema
        await tester.tap(find.text('Tema Aplikasi'));
        await tester.pumpAndSettle();

        expect(find.text('Pilih Tema Aplikasi'), findsOneWidget);
        expect(find.text('Mode Terang'), findsOneWidget);
        expect(find.text('Mode Gelap'), findsOneWidget);
        expect(find.text('Sistem (Otomatis)'), findsNothing);

        // Pilih Mode Gelap
        await tester.tap(find.text('Mode Gelap'));
        await tester.pumpAndSettle();

        expect(themeProvider.themeMode, equals(ThemeMode.dark));
      },
    );

    testWidgets('4. Membuka dialog konfirmasi logout dan membatalkannya', (
      tester,
    ) async {
      await authProvider.register(
        name: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll ke tile Keluar dari Akun
      final logoutFinder = find.text('Keluar dari Akun');
      await tester.scrollUntilVisible(logoutFinder, 200);
      await tester.pumpAndSettle();

      await tester.tap(logoutFinder);
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Logout'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Klik Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog tertutup, user tetap login
      expect(find.text('Konfirmasi Logout'), findsNothing);
      expect(authProvider.isAuthenticated, isTrue);
    });

    testWidgets(
      '5. Konfirmasi logout berhasil mengeluarkan akun dan kembali ke login',
      (tester) async {
        await authProvider.register(
          name: 'Ahmad Dahlan',
          email: 'ahmad@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final logoutFinder = find.text('Keluar dari Akun');
        await tester.scrollUntilVisible(logoutFinder, 200);
        await tester.pumpAndSettle();

        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();

        // Klik tombol Keluar di dialog
        await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
        await tester.pumpAndSettle();

        expect(authProvider.isAuthenticated, isFalse);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets('6. Ubah nama melalui dialog mengubah nama akun seketika', (
      tester,
    ) async {
      await authProvider.register(
        name: 'Ahmad Dahlan',
        email: 'ahmad@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ahmad Dahlan'), findsOneWidget);

      // Tap Ubah Nama
      await tester.tap(find.text('Ubah Nama'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nama Lengkap'), findsOneWidget);

      // Masukkan nama baru
      final textFormFieldFinder = find.byType(TextFormField);
      await tester.enterText(textFormFieldFinder, 'K.H. Ahmad Dahlan');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Verifikasi nama terupdate di layar
      expect(find.text('K.H. Ahmad Dahlan'), findsOneWidget);
      expect(authProvider.user?.name, equals('K.H. Ahmad Dahlan'));
    });
  });
}
