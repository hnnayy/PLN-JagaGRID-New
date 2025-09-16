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
  final String? filterType;

  TreeMappingReportPage({this.filterType});

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

  List<DataPohon> _filterAndSortList(List<DataPohon> pohonList) {
    List<DataPohon> filteredList = List.from(pohonList);

    print('Jumlah data awal sebelum filter: ${pohonList.length}');

    if (filterType == 'high_priority') {
      filteredList = filteredList.where((p) => p.prioritas == 3).toList();
    } else if (filterType == 'medium_priority') {
      filteredList = filteredList.where((p) => p.prioritas == 2).toList();
    } else if (filterType == 'low_priority') {
      filteredList = filteredList.where((p) => p.prioritas == 1).toList();
    } else if (filterType == 'tebang_habis') {
      filteredList = filteredList.where((p) => p.tujuanPenjadwalan == 2).toList();
    } else if (filterType == 'tebang_pangkas') {
      filteredList = filteredList.where((p) => p.tujuanPenjadwalan == 1).toList();
    } else if (filterType == 'total_pohon' || filterType == 'prioritas' || filterType == null) {
      // Tampilkan semua data tanpa filter tambahan
    } else {
      print('FilterType tidak dikenali: $filterType');
    }

    print('Jumlah data setelah filter: ${filteredList.length}');

    if (filterType == null || filterType == 'total_pohon') {
      filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } else {
      filteredList.sort((a, b) => b.prioritas.compareTo(a.prioritas));
    }

    return filteredList;
  }

  String _getTitle() {
    if (filterType == 'high_priority') return 'Laporan Prioritas Tinggi';
    if (filterType == 'medium_priority') return 'Laporan Prioritas Sedang';
    if (filterType == 'low_priority') return 'Laporan Prioritas Rendah';
    if (filterType == 'tebang_habis') return 'Laporan Tebang Habis';
    if (filterType == 'tebang_pangkas') return 'Laporan Tebang Pangkas';
    if (filterType == 'prioritas') return 'Laporan Semua Prioritas';
    return 'Laporan Semua Data Pohon';
  }

  Future<void> _exportToExcel(BuildContext context, List<DataPohon> pohonList) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

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

      final directory = await getTemporaryDirectory();
      final fileName = 'Laporan_Pohon_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor ke Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealGelap,
        title: Text(
          _getTitle(),
          style: const TextStyle(
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
              final filteredList = _filterAndSortList(pohonList);
              if (filteredList.isNotEmpty) {
                await _exportToExcel(context, filteredList);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada data untuk diekspor')),
                );
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
            print('Error snapshot: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('Tidak ada data atau snapshot kosong');
            return const Center(child: Text('Tidak ada data pohon tersedia'));
          }

          final pohonList = _filterAndSortList(snapshot.data!);
          if (pohonList.isEmpty) {
            print('Data kosong setelah filter: filterType = $filterType');
            return const Center(child: Text('Tidak ada data yang sesuai filter'));
          }
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
                          print('Attempting to delete document with ID: ${pohon.id}, idPohon: ${pohon.idPohon}');
                          await _dataPohonService.deleteDataPohon(pohon.id);
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
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Image.asset(
                                'assets/logo/logo.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/logo/logo.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/logo/logo.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                      title: Text(
                        'Pohon ID #${pohon.idPohon} - ${pohon.namaPohon}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lokasi: ${pohon.up3}, ${pohon.ulp}'),
                          Text('Penyulang: ${pohon.penyulang}'),
                          Text('Zona Proteksi: ${pohon.zonaProteksi}'),
                          Text('Section: ${pohon.section}'),
                          Text('KMS Aset: ${pohon.kmsAset}'),
                          Text('Vendor: ${pohon.vendor}'),
                          Text('Prioritas: ${_getPrioritasText(pohon.prioritas)}'),
                          Text('Tujuan: ${_getTujuanPenjadwalanText(pohon.tujuanPenjadwalan)}'),
                          Text('Koordinat: ${pohon.koordinat}'),
                          Text('Tanggal Penjadwalan: ${pohon.scheduleDate.toString().substring(0, 10)}'),
                          Text('Laju Pertumbuhan: ${pohon.growthRate} cm/tahun'),
                          Text('Tinggi Awal: ${pohon.initialHeight} m'),
                          Text('Catatan: ${pohon.catatan.isEmpty ? 'Tidak ada' : pohon.catatan}'),
                          Text('Dibuat Oleh: ${pohon.createdBy}'),
                          Text('Tanggal Dibuat: ${pohon.createdDate.toString().substring(0, 10)}'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const Divider(color: AppColors.cyan, thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}