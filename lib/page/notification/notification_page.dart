import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../models/data_pohon.dart';
import '../report/treemapping_detail.dart'; // Import TreeMappingDetailPage

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Method to get session data (level and unit)
  Future<Map<String, dynamic>> _getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'session_level': prefs.getInt('session_level') ?? 2,
      'session_unit': prefs.getString('session_unit') ?? '',
    };
  }

  // Fungsi untuk mengambil data pohon dari Firestore berdasarkan document ID
  Future<DataPohon?> _fetchPohon(String documentId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('data_pohon')
          .doc(documentId)
          .get();
      if (docSnapshot.exists) {
        return DataPohon.fromMap({
          ...docSnapshot.data()!,
          'id': docSnapshot.id,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching pohon: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5D6F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        leading: const SizedBox(),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getSessionData(),
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sessionSnapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan mengambil data sesi'));
          }

          final sessionData = sessionSnapshot.data ?? {'session_level': 2, 'session_unit': ''};
          final sessionLevel = sessionData['session_level'] as int;
          final sessionUnit = sessionData['session_unit'] as String;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notification')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan mengambil notifikasi'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                // Apply client-side filtering based on session level
                if (sessionLevel == 2 && sessionUnit.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final up3 = data['up3'] as String? ?? '';
                    final ulp = data['ulp'] as String? ?? '';
                    return up3 == sessionUnit || ulp == sessionUnit;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada notifikasi'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final notif = AppNotification(
                      title: data['title'] ?? '',
                      message: data['message'] ?? '',
                      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
                      idPohon: data['id_data_pohon'] as String?, // Gunakan id_data_pohon untuk navigasi
                    );
                    return _buildNotificationItem(context, notif);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notif) {
    return GestureDetector(
      onTap: notif.idPohon != null
          ? () async {
              // Ambil data pohon berdasarkan idPohon
              final pohon = await _fetchPohon(notif.idPohon!);
              if (pohon != null) {
                // Navigasi ke TreeMappingDetailPage dengan data pohon
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreeMappingDetailPage(pohon: pohon),
                  ),
                );
              } else {
                // Tampilkan pesan jika pohon tidak ditemukan
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data pohon tidak ditemukan')),
                );
              }
            }
          : null, // Tidak ada aksi jika idPohon null
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatDate(notif.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day} ${months[date.month]} ${date.year}';
  }
}