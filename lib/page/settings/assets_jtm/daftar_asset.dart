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

  // Controller untuk form tambah asset
  final TextEditingController _wilayahController = TextEditingController();
  final TextEditingController _subWilayahController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _up3Controller = TextEditingController();
  final TextEditingController _ulpController = TextEditingController();
  final TextEditingController _penyulangController = TextEditingController();
  final TextEditingController _zonaProteksiController = TextEditingController();
  final TextEditingController _panjangKmsController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  Future<void> _tambahAsset() async {
    if (_wilayahController.text.isEmpty ||
        _subWilayahController.text.isEmpty ||
        _sectionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua field wajib!")),
      );
      return;
    }

    final newAsset = AssetModel(
      id: '', // Firestore akan generate otomatis
      wilayah: _wilayahController.text,
      subWilayah: _subWilayahController.text,
      section: _sectionController.text,
      up3: _up3Controller.text,
      ulp: _ulpController.text,
      penyulang: _penyulangController.text,
      zonaProteksi: _zonaProteksiController.text,
      panjangKms: double.tryParse(_panjangKmsController.text) ?? 0,
      status: _statusController.text,
      role: "-", // bisa disesuaikan nanti
      vendorVb: "-", // bisa disesuaikan nanti
      createdAt: DateTime.now(),
    );

    await _assetService.addAsset(newAsset);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Asset berhasil ditambahkan")),
    );

    _wilayahController.clear();
    _subWilayahController.clear();
    _sectionController.clear();
    _up3Controller.clear();
    _ulpController.clear();
    _penyulangController.clear();
    _zonaProteksiController.clear();
    _panjangKmsController.clear();
    _statusController.clear();
  }

  void _showTambahAssetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Asset JTM"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _wilayahController, decoration: const InputDecoration(labelText: "Wilayah")),
              TextField(controller: _subWilayahController, decoration: const InputDecoration(labelText: "Sub Wilayah")),
              TextField(controller: _sectionController, decoration: const InputDecoration(labelText: "Section")),
              TextField(controller: _up3Controller, decoration: const InputDecoration(labelText: "UP3")),
              TextField(controller: _ulpController, decoration: const InputDecoration(labelText: "ULP")),
              TextField(controller: _penyulangController, decoration: const InputDecoration(labelText: "Penyulang")),
              TextField(controller: _zonaProteksiController, decoration: const InputDecoration(labelText: "Zona Proteksi")),
              TextField(
                controller: _panjangKmsController,
                decoration: const InputDecoration(labelText: "Panjang (KMS)"),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: _statusController, decoration: const InputDecoration(labelText: "Status")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5D6F)),
            onPressed: _tambahAsset,
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Asset JTM"),
        backgroundColor: const Color(0xFF2E5D6F),
      ),
      body: StreamBuilder<List<AssetModel>>(
        stream: _assetService.getAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Tidak ada data asset JTM",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final assets = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade300),
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2E5D6F)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              columns: const [
                DataColumn(label: Text("Wilayah")),
                DataColumn(label: Text("Sub Wilayah")),
                DataColumn(label: Text("Section")),
                DataColumn(label: Text("UP3")),
                DataColumn(label: Text("ULP")),
                DataColumn(label: Text("Penyulang")),
                DataColumn(label: Text("Zona Proteksi")),
                DataColumn(label: Text("Panjang (KMS)")),
                DataColumn(label: Text("Status")),
              ],
              rows: assets.map((asset) {
                return DataRow(
                  cells: [
                    DataCell(Text(asset.wilayah)),
                    DataCell(Text(asset.subWilayah)),
                    DataCell(Text(asset.section)),
                    DataCell(Text(asset.up3)),
                    DataCell(Text(asset.ulp)),
                    DataCell(Text(asset.penyulang)),
                    DataCell(Text(asset.zonaProteksi)),
                    DataCell(Text("${asset.panjangKms}")),
                    DataCell(Text(asset.status)),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E5D6F),
        onPressed: _showTambahAssetDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
