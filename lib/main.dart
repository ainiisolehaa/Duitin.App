import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Siapkan akun & data demo saat pertama kali aplikasi dijalankan.
  // Dibatasi dengan timeout + try/catch agar kegagalan/lambatnya database
  // tidak pernah membuat aplikasi berhenti di layar hitam sebelum runApp().
  try {
    await DataSeeder.seedStudentData().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Gagal menyiapkan data demo: $e');
  }

  runApp(const DuitinApp());
}

class DuitinApp extends StatelessWidget {
  const DuitinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemeMode()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Duitin',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00897B), // Teal
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00897B),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Scroll behavior yang mengizinkan gesture drag pada layar sentuh maupun pointer mouse/trackpad.
/// Memastikan komponen scroll horizontal (seperti chip kategori) dapat digeser dengan mulus
/// di semua perangkat (emulator, HP fisik, maupun desktop).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
