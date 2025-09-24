import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';
import 'edit_asset.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
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
    'HEALTH_INDEX': '',
    'VENDOR VB': '',
  };

  List<AssetModel> _filteredAssets(List<AssetModel> assets) {
    print('Original assets: ${assets.length}');
    List<AssetModel> filtered = assets;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.wilayah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.subWilayah.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.section.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.up3.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.ulp.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.penyulang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.vendorVb.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.healthIndex.toString().split('.').last.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

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
            case 'HEALTH_INDEX':
              return asset.healthIndex.toString().split('.').last.toLowerCase().contains(filterValue.toLowerCase());
            default:
              return true;
          }
        }).toList();
      }
    });

    print('Filtered assets: ${filtered.length}');
    return filtered;
  }

  Future<void> _exportToExcel(List<AssetModel> assets) async {
    try {
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

      // Request storage permission only for Android versions < 13
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted && (await Permission.storage.status).isPermanentlyDenied) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Izin penyimpanan diperlukan. Silakan izinkan di pengaturan.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Buka Pengaturan',
                onPressed: openAppSettings,
              ),
            ),
          );
          return;
        }
      }

      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Sheet1'];

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
        'Health Index'
      ];

      excel_pkg.CellStyle headerStyle = excel_pkg.CellStyle(
        backgroundColorHex: '#125E72',
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 12,
        bold: true,
        fontColorHex: '#FFFFFF',
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      excel_pkg.CellStyle dataStyle = excel_pkg.CellStyle(
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: excel_pkg.VerticalAlign.Center,
      );

      excel_pkg.CellStyle dateStyle = excel_pkg.CellStyle(
        fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: excel_pkg.VerticalAlign.Center,
        backgroundColorHex: '#F0F8FF',
      );

      String currentDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      for (int i = 0; i < assets.length; i++) {
        AssetModel asset = assets[i];
        List<dynamic> rowData = [
          i + 1,
          currentDate,
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
          asset.healthIndex.toString().split('.').last,
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = rowData[j];
          cell.cellStyle = j == 1 ? dateStyle : dataStyle;
        }
      }

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String filename = 'Daftar_Asset_JTM_$timestamp.xlsx';
      String filePath;

      Directory? directory;
      if (Platform.isAndroid) {
        filePath = '/storage/emulated/0/Download/$filename';
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$filename';
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

      File file = File(filePath);
      print('Saving file to: $filePath');
      var encodedExcel = excel.encode();
      if (encodedExcel == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengenkode file Excel'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await file.writeAsBytes(encodedExcel);
      bool fileExists = await file.exists();
      print('File exists: $fileExists');

      Navigator.pop(context); // Close the loading dialog

      print('Attempting to open file: $filePath');
      final openResult = await OpenFile.open(
        filePath,
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      print('Open result: ${openResult.type}, message: ${openResult.message}');

      if (openResult.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: ${openResult.message}. File tersimpan di Download folder.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Bagikan',
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                  text: 'Daftar Asset JTM - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                );
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      Navigator.pop(context);
      print('Error exporting Excel: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        if (activeFilters.isEmpty)
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF125E72),
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
                                      setState(() {});
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
    if (filterType == 'HEALTH_INDEX') {
      String? selectedValue = _selectedFilters[filterType];
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Filter berdasarkan $filterType'),
            content: DropdownButton<String>(
              value: selectedValue?.isEmpty ?? true ? null : selectedValue,
              hint: Text('Pilih $filterType'),
              isExpanded: true,
              items: ['SEMPURNA', 'SEHAT', 'SAKIT'].map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setDialogState(() {
                  _selectedFilters[filterType] = value ?? '';
                });
                Navigator.pop(context);
                setState(() {});
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );
    } else {
      TextEditingController controller = TextEditingController(text: _selectedFilters[filterType]);
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
                      child: const Text('Batal'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          _selectedFilters[filterType] = controller.text;
                        });
                        Navigator.pop(context);
                        setState(() {});
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(asset.healthIndex),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          asset.healthIndex.toString().split('.').last,
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
                                _buildDetailItem('Health Index', asset.healthIndex.toString().split('.').last),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            backgroundColor: const Color(0xFF125E72),
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
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _editAsset(AssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssetPage(asset: asset),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showSuccessDialog(AssetModel deletedAsset) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(color: Color(0xFF2E5D6F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "Berhasil!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E5D6F)),
              ),
              const SizedBox(height: 10),
              Text(
                "Asset ${deletedAsset.wilayah} - ${deletedAsset.section} berhasil dihapus",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        if (mounted) {
                          _showSuccessDialog(asset);
                        }
                        setState(() {});
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
          StreamBuilder<List<AssetModel>>(
            stream: _assetService.getAssets(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              final filteredAssets = _filteredAssets(snapshot.data!);
              return IconButton(
                onPressed: filteredAssets.isNotEmpty ? () => _exportToExcel(filteredAssets) : null,
                icon: const Icon(Icons.file_download),
                tooltip: 'Export ke Excel',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                              : '${_selectedFilters.values.where((v) => v.isNotEmpty).length} Filter Aktif',
                          overflow: TextOverflow.ellipsis,
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
          Expanded(
            child: StreamBuilder<List<AssetModel>>(
              stream: _assetService.getAssets(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
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
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF125E72).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF125E72).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF125E72),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Menampilkan ${filteredAssets.length} dari ${snapshot.data!.length} total asset',
                              style: const TextStyle(
                                color: Color(0xFF125E72),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF125E72).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'JTM Assets',
                              style: TextStyle(
                                color: Color(0xFF125E72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(asset.healthIndex),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            asset.healthIndex.toString().split('.').last,
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
                                    _buildDetailRow(Icons.account_balance, 'UP3', asset.up3),
                                    _buildDetailRow(Icons.business, 'Section', asset.section),
                                    _buildDetailRow(Icons.store, 'Penyulang', asset.penyulang),
                                    const SizedBox(height: 8),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Flexible(
                flex: 2,
                child: Text(
                  '$label:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(HealthIndex healthIndex) {
    switch (healthIndex) {
      case HealthIndex.SEMPURNA:
        return Colors.green;
      case HealthIndex.SEHAT:
        return Colors.blue;
      case HealthIndex.SAKIT:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}