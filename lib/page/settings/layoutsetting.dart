import 'package:flutter/material.dart';

// File: lib/page/settings/layoutsetting.dart
class SettingsLayout extends StatelessWidget {
  final String title;
  final List<SettingsItem> settingsItems;
  final Function(int) onItemTap;

  const SettingsLayout({
    Key? key,
    required this.title,
    required this.settingsItems,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF125E72), 
            Color(0xFF14A2B9),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Custom header area with dynamic title positioned in the middle
            Container(
              height: 160, // Total height for the header area
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Settings content area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  itemCount: settingsItems.length,
                  itemBuilder: (context, index) {
                    return _buildSettingsItem(settingsItems[index], index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => onItemTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14A2B9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      item.iconPath,
                      width: 24,
                      height: 24,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF95A5A6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final String iconPath;

  const SettingsItem({
    required this.title,
    required this.iconPath,
  });
}