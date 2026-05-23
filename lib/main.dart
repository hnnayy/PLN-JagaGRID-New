import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/data_pohon.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:overlay_support/overlay_support.dart';
import 'providers/data_pohon_provider.dart';
import 'providers/eksekusi_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/growth_prediction_provider.dart';
import 'providers/tree_growth_provider.dart';
import 'page/splash_screen.dart';
import 'page/peta_pohon/map_page.dart';
import 'page/peta_pohon/add_data_page.dart';
import 'page/report/treemapping_report.dart';
import 'page/report/treemapping_detail.dart';
import 'page/tree_growth/tree_growth_list_page.dart';
import 'page/login/login.dart';
import 'navigation_menu.dart';
import 'services/reminder_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // LOAD ENV
  // =========================================================
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ ENV loaded');
  } catch (e) {
    debugPrint('❌ ENV gagal load: $e');
  }

  // =========================================================
  // FIREBASE INIT
  // =========================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }

  // =========================================================
  // AUTH ANON
  // =========================================================
  try {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint('✅ Anonymous auth success');
    } else {
      debugPrint('✅ Auth already available');
    }
  } catch (e) {
    debugPrint('❌ Anonymous auth failed: $e');
  }

  // =========================================================
  // SESSION LOGIN
  // =========================================================
  bool isLoggedIn = false;

  try {
    final prefs = await SharedPreferences.getInstance();

    isLoggedIn =
        prefs.getString('session_username') != null;
  } catch (e) {
    debugPrint('❌ SharedPreferences error: $e');
  }

  // =========================================================
  // RUN APP
  // =========================================================
  runApp(
    OverlaySupport(
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );

  // =========================================================
  // SETUP CALLBACK NAVIGATION
  // =========================================================
  void setupNotificationNavigation(int attempt) {
    if (attempt >= 5) {
      debugPrint('❌ Setup callback gagal');
      return;
    }

    final context = navigatorKey.currentContext;

    if (context != null &&
        context.mounted &&
        context.findRenderObject() != null) {
      try {
        final notificationProvider =
            Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        notificationProvider
            .setNotificationTapCallback(
          (String? documentId) async {
            if (documentId == null ||
                documentId.isEmpty) {
              debugPrint('❌ documentId kosong');
              return;
            }

            try {
              final docSnapshot =
                  await FirebaseFirestore.instance
                      .collection('data_pohon')
                      .doc(documentId)
                      .get();

              if (!docSnapshot.exists) {
                debugPrint('❌ Pohon tidak ditemukan');
                return;
              }

              final pohon = DataPohon.fromMap({
                ...docSnapshot.data()!,
                'id': docSnapshot.id,
              });

              if (navigatorKey.currentState != null &&
                  navigatorKey.currentContext != null) {
                navigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TreeMappingDetailPage(
                      pohon: pohon,
                    ),
                  ),
                );

                debugPrint(
                    '✅ Navigasi notif berhasil');
              }
            } catch (e) {
              debugPrint(
                  '❌ Error open notification: $e');
            }
          },
        );

        debugPrint(
            '✅ Notification callback ready');
      } catch (e) {
        debugPrint(
            '❌ Setup callback error: $e');

        Future.delayed(
          Duration(milliseconds: 1000 * (attempt + 1)),
          () => setupNotificationNavigation(attempt + 1),
        );
      }
    } else {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => setupNotificationNavigation(attempt + 1),
      );
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    setupNotificationNavigation(0);

    final ctx = navigatorKey.currentContext;

    if (ctx != null) {
      final notif = Provider.of<NotificationProvider>(
        ctx,
        listen: false,
      );

      // =====================================================
      // H-3 REMINDER CHECK
      // =====================================================
      ReminderService
          .runThreeDayTelegramRemindersIfNeeded(
        notif,
      );
    }
  });
}

// =========================================================
// APP
// =========================================================
class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DataPohonProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EksekusiProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => GrowthPredictionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TreeGrowthProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: isLoggedIn
            ? const NavigationMenu()
            : const SplashScreen(),
        routes: {
          '/map': (context) => MapPage(),
          '/addData': (context) => AddDataPage(),
          '/report': (context) => TreeMappingReportPage(),
          '/treeGrowth': (context) =>
              const TreeGrowthListPage(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}