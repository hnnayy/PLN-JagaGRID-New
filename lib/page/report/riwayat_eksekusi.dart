import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatEksekusiPage extends StatelessWidget {
  final DataPohon pohon;

  const RiwayatEksekusiPage({super.key, required this.pohon});

  // ─────────────────────────────────────────────
  // Fullscreen image viewer
  // ─────────────────────────────────────────────
  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Foto fullscreen + bisa zoom/pan
            InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),

            // Tombol silang tutup
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Riwayat Eksekusi #${pohon.idPohon}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: FutureBuilder<bool>(
        future: _isAllowed(),
        builder: (context, perm) {
          if (perm.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (perm.hasError || perm.data != true) {
            return const Center(child: Text('Akses ditolak untuk pohon ini'));
          }

          return StreamBuilder<List<Eksekusi>>(
            stream: FirebaseFirestore.instance
                .collection('eksekusi')
                .where('data_pohon_id', isEqualTo: pohon.id)
                .snapshots()
                .map((snapshot) => snapshot.docs
                    .map((doc) =>
                        Eksekusi.fromMap({...doc.data(), 'id': doc.id}))
                    .toList()
                  ..sort((a, b) =>
                      b.createdDate.compareTo(a.createdDate))),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final eksekusiList = snapshot.data ?? [];

              if (eksekusiList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat eksekusi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final total = eksekusiList.length;
              final latest = eksekusiList.first;
              final latestTipe = latest.statusEksekusi == 1
                  ? 'Tebang Pangkas'
                  : 'Tebang Habis';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Summary Card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF125E72), Color(0xFF14A2B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryItem(
                            'Total Eksekusi',
                            '$total kali',
                            Icons.repeat,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3)),
                        Expanded(
                          child: _summaryItem(
                            'Terakhir',
                            _formatDateShort(latest.tanggalEksekusi),
                            Icons.calendar_today,
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3)),
                        Expanded(
                          child: _summaryItem(
                            'Tipe',
                            latestTipe,
                            Icons.content_cut,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── List Riwayat ──
                  ...eksekusiList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final eksekusi = entry.value;
                    final nomorEksekusi = total - index;
                    final isTebangPangkas = eksekusi.statusEksekusi == 1;
                    final tipeColor =
                        isTebangPangkas ? Colors.green : Colors.red;
                    final tipeText =
                        isTebangPangkas ? 'Tebang Pangkas' : 'Tebang Habis';
                    final tipeIcon =
                        isTebangPangkas ? Icons.content_cut : Icons.park;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header card ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF125E72),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Eksekusi #$nomorEksekusi${index == 0 ? " (Terkini)" : ""}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tipeColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(tipeIcon,
                                          size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        tipeText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Foto setelah eksekusi ──
                          if (eksekusi.fotoSetelah != null &&
                              eksekusi.fotoSetelah!.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.camera_alt,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Foto Setelah Eksekusi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // ── FOTO DENGAN GESTURE TAP ──
                                  GestureDetector(
                                    onTap: () => _showFullscreenImage(
                                        context, eksekusi.fotoSetelah!),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: eksekusi.fotoSetelah!,
                                            width: double.infinity,
                                            height: 220,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 220,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: 220,
                                              color: Colors.grey[200],
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.broken_image,
                                                      color: Colors.grey[400],
                                                      size: 40),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Foto tidak tersedia',
                                                    style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // ── Icon zoom di pojok kanan bawah foto ──
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.zoom_in,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Hint ketuk ──
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app,
                                          size: 12, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ketuk foto untuk memperbesar',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── Detail info ──
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              children: [
                                _detailRow(
                                  Icons.calendar_today,
                                  'Tanggal Eksekusi',
                                  eksekusi.tanggalEksekusi,
                                ),
                                const SizedBox(height: 8),
                                _detailRow(
                                  Icons.height,
                                  'Tinggi Setelah Eksekusi',
                                  '${eksekusi.tinggiPohon} m',
                                ),
                                const SizedBox(height: 8),
                                _detailRow(
                                  Icons.circle_outlined,
                                  'Diameter Pohon',
                                  '${eksekusi.diameterPohon} cm',
                                ),
                                const SizedBox(height: 8),
                                _detailRow(
                                  Icons.check_circle_outline,
                                  'Status',
                                  eksekusi.status == 1 ? 'Selesai' : 'Berjalan',
                                  valueColor: eksekusi.status == 1
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helper widgets
  // ─────────────────────────────────────────────
  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF125E72)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDateShort(String tanggalEksekusi) {
    final parts = tanggalEksekusi.split(' ');
    return parts[0];
  }

  Future<bool> _isAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';
      if (level == 2) {
        return pohon.up3 == sessionUnit || pohon.ulp == sessionUnit;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}