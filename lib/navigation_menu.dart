import 'package:flutter/material.dart';
import 'page/home_page.dart';
import 'page/peta_pohon/map_page.dart';
import 'page/report/report_menu.dart'; // ✅ GANTI IMPORT INI
import 'page/settings/settingcontent.dart' as settings;
import 'package:flutter_application_2/page/notification/notification_page.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  // Menyimpan index halaman yang sedang aktif
  int _selectedIndex = 0;

  // Daftar halaman yang dapat dipilih
  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    const MapPage(),
    ReportMenuPage(), // ✅ GANTI JADI ReportMenuPage()
    const NotificationPage(),
    const settings.SettingsMainContent(),
  ];

  // Fungsi untuk menangani perubahan halaman
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman yang sesuai dengan index yang dipilih
      body: _widgetOptions[_selectedIndex],
      
      // Bottom navigation bar
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFE8FBF9),
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
          onTap: _onItemTapped, // Mengubah halaman berdasarkan item yang dipilih
          iconSize: 28,
          items: [
            // Menu "Home"
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/home.png', 0),
              activeIcon: _buildNavIcon('assets/icons/home.png', 0, isSelected: true),
              label: 'Home',
            ),
            // Menu "Peta Pohon"
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/peta.png', 1),
              activeIcon: _buildNavIcon('assets/icons/peta.png', 1, isSelected: true),
              label: 'Peta Pohon',
            ),
            // Menu "Statistik"
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/report.png', 2),
              activeIcon: _buildNavIcon('assets/icons/report.png', 2, isSelected: true),
              label: 'Statistik',
            ),
            // Menu "Notifikasi"
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/notification.png', 3),
              activeIcon: _buildNavIcon('assets/icons/notification.png', 3, isSelected: true),
              label: 'Notifikasi',
            ),
            // Menu "Setting"
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/setting.png', 4),
              activeIcon: _buildNavIcon('assets/icons/setting.png', 4, isSelected: true),
              label: 'Setting',
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  // Membuat ikon menu dengan penyesuaian warna berdasarkan apakah item aktif atau tidak
  Widget _buildNavIcon(String assetPath, int index, {bool isSelected = false}) {
    return SizedBox(
      width: 28,
      height: 28,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          isSelected ? const Color(0xFF0B5F6D) : Colors.black.withOpacity(0.7),
          BlendMode.srcIn,
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
