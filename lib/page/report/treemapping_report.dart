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

class TreeMappingReportPage extends StatefulWidget {
  final String? filterType;

  const TreeMappingReportPage({super.key, this.filterType});

  @override
  State<TreeMappingReportPage> createState() => _TreeMappingReportPageState();
}

class _TreeMappingReportPageState extends State<TreeMappingReportPage> {
  final DataPohonService _dataPohonService = DataPohonService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // ── Filter state ──
  DateTime _selectedMonth = DateTime.now();
  bool _filterBySpecificDate = false;
  DateTime? _specificDate;
  String _searchQuery = '';
  int? _filterPrioritas;
  int? _filterTujuan;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  static final Map<String, List<String>> _geoLinesCache = {};
  static final Map<String, String> _userNameCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getUserName(String id) async {
    if (id.isEmpty) return '-';
    final cached = _userNameCache[id];
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getString('user_name_cache|$id');
      if (persisted != null && persisted.isNotEmpty) {
        _userNameCache[id] = persisted;
        return persisted;
      }
      final service = UserService();
      final user = await service.getUserById(id);
      final name = (user?.name ?? '').trim();
      if (name.isNotEmpty) {
        _userNameCache[id] = name;
        await prefs.setString('user_name_cache|$id', name);
        return name;
      }
    } catch (_) {}
    return '-';
  }

  Future<List<String>> _getAddressLinesFromCoords(String koordinat,
      {String fallback = ''}) async {
    try {
      final key = 'lines|${koordinat.trim()}';
      final cached = _geoLinesCache[key];
      if (cached != null) return cached;

      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList('geo_lines_cache|$key');
      if (persisted != null && persisted.isNotEmpty) {
        _geoLinesCache[key] = persisted;
        return persisted;
      }

      final raw = koordinat.trim();
      final parts = raw.split(',');
      if (parts.length != 2) return fallback.isNotEmpty ? [fallback] : [];
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());

      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return fallback.isNotEmpty ? [fallback] : [];

      final p = placemarks.first;
      final lines = <String>[];
      if ((p.subLocality ?? '').trim().isNotEmpty)
        lines.add(p.subLocality!.trim());
      if ((p.locality ?? '').trim().isNotEmpty) lines.add(p.locality!.trim());

      // ✅ DIUBAH: eksplisit tipe List<String> biar tidak error type mismatch
      final List<String> result =
          lines.isNotEmpty ? lines : (fallback.isNotEmpty ? [fallback] : []);
      _geoLinesCache[key] = result;
      await prefs.setStringList('geo_lines_cache|$key', result);
      return result;
    } catch (_) {
      return fallback.isNotEmpty ? [fallback] : [];
    }
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
        return '-';
    }
  }

  String _getTujuanText(int tujuan) {
    switch (tujuan) {
      case 1:
        return 'Tebang Pangkas';
      case 2:
        return 'Tebang Habis';
      default:
        return '-';
    }
  }

  String _getTitle() {
    if (widget.filterType == 'high_priority') return 'Laporan Prioritas Tinggi';
    if (widget.filterType == 'medium_priority')
      return 'Laporan Prioritas Sedang';
    if (widget.filterType == 'low_priority') return 'Laporan Prioritas Rendah';
    if (widget.filterType == 'tebang_habis') return 'Laporan Tebang Habis';
    if (widget.filterType == 'tebang_pangkas') return 'Laporan Tebang Pangkas';
    return 'Laporan Semua Data Pohon';
  }

  // ── Filter & sort ──
  Future<List<DataPohon>> _filterAndSortList(List<DataPohon> pohonList) async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    // ✅ DIUBAH: sudah UPPERCASE dari login, tapi trim() lagi untuk keamanan
    final sessionUnit = (prefs.getString('session_unit') ?? '').trim().toUpperCase();

    List<DataPohon> list = List.from(pohonList);

    // ✅ DIUBAH: filter pakai toUpperCase + trim agar konsisten meski format data beda
    if (level == 2) {
      list = list
          .where((p) =>
              p.up3.trim().toUpperCase() == sessionUnit ||
              p.ulp.trim().toUpperCase() == sessionUnit)
          .toList();
    }

    // Filter periode
    list = list.where((p) {
      if (_filterBySpecificDate && _specificDate != null) {
        return p.scheduleDate.year == _specificDate!.year &&
            p.scheduleDate.month == _specificDate!.month &&
            p.scheduleDate.day == _specificDate!.day;
      } else {
        return p.scheduleDate.year == _selectedMonth.year &&
            p.scheduleDate.month == _selectedMonth.month;
      }
    }).toList();

    // Filter prioritas
    if (_filterPrioritas != null) {
      list = list.where((p) => p.prioritas == _filterPrioritas).toList();
    }

    // Filter tujuan
    if (_filterTujuan != null) {
      list = list.where((p) => p.tujuanPenjadwalan == _filterTujuan).toList();
    }

    // Filter filterType dari parent
    if (widget.filterType == 'high_priority') {
      list = list.where((p) => p.prioritas == 3).toList();
    } else if (widget.filterType == 'medium_priority') {
      list = list.where((p) => p.prioritas == 2).toList();
    } else if (widget.filterType == 'low_priority') {
      list = list.where((p) => p.prioritas == 1).toList();
    } else if (widget.filterType == 'tebang_habis') {
      list = list.where((p) => p.tujuanPenjadwalan == 2).toList();
    } else if (widget.filterType == 'tebang_pangkas') {
      list = list.where((p) => p.tujuanPenjadwalan == 1).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.idPohon.toLowerCase().contains(q) ||
            p.namaPohon.toLowerCase().contains(q) ||
            p.ulp.toLowerCase().contains(q) ||
            p.penyulang.toLowerCase().contains(q);
      }).toList();
    }

    // Sort
    list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return list;
  }

  // ── Export Excel ──
  Future<void> _exportToExcel(
      BuildContext context, List<DataPohon> pohonList) async {
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
          pohon.koordinat,
          _getTujuanText(pohon.tujuanPenjadwalan),
          pohon.catatan,
          creatorName,
          pohon.createdDate.toIso8601String(),
          pohon.growthRate.toString(),
          pohon.initialHeight.toString(),
        ]);
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'Laporan_Pohon_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final fileBytes = excel.encode();
      await File(filePath).writeAsBytes(fileBytes!);
      await OpenFile.open(filePath);
    } catch (e) {
      await _showErrorAlert(context, e.toString());
    }
  }

  // ── Dialogs ──
  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, String idPohon) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus data pohon ID #$idPohon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.tealGelap)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessAlert(
      BuildContext context, String idPohon) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E5D6F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    size: 55, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Berhasil!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5D6F))),
              const SizedBox(height: 10),
              Text('Data pohon ID #$idPohon berhasil dihapus',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showErrorAlert(
      BuildContext context, String errorMessage) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                    color: Colors.red.shade600, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Gagal!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600)),
              const SizedBox(height: 10),
              Text('Gagal: $errorMessage',
                  style:
                      TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter bottom sheet ──
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Prioritas',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('Semua', _filterPrioritas == null, () {
                        setModalState(() => _filterPrioritas = null);
                        setState(() => _filterPrioritas = null);
                      }),
                      _filterChip('Rendah', _filterPrioritas == 1, () {
                        setModalState(() => _filterPrioritas = 1);
                        setState(() => _filterPrioritas = 1);
                      }),
                      _filterChip('Sedang', _filterPrioritas == 2, () {
                        setModalState(() => _filterPrioritas = 2);
                        setState(() => _filterPrioritas = 2);
                      }),
                      _filterChip('Tinggi', _filterPrioritas == 3, () {
                        setModalState(() => _filterPrioritas = 3);
                        setState(() => _filterPrioritas = 3);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Tujuan Penjadwalan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('Semua', _filterTujuan == null, () {
                        setModalState(() => _filterTujuan = null);
                        setState(() => _filterTujuan = null);
                      }),
                      _filterChip('Tebang Pangkas', _filterTujuan == 1, () {
                        setModalState(() => _filterTujuan = 1);
                        setState(() => _filterTujuan = 1);
                      }),
                      _filterChip('Tebang Habis', _filterTujuan == 2, () {
                        setModalState(() => _filterTujuan = 2);
                        setState(() => _filterTujuan = 2);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E5D6F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E5D6F) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Pilih bulan ──
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Bulan',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNames = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
                    ];
                    final isSelected = !_filterBySpecificDate &&
                        _selectedMonth.month == index + 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMonth =
                              DateTime(_selectedMonth.year, index + 1, 1);
                          _filterBySpecificDate = false;
                          _specificDate = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2E5D6F)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          monthNames[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getPeriodeText() {
    if (_filterBySpecificDate && _specificDate != null) {
      return _formatFullDate(_specificDate!);
    }
    return _formatMonthYear(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Builder(
        builder: (innerContext) => Scaffold(
          backgroundColor: const Color(0xFF2E5D6F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E5D6F),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _getPeriodeText(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.white),
                tooltip: 'Ekspor ke Excel',
                onPressed: () async {
                  final pohonList =
                      await _dataPohonService.getAllDataPohon().first;
                  final filteredList = await _filterAndSortList(pohonList);
                  if (filteredList.isNotEmpty) {
                    await _exportToExcel(innerContext, filteredList);
                  } else {
                    await _showErrorAlert(
                        innerContext, 'Tidak ada data untuk diekspor');
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // ── Filter Bar ──
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari ID pohon, nama, ULP, penyulang...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _showMonthPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.black.withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        size: 18, color: Color(0xFF2E5D6F)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getPeriodeText(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _specificDate ?? _selectedMonth,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  _specificDate = picked;
                                  _selectedMonth = picked;
                                  _filterBySpecificDate = true;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _filterBySpecificDate
                                    ? const Color(0xFF2E5D6F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: _filterBySpecificDate
                                    ? Colors.white
                                    : const Color(0xFF2E5D6F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _showFilterSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: (_filterPrioritas != null ||
                                        _filterTujuan != null)
                                    ? const Color(0xFF2E5D6F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Icon(
                                Icons.tune,
                                size: 18,
                                color: (_filterPrioritas != null ||
                                        _filterTujuan != null)
                                    ? Colors.white
                                    : const Color(0xFF2E5D6F),
                              ),
                            ),
                          ),
                          if (_filterBySpecificDate ||
                              _filterPrioritas != null ||
                              _filterTujuan != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _filterBySpecificDate = false;
                                  _specificDate = null;
                                  _filterPrioritas = null;
                                  _filterTujuan = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.refresh,
                                    size: 18, color: Colors.red.shade400),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── List ──
                Expanded(
                  child: StreamBuilder<List<DataPohon>>(
                    stream: _dataPohonService.getAllDataPohon(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('Tidak ada data pohon tersedia'));
                      }

                      return FutureBuilder<List<DataPohon>>(
                        future: _filterAndSortList(snapshot.data!),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final pohonList = futureSnapshot.data ?? [];

                          if (pohonList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada data yang sesuai filter',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(
                                  children: [
                                    Text(
                                      '${pohonList.length} pohon ditemukan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  itemCount: pohonList.length,
                                  itemBuilder: (context, index) {
                                    final pohon = pohonList[index];
                                    return Dismissible(
                                      key: Key(pohon.idPohon),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        final confirmed =
                                            await _showDeleteConfirmationDialog(
                                                innerContext, pohon.idPohon);
                                        if (confirmed == true) {
                                          try {
                                            await _dataPohonService
                                                .deleteDataPohon(pohon.id);
                                            await _showSuccessAlert(
                                                innerContext, pohon.idPohon);
                                            return true;
                                          } catch (e) {
                                            await _showErrorAlert(
                                                innerContext, e.toString());
                                            return false;
                                          }
                                        }
                                        return false;
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                          leading: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: pohon.fotoPohon.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: pohon.fotoPohon,
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        Container(
                                                            width: 56,
                                                            height: 56,
                                                            color: Colors.grey
                                                                .shade200),
                                                    errorWidget: (_, __, ___) =>
                                                        Image.asset(
                                                      'assets/logo/logo.png',
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/logo/logo.png',
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          title: Text(
                                            'Pohon ID #${pohon.idPohon}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<List<String>>(
                                                future:
                                                    _getAddressLinesFromCoords(
                                                        pohon.koordinat,
                                                        fallback: pohon.up3),
                                                builder: (context, snap) {
                                                  final lines = (snap.data ==
                                                              null ||
                                                          snap.data!.isEmpty)
                                                      ? [pohon.up3]
                                                      : snap.data!;
                                                  return Text(
                                                    'Lokasi: ${lines.join(', ')}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: pohon.prioritas ==
                                                              1
                                                          ? Colors
                                                              .green.shade100
                                                          : pohon.prioritas ==
                                                                  2
                                                              ? Colors.orange
                                                                  .shade100
                                                              : Colors
                                                                  .red.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      _getPrioritasText(
                                                          pohon.prioritas),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: pohon.prioritas ==
                                                                1
                                                            ? Colors
                                                                .green.shade700
                                                            : pohon.prioritas ==
                                                                    2
                                                                ? Colors.orange
                                                                    .shade700
                                                                : Colors
                                                                    .red.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFE3F2FD),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      _getTujuanText(pohon
                                                          .tujuanPenjadwalan),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF1565C0),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TreeMappingDetailPage(
                                                        pohon: pohon),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}