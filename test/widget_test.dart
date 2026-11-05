import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duitin/main.dart';
import 'package:duitin/screens/splash_screen.dart';
import 'package:duitin/screens/login_screen.dart';

void main() {
  testWidgets('DuitinApp renders SplashScreen and navigates to LoginScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DuitinApp());

    // 1. Splash Screen tampil pertama kali
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Duitin'), findsOneWidget);
    expect(find.text('Catat Keuanganmu dengan Mudah'), findsOneWidget);

    // 2. Majukan waktu hingga animasi splash dan delay 2 detik selesai
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Karena belum login, otomatis berpindah ke LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Duitin'), findsOneWidget);
    expect(
      find.text('Masuk untuk mengelola keuangan harianmu'),
      findsOneWidget,
    );
  });
}
