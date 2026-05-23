import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../models/data_pohon.dart';
import '../report/treemapping_detail.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<Map<String, dynamic>> _getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'session_level': prefs.getInt('session_level') ?? 2,
      'session_unit': prefs.getString('session_unit') ?? '',
      'session_id': prefs.getString('session_id') ?? '',
    };
  }

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

  // ─────────────────────────────────────────
  // Tentukan icon, warna, dan tipe notif
  // berdasarkan judul notifikasi
  // ─────────────────────────────────────────
  _NotifStyle _getNotifStyle(String title) {
    final t = title.toLowerCase();

    // Eksekusi selesai (tebang pangkas / tebang habis)
    if (t.contains('pangkas') || t.contains('eksekusi selesai')) {
      return _NotifStyle(
        icon: Icons.content_cut,
        bgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        label: 'Eksekusi',
      );
    }

    // Tebang habis
    if (t.contains('habis') || t.contains('dihapus')) {
      return _NotifStyle(
        icon: Icons.delete_forever,
        bgColor: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFC62828),
        label: 'Tebang Habis',
      );
    }

    // Pohon baru ditambahkan
    if (t.contains('baru') || t.contains('ditambahkan')) {
      return _NotifStyle(
        icon: Icons.park,
        bgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        label: 'Pohon Baru',
      );
    }

    // Reminder / H-3
    if (t.contains('reminder') || t.contains('perawatan') ||
        t.contains('penebangan')) {
      return _NotifStyle(
        icon: Icons.alarm,
        bgColor: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFF57F17),
        label: 'Reminder',
      );
    }

    // Prediksi / pertumbuhan
    if (t.contains('prediksi') || t.contains('pertumbuhan')) {
      return _NotifStyle(
        icon: Icons.trending_up,
        bgColor: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF283593),
        label: 'Prediksi',
      );
    }

    // Default
    return _NotifStyle(
      icon: Icons.notifications,
      bgColor: const Color(0xFFF5F5F5),
      iconColor: const Color(0xFF616161),
      label: 'Info',
    );
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
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
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

          final sessionData = sessionSnapshot.data ??
              {'session_level': 2, 'session_unit': '', 'session_id': ''};
          final sessionLevel = sessionData['session_level'] as int;
          final sessionUnit = sessionData['session_unit'] as String;

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notification')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Terjadi kesalahan mengambil notifikasi'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> docs =
                    snapshot.data?.docs ?? [];

                // Filter berdasarkan level
                if (sessionLevel == 2) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ulp = (data['ulp'] as String? ?? '')
                        .trim()
                        .toLowerCase();
                    return ulp == sessionUnit.trim().toLowerCase();
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada notifikasi',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // Group notif by tanggal
                final grouped = _groupByDate(docs);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final group = grouped[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label tanggal
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 4, bottom: 8, top: 4),
                          child: Text(
                            group['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // List notif di tanggal ini
                        ...(group['items'] as List<QueryDocumentSnapshot>)
                            .map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          DateTime parsedDate = DateTime.now();
                          final createdAt = data['created_at'];
                          if (createdAt is Timestamp) {
                            parsedDate = createdAt.toDate();
                          } else {
                            parsedDate =
                                DateTime.tryParse(data['date'] ?? '') ??
                                    DateTime.now();
                          }
                          final notif = AppNotification(
                            title: data['title'] ?? '',
                            message: data['message'] ?? '',
                            date: parsedDate,
                            idPohon: data['id_data_pohon'] as String?,
                          );
                          return _buildNotificationItem(context, notif);
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Group notif berdasarkan tanggal
  List<Map<String, dynamic>> _groupByDate(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime date = DateTime.now();
      final createdAt = data['created_at'];
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final docDate = DateTime(date.year, date.month, date.day);

      String label;
      if (docDate == today) {
        label = 'Hari Ini';
      } else if (docDate == yesterday) {
        label = 'Kemarin';
      } else {
        final months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        label = '${date.day} ${months[date.month]} ${date.year}';
      }

      grouped.putIfAbsent(label, () => []).add(doc);
    }

    return grouped.entries
        .map((e) => {'label': e.key, 'items': e.value})
        .toList();
  }

  Widget _buildNotificationItem(
      BuildContext context, AppNotification notif) {
    final style = _getNotifStyle(notif.title);

    return GestureDetector(
      onTap: notif.idPohon != null
          ? () async {
              final pohon = await _fetchPohon(notif.idPohon!);
              if (pohon != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TreeMappingDetailPage(pohon: pohon),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Data pohon tidak ditemukan')),
                );
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon dengan warna sesuai tipe
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge tipe + judul
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: style.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: style.iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tap untuk detail
                      if (notif.idPohon != null)
                        Text(
                          'Tap untuk lihat detail →',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade400,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _formatTime(notif.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Model style per tipe notif
class _NotifStyle {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String label;

  const _NotifStyle({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.label,
  });
}