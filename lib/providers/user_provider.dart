import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Provider untuk mengelola state user.
///
/// Menyimpan user yang sedang aktif (login) dan menyediakan
/// method untuk operasi CRUD melalui UserRepository.
class UserProvider extends ChangeNotifier {
  final UserRepository _repository;

  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserProvider({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  // ──────────── GETTERS ────────────

  User? get currentUser => _currentUser;
  List<User> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _currentUser != null;

  // ──────────── METHODS ────────────

  /// Tambah user baru dan set sebagai user aktif.
  Future<void> createUser({
    required String name,
    String? email,
    String currency = 'IDR',
  }) async {
    _setLoading(true);
    try {
      final user = User(name: name, email: email, currency: currency);
      final id = await _repository.insertUser(user);
      _currentUser = user.copyWith(id: id);
      _errorMessage = null;
      await loadAllUsers();
    } catch (e) {
      _errorMessage = 'Gagal membuat user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Muat semua users dari database.
  Future<void> loadAllUsers() async {
    _setLoading(true);
    try {
      _users = await _repository.getAllUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat users: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Set user aktif berdasarkan ID.
  Future<void> setCurrentUser(int userId) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.getUserById(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update data user yang sedang aktif.
  Future<void> updateCurrentUser({
    String? name,
    String? email,
    String? currency,
  }) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      final updated = _currentUser!.copyWith(
        name: name,
        email: email,
        currency: currency,
      );
      await _repository.updateUser(updated);
      _currentUser = updated;
      _errorMessage = null;
      await loadAllUsers();
    } catch (e) {
      _errorMessage = 'Gagal update user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Hapus user berdasarkan ID.
  Future<void> deleteUser(int userId) async {
    _setLoading(true);
    try {
      await _repository.deleteUser(userId);
      if (_currentUser?.id == userId) {
        _currentUser = null;
      }
      _errorMessage = null;
      await loadAllUsers();
    } catch (e) {
      _errorMessage = 'Gagal menghapus user: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

