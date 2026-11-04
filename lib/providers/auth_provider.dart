import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// Status autentikasi aplikasi.
enum AuthStatus {
  unknown, // Belum dicek (splash screen)
  authenticated, // User sudah login
  unauthenticated, // User belum login
}

/// Provider untuk mengelola status autentikasi.
///
/// Menggunakan [SharedPreferences] untuk menyimpan sesi login
/// sehingga user tetap login setelah aplikasi ditutup & dibuka kembali.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Key untuk SharedPreferences
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  // ──────────── GETTERS ────────────

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  int? get userId => _user?.id;

  // ──────────── METHODS ────────────

  /// Cek apakah user sudah login sebelumnya (dipanggil di splash screen).
  ///
  /// Membaca SharedPreferences untuk mengembalikan sesi sebelumnya.
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getInt(_keyUserId);

      if (isLoggedIn && userId != null) {
        // Restore sesi: ambil data user dari database
        final user = await _repository.getUserById(userId);
        if (user != null) {
          _user = user;
          _status = AuthStatus.authenticated;
        } else {
          // User tidak ditemukan di database (mungkin sudah dihapus)
          await _clearSession();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Gagal memeriksa status login: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Login dengan email dan password.
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Validasi input
      final validationError = _validateLoginInput(email, password);
      if (validationError != null) {
        _errorMessage = validationError;
        _setLoading(false);
        return false;
      }

      final result = await _repository.login(email: email, password: password);

      if (result.success && result.user != null) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        await _saveSession(result.user!.id!);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result.errorMessage;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Daftar akun baru.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Validasi input
      final validationError = _validateRegisterInput(
        name,
        email,
        password,
        confirmPassword,
      );
      if (validationError != null) {
        _errorMessage = validationError;
        _setLoading(false);
        return false;
      }

      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        await _saveSession(result.user!.id!);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result.errorMessage;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat mendaftar: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Update profil pengguna (nama pengguna).
  Future<bool> updateProfile({required String name}) async {
    if (_user == null) {
      _errorMessage = 'Tidak ada pengguna yang sedang login.';
      notifyListeners();
      return false;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Nama tidak boleh kosong.';
      notifyListeners();
      return false;
    }
    if (trimmedName.length < 2) {
      _errorMessage = 'Nama minimal 2 karakter.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedUser = _user!.copyWith(
        name: trimmedName,
        updatedAt: DateTime.now(),
      );
      final success = await _repository.updateUser(updatedUser);
      if (success) {
        _user = updatedUser;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Gagal memperbarui profil pengguna.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui profil: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Logout dan hapus sesi.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _clearSession();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal logout: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Bersihkan pesan error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ──────────── PRIVATE HELPERS ────────────

  /// Simpan sesi login ke SharedPreferences.
  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, userId);
  }

  /// Hapus sesi login dari SharedPreferences.
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
  }

  /// Validasi input login.
  String? _validateLoginInput(String email, String password) {
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!_isValidEmail(email)) {
      return 'Format email tidak valid.';
    }
    if (password.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    return null;
  }

  /// Validasi input register.
  String? _validateRegisterInput(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) {
    if (name.trim().isEmpty) {
      return 'Nama tidak boleh kosong.';
    }
    if (name.trim().length < 2) {
      return 'Nama minimal 2 karakter.';
    }
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    if (!_isValidEmail(email)) {
      return 'Format email tidak valid.';
    }
    if (password.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    if (password != confirmPassword) {
      return 'Konfirmasi password tidak cocok.';
    }
    return null;
  }

  /// Cek apakah format email valid.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
