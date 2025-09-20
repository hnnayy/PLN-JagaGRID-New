import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../constants/colors.dart';

class RiwayatEksekusiPage extends StatelessWidget {
  final DataPohon pohon;

  const RiwayatEksekusiPage({super.key, required this.pohon});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
            'Riwayat Eksekusi - Pohon ID #${pohon.idPohon}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Eksekusi>>(
          stream: FirebaseFirestore.instance
              .collection('eksekusi')
              .where('data_pohon_id', isEqualTo: pohon.id)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => Eksekusi.fromMap({...doc.data(), 'id': doc.id}))
                  .toList()
                  // Sort client-side to avoid requiring a composite index
                  ..sort((a, b) => b.createdDate.compareTo(a.createdDate))),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final eksekusiList = snapshot.data ?? [];
            if (eksekusiList.isEmpty) {
              return const Center(child: Text('Tidak ada riwayat eksekusi'));
            }

            // Sinkronisasi ringkasan (jumlah & eksekusi terakhir) supaya sama dengan management page
            final total = eksekusiList.length;
            // Karena sudah orderBy createddate desc, index 0 adalah terbaru
            final latestDate = _formatDate(eksekusiList.first.tanggalEksekusi);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jumlah Eksekusi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Eksekusi Terakhir', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(latestDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: eksekusiList.length,
                    itemBuilder: (context, index) {
                      final eksekusi = eksekusiList[index];
                Color statusColor;
                String aksiText;
                switch (eksekusi.statusEksekusi) {
                  case 1: // Tebang Pangkas
                    statusColor = Colors.green;
                    aksiText = 'Pemangkasan';
                    break;
                  case 2: // Tebang Habis
                    statusColor = Colors.red;
                    aksiText = 'Penebangan';
                    break;
                  default:
                    statusColor = Colors.orange; // Should not occur due to validations
                    aksiText = 'Tidak Diketahui';
                }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                          title: Text(
                            'Tanggal Eksekusi: ${_formatDate(eksekusi.tanggalEksekusi)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Aksi:'),
                                      Text(
                                        aksiText,
                                        style: TextStyle(fontSize: screenWidth * 0.035),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tinggi Pohon:'),
                                      Text(
                                        '${eksekusi.tinggiPohon} cm',
                                        style: TextStyle(fontSize: screenWidth * 0.035),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Diameter:'),
                                      Text(
                                        '${eksekusi.diameterPohon} cm',
                                        style: TextStyle(fontSize: screenWidth * 0.035),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Status:'),
                                      Text(
                                        eksekusi.status == 1 ? 'Selesai' : 'Berjalan',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (eksekusi.fotoSetelah != null) ...[
                                    const Text('Foto Setelah Eksekusi:'),
                                    const SizedBox(height: 8),
                                    Image.network(
                                      eksekusi.fotoSetelah!,
                                      fit: BoxFit.cover,
                                      height: screenHeight * 0.2,
                                      width: screenWidth * 0.8,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Text('Gambar tidak tersedia'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String tanggalEksekusi) {
    // tanggalEksekusi is in format "DD/MM/YYYY HH:MM WITA"
    // Extract the date part (DD/MM/YYYY) for display
    final parts = tanggalEksekusi.split(' ');
    return parts[0]; // Returns DD/MM/YYYY (e.g., 06/09/2025)
  }
}