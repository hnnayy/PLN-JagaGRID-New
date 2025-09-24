import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tree_growth_provider.dart';
import '../../models/tree_growth.dart';
import 'tree_growth_form_page.dart';

class TreeGrowthListPage extends StatefulWidget {
  const TreeGrowthListPage({super.key});

  @override
  State<TreeGrowthListPage> createState() => _TreeGrowthListPageState();
}

class _TreeGrowthListPageState extends State<TreeGrowthListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreeGrowthProvider>().load();
    });
  }

  // Alert Dialog untuk delete success - diperbarui sesuai gambar
  void _showDeleteSuccessDialog(String itemName, double growthRate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Success - warna teal sesuai gambar
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A8A94), // Warna teal dari gambar
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A8A94),
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'Data pertumbuhan pohon berhasil diperbarui',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Details Container - background biru muda sesuai gambar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F6), // Background biru muda dari gambar
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Nama Pohon:', itemName),
                      const SizedBox(height: 8),
                      _buildDetailRow('Pertumbuhan:', '${growthRate.round()} cm/tahun'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Disimpan:', _formatDate(DateTime.now())),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Button - dengan icon dan warna sesuai gambar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A8A94),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kembali ke List',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method untuk detail row
  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isError ? Colors.grey.shade800 : const Color(0xFF5A8A94),
            ),
          ),
        ),
      ],
    );
  }

  // Alert Dialog untuk error
  void _showFailureDialog(String title, String message, String errorDetail, {String? itemName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Error:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        errorDetail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                      if (itemName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.eco, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Item: $itemName',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade400, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<TreeGrowthProvider>().load();
                          },
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete Confirmation Dialog - sederhana
  void _showDeleteConfirmDialog(TreeGrowth item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Warning - sederhana
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Konfirmasi Hapus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'Apakah Anda yakin ingin menghapus data ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // Item info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, color: Colors.orange.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Pertumbuhan: ${item.growthRate.round()} cm/tahun',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data yang sudah dihapus tidak dapat dikembalikan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          await context.read<TreeGrowthProvider>().remove(item.id);
          if (mounted) {
            _showDeleteSuccessDialog(item.name, item.growthRate);
          }
        } catch (e) {
          if (mounted) {
            String errorMsg = e.toString().replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/\:]'), '');
            if (errorMsg.isEmpty) {
              errorMsg = 'Terjadi kesalahan sistem yang tidak diketahui.';
            }
            _showFailureDialog(
              'Gagal!',
              'Data gagal dihapus dari sistem',
              errorMsg,
              itemName: item.name,
            );
          }
        }
      }
    });
  }

  // Format tanggal
  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF125E72), Color(0xFF14A2B9)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Master Pertumbuhan Pohon',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              iconSize: 34,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () async {
                final created = await Navigator.push<TreeGrowth?>(
                  context,
                  MaterialPageRoute(builder: (_) => const TreeGrowthFormPage()),
                );
                if (created != null && mounted) {
                  try {
                    await context.read<TreeGrowthProvider>().add(created.name, created.growthRate);
                    // Tidak ada alert - form sudah handle
                  } catch (e) {
                    if (mounted) {
                      String errorMsg = e.toString().replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/\:]'), '');
                      if (errorMsg.isEmpty) {
                        errorMsg = 'Terjadi kesalahan sistem yang tidak diketahui.';
                      }
                      _showFailureDialog(
                        'Gagal!',
                        'Data pohon gagal disimpan ke database',
                        errorMsg,
                        itemName: created.name,
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Consumer<TreeGrowthProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14A2B9)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Memuat data...',
                              style: TextStyle(
                                color: Color(0xFF14A2B9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (provider.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${provider.errorMessage}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14A2B9),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => provider.load(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final items = provider.items;
                    if (items.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada data pohon.',
                              style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tekan tombol + untuk menambahkan data.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: InkWell(
                              onTap: () async {
                                final updated = await Navigator.push<TreeGrowth?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TreeGrowthFormPage(item: item),
                                  ),
                                );
                                if (updated != null && context.mounted) {
                                  try {
                                    await context.read<TreeGrowthProvider>().update(updated);
                                    // Tidak ada alert - form sudah handle
                                  } catch (e) {
                                    if (mounted) {
                                      String errorMsg = e.toString().replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/\:]'), '');
                                      if (errorMsg.isEmpty) {
                                        errorMsg = 'Terjadi kesalahan sistem yang tidak diketahui.';
                                      }
                                      _showFailureDialog(
                                        'Gagal!',
                                        'Data pohon gagal disimpan ke database',
                                        errorMsg,
                                        itemName: item.name,
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14A2B9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.eco, color: Colors.white, size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pertumbuhan: ${item.growthRate.round()} cm/tahun',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ditambahkan: ${_formatDate(item.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF0B5F6D)),
                                          onPressed: () async {
                                            final updated = await Navigator.push<TreeGrowth?>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TreeGrowthFormPage(item: item),
                                              ),
                                            );
                                            if (updated != null && context.mounted) {
                                              try {
                                                await context.read<TreeGrowthProvider>().update(updated);
                                                // Tidak ada alert - form sudah handle
                                              } catch (e) {
                                                if (mounted) {
                                                  String errorMsg = e.toString().replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/\:]'), '');
                                                  if (errorMsg.isEmpty) {
                                                    errorMsg = 'Terjadi kesalahan sistem yang tidak diketahui.';
                                                  }
                                                  _showFailureDialog(
                                                    'Gagal!',
                                                    'Data pohon gagal disimpan ke database',
                                                    errorMsg,
                                                    itemName: item.name,
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                                          onPressed: () => _showDeleteConfirmDialog(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}