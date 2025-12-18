import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart' hide Border;
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  TreeMappingReportPage({this.filterType});

  static final Map<String, List<String>> _geoLinesCache = {};
  static final Map<String, String> _userNameCache = {};

  Future<String> _getUserName(String id) async {
    if (id.isEmpty) return '-';
    final cached = _userNameCache[id];
    if (cached != null) return cached;
    try {
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
      final subLocality = (p.subLocality ?? '').trim();
      final locality = (p.locality ?? '').trim();

      final lines = <String>[];
      if (subLocality.isNotEmpty) lines.add(subLocality);
      if (locality.isNotEmpty) lines.add(locality);

      final result = lines.isNotEmpty
          ? lines
          : (fallback.isNotEmpty ? [fallback] : <String>[]);

      _geoLinesCache[key] = result;
      await prefs.setStringList('geo_lines_cache|' + key, result);
      return result;
    } catch (_) {
      return fallback.isNotEmpty ? [fallback] : <String>[];
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String idPohon) async {
    print('Showing delete confirmation dialog for Pohon ID #$idPohon');
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data pohon ID #$idPohon?'),
        actions: [
          TextButton(
            onPressed: () {
              print('User cancelled deletion for Pohon ID #$idPohon');
              Navigator.pop(context, false);
            },
            child: const Text('Batal', style: TextStyle(color: AppColors.tealGelap)),
          ),
          TextButton(
            onPressed: () {
              print('User confirmed deletion for Pohon ID #$idPohon');
              Navigator.pop(context, true);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessAlert(BuildContext context, String idPohon) async {
    print('Attempting to show success alert for Pohon ID #$idPohon');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Builder(
        builder: (innerContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E5D6F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 55,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Berhasil!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5D6F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Data pohon ID #$idPohon berhasil dihapus",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5D6F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      print('Success alert OK button pressed for Pohon ID #$idPohon');
                      Navigator.of(innerContext).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    print('Success alert displayed and closed for Pohon ID #$idPohon');
  }

  Future<void> _showErrorAlert(BuildContext context, String errorMessage) async {
    print('Attempting to show error alert: $errorMessage');
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Builder(
        builder: (innerContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Gagal!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Gagal menghapus data: $errorMessage",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      print('Error alert OK button pressed');
                      Navigator.of(innerContext).pop();
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    print('Error alert displayed and closed');
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

    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    final sessionUnit = prefs.getString('session_unit') ?? '';

    if (level == 2) {
      filteredList = filteredList.where((p) => p.up3 == sessionUnit || p.ulp == sessionUnit).toList();
    }

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
    }

    if (filterType == null || filterType == 'total_pohon') {
      filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } else if (filterType == 'high_priority' ||
        filterType == 'medium_priority' ||
        filterType == 'low_priority') {
      filteredList.sort((a, b) {
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        return b.createdDate.compareTo(a.createdDate);
      });
    } else if (filterType == 'tebang_habis' || filterType == 'tebang_pangkas') {
      filteredList.sort((a, b) {
        final byPriority = b.prioritas.compareTo(a.prioritas);
        if (byPriority != 0) return byPriority;
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        return b.createdDate.compareTo(a.createdDate);
      });
    } else if (filterType == 'prioritas') {
      filteredList.sort((a, b) {
        final byPriority = b.prioritas.compareTo(a.prioritas);
        if (byPriority != 0) return byPriority;
        final bySchedule = a.scheduleDate.compareTo(b.scheduleDate);
        if (bySchedule != 0) return bySchedule;
        return b.createdDate.compareTo(a.createdDate);
      });
    } else {
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
      print('Error exporting to Excel: $e');
      await _showErrorAlert(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Builder(
        builder: (innerContext) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.tealGelap,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _getTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.white),
                tooltip: 'Ekspor ke Excel',
                onPressed: () async {
                  print('Export to Excel triggered');
                  final pohonList = await _dataPohonService.getAllDataPohon().first;
                  final filteredList = await _filterAndSortList(pohonList);
                  if (filteredList.isNotEmpty) {
                    await _exportToExcel(innerContext, filteredList);
                  } else {
                    print('No data to export');
                    await _showErrorAlert(innerContext, 'Tidak ada data untuk diekspor');
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<List<DataPohon>>(
            stream: _dataPohonService.getAllDataPohon(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('StreamBuilder: Waiting for data');
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('StreamBuilder: Error - ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print('StreamBuilder: No data or empty snapshot');
                return const Center(child: Text('Tidak ada data pohon tersedia'));
              }

              return FutureBuilder<List<DataPohon>>(
                future: _filterAndSortList(snapshot.data!),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState == ConnectionState.waiting) {
                    print('FutureBuilder: Waiting for filtered data');
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (futureSnapshot.hasError) {
                    print('FutureBuilder: Error - ${futureSnapshot.error}');
                    return Center(child: Text('Error: ${futureSnapshot.error}'));
                  }
                  final pohonList = futureSnapshot.data ?? [];
                  if (pohonList.isEmpty) {
                    print('FutureBuilder: Empty data after filter, filterType = $filterType');
                    return const Center(child: Text('Tidak ada data yang sesuai filter'));
                  }
                  print('Building ListView with ${pohonList.length} items');
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
                              print('Dismissible triggered for Pohon ID #${pohon.idPohon}');
                              final confirmed = await _showDeleteConfirmationDialog(innerContext, pohon.idPohon);
                              if (confirmed == true) {
                                try {
                                  print('Attempting to delete document with ID: ${pohon.id}, idPohon: ${pohon.idPohon}');
                                  if (pohon.id == null || pohon.id.isEmpty) {
                                    print('Invalid document ID: ${pohon.id}');
                                    await _showErrorAlert(innerContext, 'ID dokumen tidak valid');
                                    return false;
                                  }
                                  await _dataPohonService.deleteDataPohon(pohon.id);
                                  print('Deletion successful for Pohon ID #${pohon.idPohon}');
                                  await _showSuccessAlert(innerContext, pohon.idPohon);
                                  return true;
                                } catch (e) {
                                  print('Error deleting Pohon ID #${pohon.idPohon}: $e');
                                  await _showErrorAlert(innerContext, e.toString());
                                  return false;
                                }
                              }
                              print('Deletion cancelled for Pohon ID #${pohon.idPohon}');
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
                              subtitle: FutureBuilder<List<String>>(
                                future: _getAddressLinesFromCoords(pohon.koordinat, fallback: pohon.up3),
                                builder: (context, snap) {
                                  final lines = (snap.data == null || snap.data!.isEmpty) ? [pohon.up3] : snap.data!;
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
                                print('Navigating to detail page for Pohon ID #${pohon.idPohon}');
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
        ),
      ),
    );
  }
}