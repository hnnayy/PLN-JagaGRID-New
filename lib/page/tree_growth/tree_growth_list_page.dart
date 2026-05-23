import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tree_growth_provider.dart';
import '../../models/tree_growth.dart';
import 'tree_growth_form_page.dart';

class TreeGrowthListPage extends StatefulWidget {
  const TreeGrowthListPage({super.key});

  @override
  State<TreeGrowthListPage> createState() => _TreeGrowthListPageState();

  static Future<List<String>> getTreeNames(BuildContext context) async {
    final provider = context.read<TreeGrowthProvider>();
    try {
      final trees = await provider.watchAll().first;
      return trees.map((tree) => tree.name).toSet().toList()..sort();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TreeGrowth>> getTreeData(BuildContext context) async {
    final provider = context.read<TreeGrowthProvider>();
    try {
      return await provider.watchAll().first;
    } catch (e) {
      return [];
    }
  }
}

class _TreeGrowthListPageState extends State<TreeGrowthListPage> {
  int _sessionLevel = 1;
  String _sessionUnit = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreeGrowthProvider>().migrateData(); // jalankan sekali untuk data lama
      context.read<TreeGrowthProvider>().load();
    });
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionLevel = prefs.getInt('session_level') ?? 1;
      _sessionUnit = prefs.getString('session_unit') ?? '';
    });
  }

  // Cek apakah user boleh edit/hapus item ini
  bool _canModify(TreeGrowth item) {
    if (_sessionLevel == 1) return true; // Admin bisa semua
    // ULP hanya bisa modify milik sendiri (bukan global)
    return !item.isGlobal &&
        item.unit.toLowerCase() == _sessionUnit.toLowerCase();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFF256D78),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Berhasil!',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Data "$itemName" berhasil dihapus',
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF256D78),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCannotDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tidak Dapat Dihapus'),
        content: const Text(
            'Data ini adalah data umum yang ditambahkan oleh Admin UP3. Anda hanya dapat menghapus data yang Anda tambahkan sendiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            // Semua level boleh tambah
            IconButton(
              iconSize: 34,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () async {
                await Navigator.push<TreeGrowth?>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TreeGrowthFormPage()),
                );
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF14A2B9)),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
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
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tekan tombol + untuk menambahkan data.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final canModify = _canModify(item);

                        return Dismissible(
                          key: Key(item.id),
                          direction: canModify
                              ? DismissDirection.horizontal
                              : DismissDirection.none, // Tidak bisa swipe kalau tidak punya hak
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 28),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            if (!canModify) {
                              _showCannotDeleteDialog();
                              return false;
                            }
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Data'),
                                content: Text(
                                    'Yakin ingin menghapus "${item.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Hapus',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await context
                                  .read<TreeGrowthProvider>()
                                  .remove(item.id);
                              if (mounted) {
                                _showDeleteSuccessDialog(item.name);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Gagal menghapus ${item.name}'),
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
                                onTap: canModify
                                    ? () async {
                                        await Navigator.push<TreeGrowth?>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TreeGrowthFormPage(
                                                    item: item),
                                          ),
                                        );
                                      }
                                    : null, // Tidak bisa tap kalau tidak punya hak
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: item.isGlobal
                                              ? const Color(0xFF14A2B9)
                                              : const Color(0xFF2E7D32),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.eco,
                                              color: Colors.white, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                ),
                                                // Badge label
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: item.isGlobal
                                                        ? const Color(
                                                            0xFFE1F5FE)
                                                        : const Color(
                                                            0xFFE8F5E9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: item.isGlobal
                                                          ? const Color(
                                                              0xFF14A2B9)
                                                          : const Color(
                                                              0xFF2E7D32),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.isGlobal
                                                        ? 'Umum'
                                                        : 'Unit Saya',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: item.isGlobal
                                                          ? const Color(
                                                              0xFF14A2B9)
                                                          : const Color(
                                                              0xFF2E7D32),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Pertumbuhan: ${item.growthRate.round()} cm/tahun',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (!canModify)
                                              Text(
                                                'Data umum — tidak dapat diedit',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (canModify)
                                        Icon(Icons.chevron_right,
                                            color: Colors.grey.shade400),
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