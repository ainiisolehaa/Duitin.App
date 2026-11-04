import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duitin/providers/auth_provider.dart';
import 'package:duitin/repositories/auth_repository.dart';
import 'package:duitin/models/user.dart';

// Fake AuthRepository untuk unit test AuthProvider
class FakeAuthRepository extends AuthRepository {
  final Map<String, User> _mockUsers = {};
  int _idCounter = 1;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    if (_mockUsers.containsKey(normalizedEmail)) {
      return AuthResult(
        success: false,
        errorMessage: 'Email sudah terdaftar. Silakan gunakan email lain.',
      );
    }

    final user = User(
      id: _idCounter++,
      name: name.trim(),
      email: normalizedEmail,
      password: 'mock_hashed_$password',
    );
    _mockUsers[normalizedEmail] = user;
    return AuthResult(success: true, user: user);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final user = _mockUsers[normalizedEmail];

    if (user == null) {
      return AuthResult(
        success: false,
        errorMessage: 'Email belum terdaftar. Silakan daftar terlebih dahulu.',
      );
    }

    if (user.password != 'mock_hashed_$password') {
      return AuthResult(
        success: false,
        errorMessage: 'Password salah. Silakan coba lagi.',
      );
    }

    return AuthResult(success: true, user: user);
  }

  @override
  Future<User?> getUserById(int id) async {
    for (final user in _mockUsers.values) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  Future<bool> updateUser(User user) async {
    for (final entry in _mockUsers.entries) {
      if (entry.value.id == user.id) {
        _mockUsers[entry.key] = user;
        return true;
      }
    }
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRepo = FakeAuthRepository();
      authProvider = AuthProvider(repository: fakeRepo);
    });

    test('Status awal adalah AuthStatus.unknown', () {
      expect(authProvider.status, equals(AuthStatus.unknown));
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('Validasi Register: Nama minimal 2 karakter', () async {
      final success = await authProvider.register(
        name: 'A',
        email: 'user@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('minimal 2 karakter'));
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('Validasi Register: Format email salah', () async {
      final success = await authProvider.register(
        name: 'Aini',
        email: 'invalid-email',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Format email tidak valid'));
    });

    test('Validasi Register: Password minimal 6 karakter', () async {
      final success = await authProvider.register(
        name: 'Aini',
        email: 'aini@test.com',
        password: '123',
        confirmPassword: '123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('minimal 6 karakter'));
    });

    test('Validasi Register: Konfirmasi password tidak cocok', () async {
      final success = await authProvider.register(
        name: 'Aini',
        email: 'aini@test.com',
        password: 'password123',
        confirmPassword: 'passwordBeda',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('tidak cocok'));
    });

    test('Register Berhasil dan simpan sesi', () async {
      final success = await authProvider.register(
        name: 'Aini',
        email: 'aini@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, equals('Aini'));
      expect(authProvider.user?.email, equals('aini@test.com'));

      // Cek sesi tersimpan di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isTrue);
      expect(prefs.getInt('user_id'), isNotNull);
    });

    test('Register dengan email yang sudah ada menghasilkan error', () async {
      // Register pertama
      await authProvider.register(
        name: 'Aini',
        email: 'duplikat@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // Register kedua dengan email sama
      final provider2 = AuthProvider(repository: fakeRepo);
      final success = await provider2.register(
        name: 'Budi',
        email: 'duplikat@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      expect(success, isFalse);
      expect(provider2.errorMessage, contains('sudah terdaftar'));
    });

    test('Login: Error jika akun belum terdaftar', () async {
      final success = await authProvider.login(
        email: 'tidakada@test.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('belum terdaftar'));
    });

    test('Login: Error jika password salah', () async {
      // Daftarkan dulu
      await authProvider.register(
        name: 'Aini',
        email: 'aini@test.com',
        password: 'passwordBenar',
        confirmPassword: 'passwordBenar',
      );
      await authProvider.logout();

      // Coba login password salah
      final success = await authProvider.login(
        email: 'aini@test.com',
        password: 'passwordSalah',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Password salah'));
    });

    test('Login Berhasil & Logout Berhasil (Session clearing)', () async {
      // 1. Registrasi
      await authProvider.register(
        name: 'Aini',
        email: 'aini@test.com',
        password: 'password123',
        confirmPassword: 'password123',
      );

      // 2. Logout
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isNull);
      expect(prefs.getInt('user_id'), isNull);

      // 3. Login kembali
      final loginSuccess = await authProvider.login(
        email: 'aini@test.com',
        password: 'password123',
      );
      expect(loginSuccess, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.email, equals('aini@test.com'));

      // 4. Session check restore
      final newSessionProvider = AuthProvider(repository: fakeRepo);
      await newSessionProvider.checkAuthStatus();
      expect(newSessionProvider.isAuthenticated, isTrue);
      expect(newSessionProvider.user?.name, equals('Aini'));
    });
  });
}

