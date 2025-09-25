import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application_2/main.dart';
import 'package:flutter_application_2/page/splash_screen.dart';
import 'package:flutter_application_2/navigation_menu.dart';

// Mock class untuk Firebase
class MockFirebaseApp extends Mock implements FirebaseApp {}

void main() {
  // Setup untuk menangani inisialisasi Firebase dan SharedPreferences
  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Mock Firebase
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MyApp Widget Tests', () {
    testWidgets('MyApp menampilkan SplashScreen saat belum login', (WidgetTester tester) async {
      // Atur SharedPreferences agar tidak ada session_username (belum login)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Build MyApp dengan isLoggedIn = false
      await tester.pumpWidget(const MyApp(isLoggedIn: false));

      // Tunggu hingga frame selesai dirender
      await tester.pumpAndSettle();

      // Verifikasi bahwa SplashScreen ditampilkan
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(NavigationMenu), findsNothing);
    });

    testWidgets('MyApp menampilkan NavigationMenu saat sudah login', (WidgetTester tester) async {
      // Atur SharedPreferences agar ada session_username (sudah login)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_username', '@testuser');

      // Build MyApp dengan isLoggedIn = true
      await tester.pumpWidget(const MyApp(isLoggedIn: true));

      // Tunggu hingga frame selesai dirender
      await tester.pumpAndSettle();

      // Verifikasi bahwa NavigationMenu ditampilkan
      expect(find.byType(NavigationMenu), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}