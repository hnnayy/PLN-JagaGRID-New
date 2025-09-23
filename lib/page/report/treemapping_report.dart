import 'package:flutter/material.dart';
// Removed direct cloud_firestore import (not used in this file)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:io';
import 'treemapping_detail.dart';
import '../../constants/colors.dart';
import '../../models/data_pohon.dart';
import '../../services/data_pohon_service.dart';
import '../../services/user_service.dart';

class TreeMappingReportPage extends StatelessWidget {
  final DataPohonService _dataPohonService = DataPohonService();
  final String? filterType;

  TreeMappingReportPage({this.filterType});

  // In-memory cache for address lines per coordinate
  static final Map<String, List<String>> _geoLinesCache = {};
  // In-memory cache for userId -> name
  static final Map<String, String> _userNameCache = {};

  Future<String> _getUserName(String id) async {
    if (id.isEmpty) return '-';
    final cached = _userNameCache[id];
    if (cached != null) return cached;
    try {
      // Try persistent cache first
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getString('user_name_cache|' + id);
      if (persisted != null && persisted.isNotEmpty) {
        _userNameCache[id] = persisted;
        return persisted;
      }
      final service = UserService();
      final user = await service.getUserById(id);
      final name = (user?.name ?? '').trim();
      if (name.isNotEmpty) {
        _userNameCache[id] = name;
        await prefs.setString('user_name_cache|' + id, name);
        return name;
      }
    } catch (_) {}
    return '-';
  }

  Future<List<String>> _getAddressLinesFromCoords(String koordinat, {String fallback = ''}) async {
    try {
      final key = 'lines|' + koordinat.trim();
      if (key.isEmpty) return fallback.isNotEmpty ? [fallback] : <String>[];
      final cached = _geoLinesCache[key];
      if (cached != null) return cached;

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList('geo_lines_cache|' + key);
      if (persisted != null && persisted.isNotEmpty) {
        _geoLinesCache[key] = persisted;
        return persisted;
      }

      final raw = koordinat.trim();
      final parts = raw.split(',');
      if (parts.length != 2) return fallback.isNotEmpty ? [fallback] : <String>[];
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());

      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return fallback.isNotEmpty ? [fallback] : <String>[];

      final p = placemarks.first;
    // Compose ONLY two lines: subLocality (Kecamatan/Area) and locality (Kota/Kabupaten)
    final subLocality = (p.subLocality ?? '').trim();
    final locality = (p.locality ?? '').trim();

    final lines = <String>[];
    if (subLocality.isNotEmpty) lines.add(subLocality);
    if (locality.isNotEmpty) lines.add(locality);

    // Fallback if both empty
    final result = lines.isNotEmpty
      ? lines
      : (fallback.isNotEmpty ? [fallback] : <String>[]);

      _geoLinesCache[key] = result;
      // Persist for later sessions
      await prefs.setStringList('geo_lines_cache|' + key, result);
      return result;
    } catch (_) {
      return fallback.isNotEmpty ? [fallback] : <String>[];
    }
  }

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

  Future<List<DataPohon>> _filterAndSortList(List<DataPohon> pohonList) async {
    List<DataPohon> filteredList = List.from(pohonList);

    // Ambil level dan unit dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    final sessionUnit = prefs.getString('session_unit') ?? '';

    // Filter berdasarkan level
    if (level == 2) {
      // Ganti 'unit' dengan field yang sesuai di DataPohon
      filteredList = filteredList.where((p) => p.up3 == sessionUnit || p.ulp == sessionUnit).toList();
    }

    print('Jumlah data awal sebelum filter: ${filteredList.length}');

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

    // Terapkan sorting sesuai dengan pilihan statistik pada grid
    if (filterType == null || filterType == 'total_pohon') {
      // Total pohon: terbaru di atas
      filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } else if (filterType == 'high_priority' ||
        filterType == 'medium_priority' ||
        filterType == 'low_priority') {
      // Untuk prioritas spesifik, urutkan berdasarkan tanggal penjadwalan terdekat
      filteredList.sort((a, b) {
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        // Tie-breaker: terbaru di atas
        return b.createdDate.compareTo(a.createdDate);
      });
    } else if (filterType == 'tebang_habis' || filterType == 'tebang_pangkas') {
      // Untuk tujuan penjadwalan, tampilkan prioritas lebih tinggi dulu,
      // lalu tanggal penjadwalan terdekat
      filteredList.sort((a, b) {
        final byPriority = b.prioritas.compareTo(a.prioritas);
        if (byPriority != 0) return byPriority;
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        return b.createdDate.compareTo(a.createdDate);
      });
    } else if (filterType == 'prioritas') {
      // Semua prioritas: urutkan dari tinggi ke rendah, kemudian by scheduleDate
      filteredList.sort((a, b) {
        final byPriority = b.prioritas.compareTo(a.prioritas);
        if (byPriority != 0) return byPriority;
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        return b.createdDate.compareTo(a.createdDate);
      });
    } else {
      // Default fallback: terbaru di atas
      filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
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
        final creatorName = await _getUserName(pohon.createdBy.toString());
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
          creatorName,
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _getTitle(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Color.fromARGB(255, 255, 255, 255)),
            tooltip: 'Ekspor ke Excel',
            onPressed: () async {
              final pohonList = await _dataPohonService.getAllDataPohon().first;
              final filteredList = await _filterAndSortList(pohonList);
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

          return FutureBuilder<List<DataPohon>>(
            future: _filterAndSortList(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                print('Error filter: ${futureSnapshot.error}');
                return Center(child: Text('Error: ${futureSnapshot.error}'));
              }
              final pohonList = futureSnapshot.data ?? [];
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
                            'Pohon ID #${pohon.idPohon}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Gunakan subtitle gaya "Total Pohon" untuk semua filter (kecuali Sistem Repetisi yang tidak masuk ke halaman ini)
                          subtitle: FutureBuilder<List<String>>(
                            future: _getAddressLinesFromCoords(pohon.koordinat, fallback: pohon.up3),
                            builder: (context, snap) {
                              final lines = (snap.data == null || snap.data!.isEmpty) ? [pohon.up3] : snap.data!;
                              // Maksimal dua baris lokasi
                              final line1 = lines.isNotEmpty ? lines[0] : pohon.up3;
                              final line2 = lines.length > 1 ? lines[1] : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lokasi: $line1'),
                                  if (line2 != null) Text(line2),
                                ],
                              );
                            },
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
          );
        },
      ),
    );
  }
}