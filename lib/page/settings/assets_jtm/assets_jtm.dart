import 'package:flutter/material.dart';
import '../layoutsetting.dart'; // Import layout yang sudah ada
import '../assets_jtm/add_assets.dart'; // Import halaman add assets yang baru dibuat
import '../assets_jtm/daftar_asset.dart'; // Import halaman daftar asset yang baru dibuat

// File: lib/page/settings/assets_jtm.dart
class AssetsJTMPage extends StatelessWidget {
  const AssetsJTMPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Data untuk menu Assets JTM
    final List<SettingsItem> assetsMenuItems = [
      const SettingsItem(
        title: 'Tambah Assets JTM',
        iconPath: 'assets/icons/add.png',
      ),
      const SettingsItem(
        title: 'Daftar Assets JTM',
        iconPath: 'assets/icons/list.png',
      ),
    ];

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Assets JTM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
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
                  itemCount: assetsMenuItems.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: InkWell(
                          onTap: () {
                            // Handle tap untuk setiap menu item
                            switch (index) {
                              case 0:
                                // Navigasi ke halaman Tambah Assets JTM
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddAssetsPage(),
                                  ),
                                );
                                break;
                              case 1:
                                // Navigasi ke halaman Daftar Assets JTM (daftar_asset.dart)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DaftarAssetPage(),
                                  ),
                                );
                                break;
                            }
                          },
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
                                      assetsMenuItems[index].iconPath,
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    assetsMenuItems[index].title,
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
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}