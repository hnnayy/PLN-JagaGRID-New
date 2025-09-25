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

// Global navigator key untuk navigasi dari notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("ENV file not found: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // ganti playIntegrity di production
    );

    print('✅ Firebase initialized successfully + App Check active');
  } catch (e) {
    print('❌ Error initializing Firebase/AppCheck: $e');
  }

  // Ensure we have a Firebase Auth user before any Firestore access
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('🔐 Signed in anonymously for Firestore access');
    } else {
      print('🔐 Auth session already available (${auth.currentUser!.uid})');
    }
  } catch (e) {
    print('❌ Failed to sign in anonymously: $e');
  }

  // Periksa status login dengan penanganan error
  bool isLoggedIn = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getString('session_username') != null;
  } catch (e) {
    print('❌ Error accessing SharedPreferences: $e');
    isLoggedIn = false; // Default ke false jika gagal
  }

  runApp(OverlaySupport(
    child: MyApp(isLoggedIn: isLoggedIn),
  ));

  // Fungsi rekursif untuk setup navigation callback dengan retry
  void _setupNavigationCallback(int attempt) {
    if (attempt >= 5) {
      debugPrint('❌ Gagal setup navigation callback setelah 5 percobaan');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted && context.findRenderObject() != null) {
      try {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.setNotificationTapCallback((String? documentId) async {
          if (documentId != null && documentId.isNotEmpty) {
            try {
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('data_pohon')
                  .doc(documentId)
                  .get();

              if (docSnapshot.exists && navigatorKey.currentState != null && navigatorKey.currentContext != null) {
                final pohon = DataPohon.fromMap({
                  ...docSnapshot.data()!,
                  'id': docSnapshot.id,
                });

                if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
                  navigatorKey.currentState!.push(
                    MaterialPageRoute(
                      builder: (context) => TreeMappingDetailPage(pohon: pohon),
                    ),
                  );
                  debugPrint('✅ Navigasi ke detail pohon berhasil: $documentId');
                } else {
                  debugPrint('⚠️ Context tidak valid untuk navigasi: $documentId');
                }
              } else {
                debugPrint('❌ Document tidak ditemukan atau navigator tidak tersedia: $documentId');
              }
            } catch (e) {
              debugPrint('❌ Error fetching pohon for notification: $e');
            }
          } else {
            debugPrint('❌ Document ID kosong atau null');
          }
        });
        debugPrint('🔧 Navigation callback berhasil di-setup pada attempt ${attempt + 1}');
      } catch (e) {
        debugPrint('❌ Error setting up navigation callback pada attempt ${attempt + 1}: $e');
        Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)), () {
          _setupNavigationCallback(attempt + 1);
        });
      }
    } else {
      debugPrint('⏳ Menunggu context stabil... attempt ${attempt + 1}');
      Future.delayed(const Duration(milliseconds: 500), () {
        _setupNavigationCallback(attempt + 1);
      });
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _setupNavigationCallback(0);

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final notif = Provider.of<NotificationProvider>(ctx, listen: false);
      ReminderService.runThreeDayTelegramRemindersIfNeeded(notif);
    }
  });
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataPohonProvider()),
        ChangeNotifierProvider(create: (_) => EksekusiProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GrowthPredictionProvider()),
        ChangeNotifierProvider(create: (_) => TreeGrowthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: isLoggedIn ? const NavigationMenu() : const SplashScreen(),
        routes: {
          '/map': (context) => MapPage(),
          '/addData': (context) => AddDataPage(),
          '/report': (context) => TreeMappingReportPage(),
          '/treeGrowth': (context) => const TreeGrowthListPage(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}