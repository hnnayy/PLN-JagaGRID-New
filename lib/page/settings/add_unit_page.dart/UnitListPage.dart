import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/unit.dart';
import '../../../services/unit_service.dart';
import 'AddUnitPage.dart' show FormAddUnitPage;

class UnitListPage extends StatefulWidget {
  const UnitListPage({super.key});

  @override
  State<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends State<UnitListPage> {
  final TextEditingController searchController = TextEditingController();
  final UnitService _unitService = UnitService();
  String searchQuery = "";

  void _addNewUnit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormAddUnitPage()),
    );
  }

  void _editUnit(String docId, String namaUnit, String kodeUnit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormAddUnitPage(
          docId: docId,
          namaUnit: namaUnit,
          kodeUnit: kodeUnit,
        ),
      ),
    );
  }

  void _deleteUnit(String docId, String namaUnit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus $namaUnit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _unitService.softDelete(docId); // ← soft delete
                if (mounted) _showSuccessDialog(namaUnit);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus unit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String namaUnit) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
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
                "Unit $namaUnit berhasil dihapus",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      Timer(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(color: Color(0xFF125E72)),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Daftar Unit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 23,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_business,
                              color: Colors.white, size: 34),
                          onPressed: _addNewUnit,
                          tooltip: "Tambah Unit",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Cari unit...",
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey[400], size: 20),
                        onPressed: () => setState(() {
                          searchController.clear();
                          searchQuery = "";
                        }),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 4),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // ── Total Unit Card ──
          if (searchQuery.isEmpty)
            StreamBuilder<List<UnitModel>>(
              stream: _unitService.watchAll(), // ← watchAll
              builder: (context, snapshot) {
                final total = snapshot.data?.length ?? 0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF125E72), Color(0xFF14A2B9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Total $total Unit Terdaftar",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 20),

          // ── Unit List ──
          Expanded(
            child: StreamBuilder<List<UnitModel>>(
              stream: _unitService.watchAll(), // ← watchAll
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text("Terjadi kesalahan",
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF14A2B9)),
                    ),
                  );
                }

                final units = (snapshot.data ?? []).where((unit) {
                  final query = searchQuery.toLowerCase();
                  return unit.namaUnit.toLowerCase().contains(query) ||
                      unit.kodeUnit.toLowerCase().contains(query);
                }).toList();

                if (units.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    return _buildUnitCard(units[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.business_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isNotEmpty ? "Tidak ditemukan" : "Belum ada unit",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? "Tidak ada unit yang cocok dengan '$searchQuery'"
                : "Tambahkan unit pertama Anda",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                searchController.clear();
                searchQuery = "";
              }),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text("Hapus Pencarian"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF125E72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitCard(UnitModel unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Badge kode unit
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF125E72),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  unit.kodeUnit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Nama unit & preview ID pohon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.namaUnit,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF125E72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
  children: [
    Icon(Icons.tag, size: 13, color: Colors.grey[400]),
    const SizedBox(width: 4),
    Flexible(
      child: Text(
        "Prefix ID: ${unit.kodeUnit}-XXXXXXXX",
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
                ],
              ),
            ),

            // Tombol edit & hapus
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: const Color(0xFF14A2B9),
                    onPressed: () => _editUnit(
                      unit.id ?? '',
                      unit.namaUnit,
                      unit.kodeUnit,
                    ),
                    tooltip: "Edit Unit",
                  ),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () =>
                        _deleteUnit(unit.id ?? '', unit.namaUnit),
                    tooltip: "Hapus Unit",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}