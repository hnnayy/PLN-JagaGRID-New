import 'package:flutter/material.dart';
import 'page/home_page.dart';
import 'page/peta_pohon/map_page.dart';
import 'page/report/treemapping_report.dart';
import 'page/settings/settingcontent.dart' as settings;
import 'package:flutter_application_2/page/notification/notification_page.dart';


class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    const MapPage(),
    TreeMappingReportPage(),
    const NotificationPage(),            // ✅ Page 4 diganti dengan NotificationPage
    const settings.SettingsMainContent(), // Page 5 Setting
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
        height: 70, // Slightly taller than default (~56px)
        decoration: BoxDecoration(
          color: const Color(0xFFE8FBF9), // Retain original white-ish background
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
          backgroundColor: Colors.transparent, // Retain transparent to show Container's color
          elevation: 0,
          selectedItemColor: const Color(0xFF0B5F6D), // Retain original selected item color
          unselectedItemColor: Colors.black, // Retain original unselected item color
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          iconSize: 28, // Slightly larger icons to match taller bar
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/home.png', 0),
              activeIcon: _buildNavIcon('assets/icons/home.png', 0, isSelected: true),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/peta.png', 1),
              activeIcon: _buildNavIcon('assets/icons/peta.png', 1, isSelected: true),
              label: 'Peta Pohon',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/report.png', 2),
              activeIcon: _buildNavIcon('assets/icons/report.png', 2, isSelected: true),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/notification.png', 3),
              activeIcon: _buildNavIcon('assets/icons/notification.png', 3, isSelected: true),
              label: 'Notifikasi',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon('assets/icons/setting.png', 4),
              activeIcon: _buildNavIcon('assets/icons/setting.png', 4, isSelected: true),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
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

