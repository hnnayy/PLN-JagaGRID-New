import 'package:flutter/material.dart';
import 'layoutsetting.dart';
import 'assets_jtm/assets_jtm.dart'; // ✅ Import halaman Assets JTM menu utama
import 'package:flutter_application_2/page/settings/profile/profile_page.dart';
import 'package:flutter_application_2/page/settings/profile/user_list_page.dart';
import '../../page/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../page/tree_growth/tree_growth_list_page.dart';

/// -------------------------
/// Settings Item Content
/// -------------------------
class SettingsContent {
  static Future<List<SettingsItem>> getSettingsItems() async {
    // Ambil level dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    if (level == 1) {
      // Level 1: semua item
      return [
        const SettingsItem(
          title: 'Profile',
          iconPath: 'assets/icons/profile.png',
        ),
        const SettingsItem(
          title: 'Tambah User',
          iconPath: 'assets/icons/add.png',
        ),
        const SettingsItem(
          title: 'Daftar Assets JTM',
          iconPath: 'assets/icons/powerline.png',
        ),
        const SettingsItem(
          title: 'Master Pertumbuhan pohon',
          iconPath: 'assets/icons/pohon-hijau.png',
        ),
        const SettingsItem(
          title: 'Logout',
          iconPath: 'assets/icons/logout.png',
        ),
      ];
    } else {
      // Level 2: hanya profile dan logout
      return [
        const SettingsItem(
          title: 'Profile',
          iconPath: 'assets/icons/profile.png',
        ),
        const SettingsItem(
          title: 'Logout',
          iconPath: 'assets/icons/logout.png',
        ),
      ];
    }
  }

  static Future<void> handleSettingsTap(int index, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    if (level == 1) {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserListPage()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssetsJTMPage()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TreeGrowthListPage()),
          );
          break;
        case 4:
          _showLogoutDialog(context);
          break;
      }
    } else {
      // Level 2: hanya profile dan logout
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
          break;
        case 1:
          _showLogoutDialog(context);
          break;
      }
    }
  }

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('session_id');
                await prefs.remove('session_username');
                await prefs.remove('session_name');
                await prefs.remove('session_unit');
                await prefs.remove('session_level');
                await prefs.remove('session_added');
                await prefs.remove('session_username_telegram');
                await prefs.remove('session_chat_id_telegram');
                await prefs.remove('session_status');
                await prefs.remove('session_timestamp');
                await prefs.remove('hasCompletedOnboarding');
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

/// -------------------------
/// Main Settings Page
/// -------------------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4; // Settings ada di tab ke-5 (index 4)

  final List<Widget> _widgetOptions = const [
    HomePage(),
    Page2(),
    Page3(),
    Page4(),
    SettingsMainContent(), // ✅ Halaman utama settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8FBF9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF0B5F6D),
          unselectedItemColor: Colors.black,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Page2'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Page3'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Page4'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

/// -------------------------
/// Settings Main Content
/// -------------------------
class SettingsMainContent extends StatelessWidget {
  const SettingsMainContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SettingsItem>>(
      future: SettingsContent.getSettingsItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        return SettingsLayout(
          title: 'Settings',
          settingsItems: items,
          onItemTap: (index) => SettingsContent.handleSettingsTap(index, context),
        );
      },
    );
  }
}

/// -------------------------
/// Placeholder Pages
/// -------------------------
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home Page')),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page 2')),
    );
  }
}

class Page3 extends StatelessWidget {
  const Page3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page 3')),
    );
  }
}

class Page4 extends StatelessWidget {
  const Page4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page 4')),
    );
  }
}