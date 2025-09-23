import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';
import 'edit_asset.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class DaftarAssetPage extends StatefulWidget {
  const DaftarAssetPage({super.key});

  @override
  State<DaftarAssetPage> createState() => _DaftarAssetPageState();
}

class _DaftarAssetPageState extends State<DaftarAssetPage> {
  final _assetService = AssetService();
  String _searchQuery = '';
  Map<String, String> _selectedFilters = {
    'UP3': '',
    'ULP': '',
    'PENYULANG': '',
    'ZONA PROTEKSI': '',
    'SECTION': '',
    'ROLE': '',
    'STATUS': '',
    'VENDOR VB': '',
  };

  List<AssetModel> _filteredAssets(List<AssetModel> assets) {
    List<AssetModel> filtered = assets;

    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.wilayah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.subWilayah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.section.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.up3.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.ulp.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.penyulang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               asset.vendorVb.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply all active filters
    _selectedFilters.forEach((filterType, filterValue) {
      if (filterValue.isNotEmpty) {
        filtered = filtered.where((asset) {
          switch (filterType) {
            case 'UP3':
              return asset.up3.toLowerCase().contains(filterValue.toLowerCase());
            case 'ULP':
              return asset.ulp.toLowerCase().contains(filterValue.toLowerCase());
            case 'PENYULANG':
              return asset.penyulang.toLowerCase().contains(filterValue.toLowerCase());
            case 'ZONA PROTEKSI':
              return asset.zonaProteksi.toLowerCase().contains(filterValue.toLowerCase());
            case 'SECTION':
              return asset.section.toLowerCase().contains(filterValue.toLowerCase());
            case 'ROLE':
              return asset.role.toLowerCase().contains(filterValue.toLowerCase());
            case 'VENDOR VB':
              return asset.vendorVb.toLowerCase().contains(filterValue.toLowerCase());
            default:
              return true;
          }
        }).toList();
      }
    });

    return filtered;
  }

