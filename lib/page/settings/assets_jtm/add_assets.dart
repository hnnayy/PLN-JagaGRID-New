import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';

class AddAssetsPage extends StatefulWidget {
  const AddAssetsPage({super.key});

  @override
  State<AddAssetsPage> createState() => _AddAssetsPageState();
}

class _AddAssetsPageState extends State<AddAssetsPage> {
  final _assetService = AssetService();
  final _formKey = GlobalKey<FormState>();

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
  final TextEditingController _roleController = TextEditingController(); // Tambahan
  final TextEditingController _vendorVbController = TextEditingController(); // Tambahan

  bool _isLoading = false;

  Future<void> _tambahAsset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
        role: _roleController.text.isNotEmpty ? _roleController.text : "-", // Update
        vendorVb: _vendorVbController.text.isNotEmpty ? _vendorVbController.text : "-", // Update
        createdAt: DateTime.now(),
      );

      await _assetService.addAsset(newAsset);

      if (mounted) {
        // Tampilkan dialog sukses
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              title: const Text("Berhasil!"),
              content: const Text("Asset berhasil ditambahkan"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    _clearForm(); // Clear form setelah berhasil
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _wilayahController.clear();
    _subWilayahController.clear();
    _sectionController.clear();
    _up3Controller.clear();
    _ulpController.clear();
    _penyulangController.clear();
    _zonaProteksiController.clear();
    _panjangKmsController.clear();
    _statusController.clear();
    _roleController.clear(); // Tambahan
    _vendorVbController.clear(); // Tambahan
  }

  @override
  void dispose() {
    _wilayahController.dispose();
    _subWilayahController.dispose();
    _sectionController.dispose();
    _up3Controller.dispose();
    _ulpController.dispose();
    _penyulangController.dispose();
    _zonaProteksiController.dispose();
    _panjangKmsController.dispose();
    _statusController.dispose();
    _roleController.dispose(); // Tambahan
    _vendorVbController.dispose(); // Tambahan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Asset JTM"),
        backgroundColor: const Color(0xFF125E72),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _clearForm,
            child: const Text(
              "Clear",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Informasi Asset",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF125E72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _wilayahController,
                        decoration: const InputDecoration(
                          labelText: "Wilayah *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Wilayah harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subWilayahController,
                        decoration: const InputDecoration(
                          labelText: "Sub Wilayah *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Sub Wilayah harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: "Section *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Section harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _up3Controller,
                        decoration: const InputDecoration(
                          labelText: "UP3",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ulpController,
                        decoration: const InputDecoration(
                          labelText: "ULP",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _penyulangController,
                        decoration: const InputDecoration(
                          labelText: "Penyulang",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _zonaProteksiController,
                        decoration: const InputDecoration(
                          labelText: "Zona Proteksi",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _panjangKmsController,
                        decoration: const InputDecoration(
                          labelText: "Panjang (KMS)",
                          border: OutlineInputBorder(),
                          suffixText: "km",
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Masukkan angka yang valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _statusController,
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tambahan inputan Role
                      TextFormField(
                        controller: _roleController,
                        decoration: const InputDecoration(
                          labelText: "Role",
                          border: OutlineInputBorder(),
                          hintText: "Contoh: Supervisor",
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tambahan inputan Vendor VB
                      TextFormField(
                        controller: _vendorVbController,
                        decoration: const InputDecoration(
                          labelText: "Vendor VB",
                          border: OutlineInputBorder(),
                          hintText: "Nama vendor atau perusahaan",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF125E72)),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Color(0xFF125E72)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _tambahAsset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF125E72),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Simpan Asset"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "* Field wajib diisi",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}