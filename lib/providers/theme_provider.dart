import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola preferensi tema aplikasi (Light, Dark, System).
///
/// Preferensi tema disimpan di [SharedPreferences] sehingga pilihan
/// pengguna tetap tersimpan setelah aplikasi ditutup.
class ThemeProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  /// Nama tema dalam bahasa Indonesia.
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  /// Deskripsi tema dalam bahasa Indonesia.
  String get themeModeDescription {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Tampilan cerah dan bersih';
      case ThemeMode.dark:
        return 'Tampilan gelap nyaman di mata';
      case ThemeMode.system:
        return 'Mengikuti preferensi sistem perangkat';
    }
  }

  /// Icon sesuai tema aktif.
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  /// Muat preferensi tema dari SharedPreferences.
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_keyThemeMode);

      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    } catch (_) {
      _themeMode = ThemeMode.system;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Ubah preferensi tema dan simpan ke SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr;
      switch (mode) {
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        case ThemeMode.system:
          modeStr = 'system';
          break;
      }
      await prefs.setString(_keyThemeMode, modeStr);
    } catch (_) {
      // Abaikan jika penyimpanan lokal gagal
    }
  }
}