  // Fungsi untuk export ke Excel - VERSI TERBARU DENGAN KOLOM TANGGAL
  Future<void> _exportToExcel(List<AssetModel> assets) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Membuat file Excel...'),
            ],
          ),
        ),
      );

      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission storage diperlukan untuk menyimpan file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create Excel workbook
      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Asset JTM'];
      excel.delete('Sheet1'); // Delete default sheet

      // Add headers with styling - TERMASUK KOLOM TANGGAL EXPORT
      List<String> headers = [
        'No',
        'Tanggal Export',
        'Wilayah',
        'Sub Wilayah', 
        'UP3',
        'ULP',
        'Section',
        'Penyulang',
        'Zona Proteksi',
        'Panjang (KMS)',
        'Role',
        'Vendor VB',
        'Status'
      ];

      // Style for headers
      excel_pkg.CellStyle headerStyle = excel_pkg.CellStyle(
        backgroundColorHex: '#125E72',
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 12,
        bold: true,
        fontColorHex: '#FFFFFF',
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // Add data rows - DENGAN KOLOM TANGGAL EXPORT OTOMATIS
      excel_pkg.CellStyle dataStyle = excel_pkg.CellStyle(
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      // Style untuk kolom tanggal
      excel_pkg.CellStyle dateStyle = excel_pkg.CellStyle(
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        backgroundColorHex: '#F0F8FF', // Light blue background untuk tanggal
      );

      String currentDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      for (int i = 0; i < assets.length; i++) {
        AssetModel asset = assets[i];
        List<dynamic> rowData = [
          i + 1,
          currentDate, // Tanggal export otomatis
          asset.wilayah,
          asset.subWilayah,
          asset.up3,
          asset.ulp,
          asset.section,
          asset.penyulang,
          asset.zonaProteksi,
          asset.panjangKms,
          asset.role,
          asset.vendorVb,
          asset.status,
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = rowData[j];
          // Gunakan style khusus untuk kolom tanggal (index 1)
          cell.cellStyle = j == 1 ? dateStyle : dataStyle;
        }
      }

      // Generate filename with timestamp
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String filename = 'Daftar_Asset_JTM_$timestamp.xlsx';

      // Get directory to save file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Create Downloads folder path
          String downloadsPath = '${directory.path}/../../../Download';
          directory = Directory(downloadsPath);
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat mengakses direktori penyimpanan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save file
      String filePath = '${directory.path}/$filename';
      File file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      Navigator.pop(context); // Close loading dialog

      // Show success dialog with options - VERSI LEBIH INFORMATIF
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Export Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Excel berhasil dibuat:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filename,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Total data: ${assets.length} asset'),
                    Text('📅 Tanggal export: $currentDate'),
                    Text('📁 Lokasi: Download folder'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                // Share file
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'Daftar Asset JTM - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF125E72),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget untuk menampilkan filter yang aktif
  Widget _buildActiveFiltersContent() {
    List<String> activeFilters = _selectedFilters.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();

    if (activeFilters.isEmpty) {
      return const Text(
        'Belum ada filter yang dipilih',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Aktif:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeFilters.map((filterType) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$filterType: ${_selectedFilters[filterType]}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilters[filterType] = '';
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        // Tombol clear all filters
        if (activeFilters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilters.updateAll((key, value) => '');
                });
              },
              icon: const Icon(
                Icons.clear_all,
                size: 16,
                color: Colors.white70,
              ),
              label: const Text(
                'Hapus Semua Filter',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF125E72),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            'Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Filter Options
                    Expanded(
                      child: ListView(
                        children: _selectedFilters.keys.map((filterType) {
                          String currentValue = _selectedFilters[filterType] ?? '';
                          return ListTile(
                            title: Text(
                              filterType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: currentValue.isNotEmpty
                                ? Text(
                                    'Filter: $currentValue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF125E72),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (currentValue.isNotEmpty)
                                  IconButton(
                                    onPressed: () {
                                      setDialogState(() {
                                        _selectedFilters[filterType] = '';
                                      });
                                    },
                                    icon: const Icon(Icons.clear, size: 20, color: Colors.red),
                                  ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () {
                              _showFilterValueDialog(filterType, setDialogState);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Bottom Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  _selectedFilters.updateAll((key, value) => '');
                                });
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                foregroundColor: const Color(0xFF2E5D6F),
                              ),
                              child: const Text(
                                'Reset Filter',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF125E72),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text('Selesai'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterValueDialog(String filterType, StateSetter setDialogState) {
    TextEditingController controller = TextEditingController(
      text: _selectedFilters[filterType] ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter berdasarkan $filterType'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Cari $filterType ...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      foregroundColor: const Color(0xFF2E5D6F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        _selectedFilters[filterType] = controller.text;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF125E72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAssetDetail(AssetModel asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.penyulang,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF125E72),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(asset.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          asset.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Details - Single Container
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detail Asset',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF125E72),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailItem('Wilayah', asset.wilayah),
                                _buildDetailItem('Sub Wilayah', asset.subWilayah),
                                _buildDetailItem('Section', asset.section),
                                _buildDetailItem('UP3', asset.up3),
                                _buildDetailItem('ULP', asset.ulp),
                                _buildDetailItem('Penyulang', asset.penyulang),
                                _buildDetailItem('Zona Proteksi', asset.zonaProteksi),
                                _buildDetailItem('Panjang', '${asset.panjangKms} KMS'),
                                _buildDetailItem('Role', asset.role),
                                _buildDetailItem('Vendor VB', asset.vendorVb),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editAsset(asset);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF125E72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteAsset(asset);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 182, 50, 41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editAsset(AssetModel asset) {
    // Navigate to edit page with proper import
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssetPage(asset: asset),
      ),
    ).then((result) {
      // Refresh data jika ada perubahan
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _deleteAsset(AssetModel asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Asset'),
          content: Text('Apakah Anda yakin ingin menghapus asset "${asset.penyulang}"?'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      foregroundColor: const Color(0xFF2E5D6F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await _assetService.deleteAsset(asset.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asset berhasil dihapus'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Asset JTM"),
        backgroundColor: const Color(0xFF125E72),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Excel Export Button di AppBar
          StreamBuilder<List<AssetModel>>(
            stream: _assetService.getAssets(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              
              final filteredAssets = _filteredAssets(snapshot.data!);
              
              return IconButton(
                onPressed: filteredAssets.isNotEmpty 
                  ? () => _exportToExcel(filteredAssets)
                  : null,
                icon: const Icon(Icons.file_download),
                tooltip: 'Export ke Excel',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF125E72),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter and Export Buttons Row - HANYA TOMBOL FILTER SAJA
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showFilterDialog,
                        icon: const Icon(Icons.tune, size: 16),
                        label: Text(
                          _selectedFilters.values.where((v) => v.isNotEmpty).isEmpty 
                            ? 'Pilih Filter' 
                            : '${_selectedFilters.values.where((v) => v.isNotEmpty).length} Filter Aktif'
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF125E72),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Container untuk Active Filters
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minHeight: 50,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _buildActiveFiltersContent(),
                ),
              ],
            ),
          ),
          
          // Asset List
          Expanded(
            child: StreamBuilder<List<AssetModel>>(
              stream: _assetService.getAssets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Tidak ada data asset JTM",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final filteredAssets = _filteredAssets(snapshot.data!);

                if (filteredAssets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Tidak ada data yang sesuai dengan pencarian",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Summary Info - TANPA TOMBOL EXCEL LAGI
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF125E72).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF125E72).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF125E72),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Menampilkan ${filteredAssets.length} dari ${snapshot.data!.length} total asset',
                            style: const TextStyle(
                              color: Color(0xFF125E72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Info tambahan tanpa tombol
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF125E72).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'JTM Assets',
                              style: TextStyle(
                                color: const Color(0xFF125E72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Asset List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = filteredAssets[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showAssetDetail(asset),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with Status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'ULP ${asset.ulp}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF125E72),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(asset.status),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            asset.status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Asset Details (Condensed)
                                    _buildDetailRow(Icons.account_balance, 'UP3', asset.up3),
                                    _buildDetailRow(Icons.business, 'Section', asset.section),
                                    _buildDetailRow(Icons.store, 'Penyulang', asset.penyulang),

                                    
                                    const SizedBox(height: 8),
                                    // Tap to view more indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Tap untuk lihat detail',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.touch_app,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'sempurna':
        return Colors.green;
      case 'sehat':
        return Colors.blue;
      case 'sakit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}