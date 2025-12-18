import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../models/data_pohon.dart';
import '../../services/data_pohon_service.dart';

class UlpDetailPage extends StatefulWidget {
  final String ulpName;
  final DateTime selectedMonth;

  const UlpDetailPage({
    Key? key,
    required this.ulpName,
    required this.selectedMonth,
  }) : super(key: key);

  @override
  State<UlpDetailPage> createState() => _UlpDetailPageState();
}

class _UlpDetailPageState extends State<UlpDetailPage> {
  final DataPohonService _service = DataPohonService();
  bool _isDownloading = false;
  bool _isLoading = false;
  late DateTime _selectedMonth;
  bool _filterBySpecificDate = false;
  DateTime? _specificDate;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.selectedMonth;
  }

  Future<Map<String, dynamic>> _getUlpDetail() async {
    final snapshot = await _service.getAllDataPohon().first;

    final filtered = snapshot.where((p) {
      final unitMatch = (p.ulp == widget.ulpName || p.up3 == widget.ulpName);
      
      if (_filterBySpecificDate && _specificDate != null) {
        final dateMatch = p.scheduleDate.year == _specificDate!.year &&
                          p.scheduleDate.month == _specificDate!.month &&
                          p.scheduleDate.day == _specificDate!.day;
        return unitMatch && dateMatch;
      } else {
        final monthMatch = p.scheduleDate.year == _selectedMonth.year &&
                           p.scheduleDate.month == _selectedMonth.month;
        return unitMatch && monthMatch;
      }
    }).toList();

    int total = filtered.length;
    int dipangkas = filtered.where((p) => p.tujuanPenjadwalan == 1).length;
    int ditebang = filtered.where((p) => p.tujuanPenjadwalan == 2).length;

    filtered.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));

    return {
      'pohonList': filtered,
      'total': total,
      'dipangkas': dipangkas,
      'ditebang': ditebang,
    };
  }

  Future<void> _exportToExcel(
    List<DataPohon> pohonList,
    int total,
    int dipangkas,
    int ditebang,
  ) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Detail ${widget.ulpName}'];

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

      sheet.cell(CellIndex.indexByString('A1')).value = 'DETAIL LOKASI POHON - ${widget.ulpName}';
      sheet.cell(CellIndex.indexByString('A2')).value = 'Periode: $periode';
      sheet.cell(CellIndex.indexByString('A3')).value = '';

      sheet.cell(CellIndex.indexByString('A4')).value = 'RINGKASAN';
      sheet.cell(CellIndex.indexByString('A5')).value = 'Total Pohon';
      sheet.cell(CellIndex.indexByString('B5')).value = total;
      sheet.cell(CellIndex.indexByString('A6')).value = 'Dipangkas';
      sheet.cell(CellIndex.indexByString('B6')).value = dipangkas;
      sheet.cell(CellIndex.indexByString('A7')).value = 'Ditebang';
      sheet.cell(CellIndex.indexByString('B7')).value = ditebang;

      sheet.cell(CellIndex.indexByString('A8')).value = '';

      sheet.cell(CellIndex.indexByString('A9')).value = 'No';
      sheet.cell(CellIndex.indexByString('B9')).value = 'ID Pohon';
      sheet.cell(CellIndex.indexByString('C9')).value = 'Lokasi/Penyulang';
      sheet.cell(CellIndex.indexByString('D9')).value = 'Koordinat';
      sheet.cell(CellIndex.indexByString('E9')).value = 'Tujuan';
      sheet.cell(CellIndex.indexByString('F9')).value = 'Tanggal Jadwal';

      int rowIndex = 9;
      for (var i = 0; i < pohonList.length; i++) {
        final pohon = pohonList[i];
        final tujuan = pohon.tujuanPenjadwalan == 1 ? 'Dipangkas' : 'Ditebang';
        final tanggal = DateFormat('dd/MM/yyyy').format(pohon.scheduleDate);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = pohon.idPohon;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = pohon.penyulang.isNotEmpty ? pohon.penyulang : '-';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = pohon.koordinat.isNotEmpty ? pohon.koordinat : '-';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = tujuan;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = tanggal;

        rowIndex++;
      }

      sheet.setColWidth(0, 8);
      sheet.setColWidth(1, 20);
      sheet.setColWidth(2, 30);
      sheet.setColWidth(3, 25);
      sheet.setColWidth(4, 15);
      sheet.setColWidth(5, 18);

      final directory = await getTemporaryDirectory();
      final cleanName = widget.ulpName.replaceAll(' ', '_');
      final fileName = 'Detail_${cleanName}_${DateFormat('yyyyMMdd').format(_filterBySpecificDate && _specificDate != null ? _specificDate! : _selectedMonth)}.xlsx';
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
            Text(
              widget.ulpName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getDisplayText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
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
                            border: Border.all(
                              color: !_filterBySpecificDate ? const Color(0xFF2B6B7C) : Colors.transparent,
                              width: 2,
                            ),
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
                            border: Border.all(
                              color: _filterBySpecificDate ? const Color(0xFF2B6B7C) : Colors.transparent,
                              width: 2,
                            ),
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
                    future: _getUlpDetail(),
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
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: Text("Tidak ada data"));
                      }

                      final data = snapshot.data!;
                      final pohonList = data['pohonList'] as List<DataPohon>;
                      final total = data['total'] as int;
                      final dipangkas = data['dipangkas'] as int;
                      final ditebang = data['ditebang'] as int;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Cards
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFF2B6B7C),
                              child: Row(
                                children: [
                                  _buildSummaryCard('Total', total, Colors.white),
                                  const SizedBox(width: 12),
                                  _buildSummaryCard('Dipangkas', dipangkas, const Color(0xFF4FC3F7)),
                                  const SizedBox(width: 12),
                                  _buildSummaryCard('Ditebang', ditebang, const Color(0xFFEF5350)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Detail Lokasi Pohon Header + Download Button
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Detail Lokasi Pohon',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _isDownloading 
                                        ? null 
                                        : () => _exportToExcel(pohonList, total, dipangkas, ditebang),
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
                            ),

                            // List Pohon
                            if (pohonList.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        _filterBySpecificDate 
                                            ? 'Tidak ada pohon untuk tanggal ini'
                                            : 'Tidak ada pohon untuk periode ini',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: pohonList.length,
                                itemBuilder: (context, index) {
                                  final pohon = pohonList[index];
                                  final tujuan = pohon.tujuanPenjadwalan == 1 ? 'Dipangkas' : 'Ditebang';
                                  final badgeColor = pohon.tujuanPenjadwalan == 1
                                      ? const Color(0xFFFFB74D)
                                      : const Color(0xFFE57373);

                                  return Container(
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
                                        // Header: Lokasi + Badge
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pohon.penyulang.isNotEmpty 
                                                    ? pohon.penyulang 
                                                    : 'Lokasi tidak tersedia',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeColor,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                tujuan,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Info Grid
                                        Row(
                                          children: [
                                            // Koordinat
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.place_outlined,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      pohon.koordinat.isNotEmpty 
                                                          ? pohon.koordinat 
                                                          : "Tidak ada koordinat",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Tanggal
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatFullDate(pohon.scheduleDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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

  Widget _buildSummaryCard(String title, int value, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}