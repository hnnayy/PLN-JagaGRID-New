import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';  // File ini dari flutterfire configure
import 'providers/data_pohon_provider.dart';
import 'page/splash_screen.dart';
import 'page/peta_pohon/map_page.dart';
import 'page/peta_pohon/add_data_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Inisialisasi Firebase App Check dengan provider debug untuk testing
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,  // Gunakan debug untuk pengembangan
      // Tambahkan debug token dari log (lihat langkah di bawah)
      // Contoh: appleProvider: AppleProvider.appAttest,
    );
    print('Firebase and App Check initialized successfully');
  } catch (e) {
    print('Error initializing Firebase or App Check: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataPohonProvider()),
      ],
      child: MaterialApp(
        home: SplashScreen(),  // Halaman splash awal
        routes: {
          '/map': (context) => const MapPage(),
          '/addData': (context) => AddDataPage(),
        },
      ),
    );
  }
}