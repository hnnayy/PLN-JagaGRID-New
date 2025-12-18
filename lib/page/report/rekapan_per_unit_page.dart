import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../services/data_pohon_service.dart';
import '../../models/data_pohon.dart';
import 'ulp_detail_page.dart';

class RekapanPerUnitListPage extends StatefulWidget {
  const RekapanPerUnitListPage({Key? key}) : super(key: key);

  @override
  State<RekapanPerUnitListPage> createState() => _RekapanPerUnitListPageState();
}

class _RekapanPerUnitListPageState extends State<RekapanPerUnitListPage> {
  final DataPohonService _service = DataPohonService();
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isCheckingAccess = true;
  bool _filterBySpecificDate = false;
  DateTime? _specificDate;

  static const List<String> _ulpList = [
    'ULP MATTIROTASI',
    'ULP BARRU',
    'ULP RAPPANG',
    'ULP PANGSID',
    'ULP TANRUTEDONG',
    'ULP SOPPENG',
    'ULP PAJALESANG',
  ];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('session_level') ?? 2;
    final sessionUnit = prefs.getString('session_unit') ?? '';

    if (level != 1) {
      // User biasa - langsung ke ULP Detail unit sendiri
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UlpDetailPage(
              ulpName: sessionUnit,
              selectedMonth: _selectedMonth,
            ),
          ),
        );
      }
    } else {
      // Admin - tampilkan list semua ULP
      setState(() {
        _isCheckingAccess = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getRekap() async {
    final snapshot = await _service.getAllDataPohon().first;

    // Filter berdasarkan bulan atau tanggal spesifik
    List<DataPohon> filtered = snapshot.where((p) {
      if (_filterBySpecificDate && _specificDate != null) {
        return p.scheduleDate.year == _specificDate!.year &&
               p.scheduleDate.month == _specificDate!.month &&
               p.scheduleDate.day == _specificDate!.day;
      } else {
        return p.scheduleDate.year == _selectedMonth.year &&
               p.scheduleDate.month == _selectedMonth.month;
      }
    }).toList();

    Map<String, Map<String, int>> rekap = {};

    for (var p in filtered) {
      final unit = p.ulp.isNotEmpty ? p.ulp : p.up3;
      if (unit.isEmpty) continue;

      if (!rekap.containsKey(unit)) {
        rekap[unit] = {'total': 0, 'dipangkas': 0, 'ditebang': 0};
      }

      rekap[unit]!['total'] = rekap[unit]!['total']! + 1;

      if (p.tujuanPenjadwalan == 1) {
        rekap[unit]!['dipangkas'] = rekap[unit]!['dipangkas']! + 1;
      } else if (p.tujuanPenjadwalan == 2) {
        rekap[unit]!['ditebang'] = rekap[unit]!['ditebang']! + 1;
      }
    }

    for (var ulp in _ulpList) {
      if (!rekap.containsKey(ulp)) {
        rekap[ulp] = {'total': 0, 'dipangkas': 0, 'ditebang': 0};
      }
    }

    int totalAll = 0;
    int dipangkasAll = 0;
    int ditebangAll = 0;

    for (var stats in rekap.values) {
      totalAll += stats['total'] ?? 0;
      dipangkasAll += stats['dipangkas'] ?? 0;
      ditebangAll += stats['ditebang'] ?? 0;
    }

    return {
      'rekap': rekap,
      'totalAll': totalAll,
      'dipangkasAll': dipangkasAll,
      'ditebangAll': ditebangAll,
    };
  }

  Future<void> _exportToExcel(Map<String, dynamic> data) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final rekap = data['rekap'] as Map<String, Map<String, int>>;
      final totalAll = data['totalAll'] as int;
      final dipangkasAll = data['dipangkasAll'] as int;
      final ditebangAll = data['ditebangAll'] as int;

      var excel = Excel.createExcel();
      Sheet sheet = excel['Rekapan Per Unit'];

      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      String periode;
      if (_filterBySpecificDate && _specificDate != null) {
        periode = '${_specificDate!.day} ${months[_specificDate!.month - 1]} ${_specificDate!.year}';
      } else {
        periode = '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
      }

      sheet.cell(CellIndex.indexByString('A1')).value = 'REKAPAN PER UNIT';
      sheet.cell(CellIndex.indexByString('A2')).value = 'Periode: $periode';
      sheet.cell(CellIndex.indexByString('A3')).value = '';

      sheet.cell(CellIndex.indexByString('A4')).value = 'Unit';
      sheet.cell(CellIndex.indexByString('B4')).value = 'Total';
      sheet.cell(CellIndex.indexByString('C4')).value = 'Dipangkas';
      sheet.cell(CellIndex.indexByString('D4')).value = 'Ditebang';

      int rowIndex = 4;
      for (var ulp in _ulpList) {
        final unitData = rekap[ulp] ?? {'total': 0, 'dipangkas': 0, 'ditebang': 0};
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = ulp;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = unitData['total'] ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = unitData['dipangkas'] ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = unitData['ditebang'] ?? 0;
        
        rowIndex++;
      }

      rowIndex++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'TOTAL KESELURUHAN';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = totalAll;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = dipangkasAll;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = ditebangAll;

      sheet.setColWidth(0, 25);
      sheet.setColWidth(1, 15);
      sheet.setColWidth(2, 15);
      sheet.setColWidth(3, 15);

      final directory = await getTemporaryDirectory();
      final fileName = 'Rekapan_Per_Unit_${DateFormat('yyyyMMdd').format(_filterBySpecificDate && _specificDate != null ? _specificDate! : _selectedMonth)}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      await OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File berhasil dibuat: $fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat Excel: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      print('❌ Error detail: $e');
    }
  }

  Future<void> _selectMonthOnly(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Bulan (Semua Tanggal)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    final isSelected = !_filterBySpecificDate && _selectedMonth.month == index + 1;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            index + 1,
                            1,
                          );
                          _filterBySpecificDate = false;
                          _specificDate = null;
                          _isLoading = true;
                        });
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2B6B7C) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          monthNames[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Future<void> _selectSpecificDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Spesifik',
    );
    if (picked != null) {
      setState(() {
        _specificDate = picked;
        _selectedMonth = picked;
        _filterBySpecificDate = true;
        _isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
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

  String _getDisplayText() {
    if (_filterBySpecificDate && _specificDate != null) {
      return _formatFullDate(_specificDate!);
    }
    return _formatMonthYear(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    // Loading saat cek akses
    if (_isCheckingAccess) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6B7C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rekapan Per Unit",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _getDisplayText(),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2B6B7C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Periode',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectMonthOnly(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_filterBySpecificDate ? [
                              BoxShadow(
                                color: const Color(0xFF2B6B7C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filter Bulanan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatMonthYear(_selectedMonth),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.calendar_month, size: 20, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectSpecificDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _filterBySpecificDate ? [
                              BoxShadow(
                                color: const Color(0xFF2B6B7C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal Spesifik',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _specificDate != null 
                                          ? _formatFullDate(_specificDate!)
                                          : 'Pilih tanggal',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _specificDate != null ? Colors.black : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_filterBySpecificDate && _specificDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _filterBySpecificDate = false;
                          _specificDate = null;
                          _isLoading = true;
                        });
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.clear, size: 16, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'Reset ke Filter Bulanan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<Map<String, dynamic>>(
                    key: ValueKey('${_selectedMonth.toString()}_${_filterBySpecificDate}_${_specificDate?.toString()}'),
                    future: _getRekap(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Memuat data...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: Text("Tidak ada data"));
                      }

                      final data = snapshot.data!;
                      final rekap = data['rekap'] as Map<String, Map<String, int>>;
                      final totalAll = data['totalAll'] as int;
                      final dipangkasAll = data['dipangkasAll'] as int;
                      final ditebangAll = data['ditebangAll'] as int;

                      final units = _ulpList;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Rincian Per Unit',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _isDownloading 
                                            ? null 
                                            : () => _exportToExcel(data),
                                        icon: _isDownloading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Icon(Icons.file_download, size: 16),
                                        label: Text(_isDownloading ? 'Memproses...' : 'Download Excel'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildTotalCard('Total', totalAll, const Color(0xFF5A9AAA)),
                                      const SizedBox(width: 12),
                                      _buildTotalCard('Dipangkas', dipangkasAll, const Color(0xFF6B9AAA)),
                                      const SizedBox(width: 12),
                                      _buildTotalCard('Ditebang', ditebangAll, const Color(0xFF7B9AAA)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: units.length,
                              itemBuilder: (context, index) {
                                final unit = units[index];
                                final unitData = rekap[unit] ?? {'total': 0, 'dipangkas': 0, 'ditebang': 0};
                                final total = unitData['total'] ?? 0;
                                final dipangkas = unitData['dipangkas'] ?? 0;
                                final ditebang = unitData['ditebang'] ?? 0;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UlpDetailPage(
                                          ulpName: unit,
                                          selectedMonth: _selectedMonth,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF2B6B7C),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                unit,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _buildUnitStatusCard('Total', total, const Color(0xFF5A9AAA)),
                                            const SizedBox(width: 10),
                                            _buildUnitStatusCard('Dipangkas', dipangkas, const Color(0xFF6B9AAA)),
                                            const SizedBox(width: 10),
                                            _buildUnitStatusCard('Ditebang', ditebang, const Color(0xFF7B9AAA)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitStatusCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}