import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'treemapping_detail.dart';
import '../../constants/colors.dart';
import '../../models/data_pohon.dart';
import '../../services/data_pohon_service.dart';

class TreeMappingReportPage extends StatelessWidget {
  final DataPohonService _dataPohonService = DataPohonService();

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String idPohon) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data pohon ID #$idPohon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.tealGelap)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mengonversi prioritas ke teks
  String _getPrioritasText(int prioritas) {
    switch (prioritas) {
      case 1:
        return 'Rendah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Tinggi';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Fungsi untuk mengonversi tujuan penjadwalan ke teks
  String _getTujuanPenjadwalanText(int tujuan) {
    switch (tujuan) {
      case 1:
        return 'Tebang Pangkas';
      case 2:
        return 'Tebang Habis';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Fungsi untuk membuat dan menyimpan file Excel
  Future<void> _exportToExcel(BuildContext context, List<DataPohon> pohonList) async {
    try {
      // Buat instance Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // Tambahkan header sesuai dengan field DataPohon (tanpa Parent ID, Unit ID, Aset JTM ID, Tanggal Notifikasi)
      sheet.appendRow([
        'ID',
        'ID Pohon',
        'UP3',
        'ULP',
        'Penyulang',
        'Zona Proteksi',
        'Section',
        'KMS Aset',
        'Vendor',
        'Tanggal Penjadwalan',
        'Prioritas',
        'Nama Pohon',
        'Foto Pohon',
        'Koordinat',
        'Tujuan Penjadwalan',
        'Catatan',
        'Dibuat Oleh',
        'Tanggal Dibuat',
        'Laju Pertumbuhan (cm/tahun)',
        'Tinggi Awal (m)',
      ]);

      // Tambahkan data pohon
      for (var pohon in pohonList) {
        sheet.appendRow([
          pohon.id,
          pohon.idPohon,
          pohon.up3,
          pohon.ulp,
          pohon.penyulang,
          pohon.zonaProteksi,
          pohon.section,
          pohon.kmsAset,
          pohon.vendor,
          pohon.scheduleDate.toIso8601String(),
          _getPrioritasText(pohon.prioritas),
          pohon.namaPohon,
          pohon.fotoPohon,
          pohon.koordinat,
          _getTujuanPenjadwalanText(pohon.tujuanPenjadwalan),
          pohon.catatan,
          pohon.createdBy.toString(),
          pohon.createdDate.toIso8601String(),
          pohon.growthRate.toString(),
          pohon.initialHeight.toString(),
        ]);
      }

      // Tentukan path penyimpanan
      final directory = await getTemporaryDirectory();
      final fileName = 'Laporan_Pohon_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Simpan file Excel
      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      // Buka file dengan aplikasi default
      await OpenFile.open(filePath);
    } catch (e) {
      // Tidak menampilkan alert untuk error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealGelap,
        title: Text(
          'Laporan Peta Pohon',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppColors.yellow),
            tooltip: 'Ekspor ke Excel',
            onPressed: () async {
              final pohonList = await _dataPohonService.getAllDataPohon().first;
              if (pohonList.isNotEmpty) {
                await _exportToExcel(context, pohonList);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DataPohon>>(
        stream: _dataPohonService.getAllDataPohon(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data pohon tersedia'));
          }

          final pohonList = snapshot.data!;
          return ListView.builder(
            itemCount: pohonList.length,
            itemBuilder: (context, index) {
              final pohon = pohonList[index];
              return Column(
                children: [
                  Dismissible(
                    key: Key(pohon.idPohon),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      final confirmed = await _showDeleteConfirmationDialog(context, pohon.idPohon);
                      if (confirmed == true) {
                        try {
                          await _dataPohonService.deleteDataPohon(pohon.idPohon);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pohon ID #${pohon.idPohon} berhasil dihapus')),
                          );
                          return true;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menghapus data: $e')),
                          );
                          return false;
                        }
                      }
                      return false;
                    },
                    child: ListTile(
                      leading: pohon.fotoPohon.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: pohon.fotoPohon,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Image.asset(
                                'assets/logo/logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/logo/logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(
                              'assets/logo/logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                      title: Text(
                        'Pohon ID #${pohon.idPohon}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: Text(
                        'Lokasi: ${pohon.up3}, ${pohon.ulp}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TreeMappingDetailPage(pohon: pohon),
                          ),
                        );
                      },
                    ),
                  ),
                  if (index < pohonList.length - 1)
                    Divider(color: AppColors.cyan, thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}