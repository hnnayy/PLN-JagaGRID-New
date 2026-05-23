import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'treemapping_report.dart';
import 'rekapan_per_unit_page.dart';
import '../../services/data_pohon_service.dart';
import '../../models/data_pohon.dart';

class ReportMenuPage extends StatelessWidget {
  const ReportMenuPage({Key? key}) : super(key: key);

  Future<Map<String, int>> _getStatistics() async {
    try {
      final service = DataPohonService();
      final snapshot = await service.getAllDataPohon().first;

      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';

      List<DataPohon> filteredList = snapshot;
      if (level == 2) {
        filteredList = snapshot
            .where((p) => p.up3 == sessionUnit || p.ulp == sessionUnit)
            .toList();
      }

      final totalPohon = filteredList.length;
      final totalUnit = filteredList
          .map((p) => p.ulp.isNotEmpty ? p.ulp : p.up3)
          .where((unit) => unit.isNotEmpty)
          .toSet()
          .length;

      return {'totalPohon': totalPohon, 'totalUnit': totalUnit};
    } catch (e) {
      return {'totalPohon': 0, 'totalUnit': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6B7C),
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Laporan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _getStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? {'totalPohon': 0, 'totalUnit': 0};
          final totalPohon = stats['totalPohon'] ?? 0;
          final totalUnit = stats['totalUnit'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B6B7C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.park,
                          label: 'Total Pohon',
                          value: '$totalPohon',
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.white24),
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.business,
                          label: 'Total Unit',
                          value: '$totalUnit',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Menu Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Card Semua Data Pohon
                _buildMenuCard(
                  context: context,
                  icon: Icons.description_outlined,
                  title: 'Semua Data Pohon',
                  subtitle: 'Lihat seluruh data pohon yang telah diinput',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeMappingReportPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Card Rekapan Per Unit
                _buildMenuCard(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Rekapan Per Unit',
                  subtitle: 'Statistik pohon berdasarkan unit kerja',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RekapanPerUnitListPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF2B6B7C).withOpacity(0.08),
        highlightColor: const Color(0xFF2B6B7C).withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6B7C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2B6B7C), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}