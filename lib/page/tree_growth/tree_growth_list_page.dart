import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tree_growth_provider.dart';
import '../../models/tree_growth.dart';
import 'tree_growth_form_page.dart';

class TreeGrowthListPage extends StatefulWidget {
  const TreeGrowthListPage({super.key});

  @override
  State<TreeGrowthListPage> createState() => _TreeGrowthListPageState();

  // Static method to get tree names from any page
  static Future<List<String>> getTreeNames(BuildContext context) async {
    final provider = context.read<TreeGrowthProvider>();
    try {
      final trees = await provider.watchAll().first; // Get current data
      return trees.map((tree) => tree.name).toSet().toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Static method to get all tree data from any page
  static Future<List<TreeGrowth>> getTreeData(BuildContext context) async {
    final provider = context.read<TreeGrowthProvider>();
    try {
      return await provider.watchAll().first; // Get current data
    } catch (e) {
      return [];
    }
  }
}

class _TreeGrowthListPageState extends State<TreeGrowthListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data and start listening to stream
      context.read<TreeGrowthProvider>().load();
    });
  }

  // Method to get tree names for add data page
  Future<List<String>> getTreeNames() async {
    final provider = context.read<TreeGrowthProvider>();
    final trees = await provider.watchAll().first; // Get current data
    return trees.map((tree) => tree.name).toSet().toList()..sort();
  }

  // Method to get all tree data for add data page
  Future<List<TreeGrowth>> getTreeData() async {
    final provider = context.read<TreeGrowthProvider>();
    return await provider.watchAll().first; // Get current data
  }

  // Alert Dialog untuk delete success
  void _showDeleteSuccessDialog(String itemName) {
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
                // Icon Success (circular check) - sama seperti form
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFF256D78),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data "$itemName" berhasil dihapus',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF256D78),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  // Alert Dialog untuk update success - diperbarui sesuai gambar  
  void _showUpdateSuccessDialog(String itemName, double growthRate) {
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
  // Format tanggal
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} WITA';
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
                await Navigator.push<TreeGrowth?>(
                  context,
                  MaterialPageRoute(builder: (_) => const TreeGrowthFormPage()),
                );
                // Form sudah handle save, jadi kita tidak perlu melakukan apapun
                // StreamBuilder akan otomatis update karena data sudah tersimpan
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
                child: StreamBuilder<List<TreeGrowth>>(
                  stream: context.read<TreeGrowthProvider>().watchAll(),
                  builder: (context, snapshot) {
                    // Show loading when waiting for data
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                    
                    // Show error if stream has error
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14A2B9),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => context.read<TreeGrowthProvider>().load(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final items = snapshot.data ?? [];
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
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Data'),
                                content: Text('Yakin ingin menghapus "${item.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await context.read<TreeGrowthProvider>().remove(item.id);
                              if (mounted) {
                                _showDeleteSuccessDialog(item.name);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menghapus ${item.name}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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