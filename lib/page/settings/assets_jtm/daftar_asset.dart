import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';

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
                          return ListTile(
                            title: Text(
                              filterType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Done'),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setDialogState(() {
                  _selectedFilters[filterType] = controller.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF125E72),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
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
    // Navigate to edit page
    // Navigator.pushNamed(context, '/edit-asset', arguments: asset);
    
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Asset'),
          content: Text('Edit asset: ${asset.penyulang}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
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
              ),
              child: const Text('Hapus'),
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
                    hintText: 'Cari wilayah, section, UP3, ULP, role, vendor...',
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
                // Filter Button
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
    // Debug print untuk melihat nilai status yang diterima
    print('Status received: "$status"');
    
    switch (status.toLowerCase().trim()) {
      case 'sempurna':
        return Colors.green;
      case 'sehat':
        return Colors.blue;
      case 'sakit':
        return Colors.red;
      default:
        print('Status tidak dikenali: "$status"');
        return Colors.grey;
    }
  }
}