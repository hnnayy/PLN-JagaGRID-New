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
      
      // Filter berdasarkan session level & unit
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';
      
      List<DataPohon> filteredList = snapshot;
      if (level == 2) {
        filteredList = snapshot.where((p) => 
          p.up3 == sessionUnit || p.ulp == sessionUnit
        ).toList();
      }
      
      // Hitung statistik
      final totalPohon = filteredList.length;
      final totalUnit = filteredList
          .map((p) => p.ulp.isNotEmpty ? p.ulp : p.up3)
          .where((unit) => unit.isNotEmpty)
          .toSet()
          .length;
      
      return {
        'totalPohon': totalPohon,
        'totalUnit': totalUnit,
      };
    } catch (e) {
      return {
        'totalPohon': 0,
        'totalUnit': 0,
      };
    }
  }

  Future<void> _navigateToRekapan(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RekapanPerUnitListPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6B7C),
        automaticallyImplyLeading: false,
        title: const Text(
          'Laporan',
          style: TextStyle(color: Color.fromARGB(255, 245, 245, 244), fontSize: 20),
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
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card Semua Data Pohon
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreeMappingReportPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF2B6B7C),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Semua Data Pohon',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Lihat Seluruh Data Pohon Yang Telah Diinput',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.file_copy, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Total: $totalPohon pohon',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Card Rekapan Per Unit
                InkWell(
                  onTap: () => _navigateToRekapan(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            color: Color(0xFF2B6B7C),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rekapan Per Unit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Statistik Pohon Berdasarkan Unit Kerja',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.trending_up, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalUnit Unit Aktif',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}