import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../providers/eksekusi_provider.dart';
import '../../constants/colors.dart';

class EksekusiPage extends StatefulWidget {
  final DataPohon pohon;

  const EksekusiPage({super.key, required this.pohon});

  @override
  _EksekusiPageState createState() => _EksekusiPageState();
}

class _EksekusiPageState extends State<EksekusiPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAction = 'Tebang Pangkas';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _diameterController = TextEditingController(text: '200');
  final TextEditingController _dateController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default _selectedAction based on DataPohon.tujuanPenjadwalan
    _selectedAction = widget.pohon.tujuanPenjadwalan == 1
        ? 'Tebang Pangkas'
        : widget.pohon.tujuanPenjadwalan == 2
            ? 'Tebang Habis'
            : 'Tebang Pangkas'; // Default to Tebang Pangkas if tujuanPenjadwalan is not 1 or 2
    _heightController.text = widget.pohon.initialHeight != null
        ? widget.pohon.initialHeight.toStringAsFixed(1)
        : '0.0';
    _dateController.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _heightController.dispose();
    _diameterController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearForm() {
    _heightController.clear();
    _diameterController.clear();
    _dateController.text = _formatDate(DateTime.now());
    setState(() {
      _selectedImage = null;
      _selectedAction = widget.pohon.tujuanPenjadwalan == 1
          ? 'Tebang Pangkas'
          : widget.pohon.tujuanPenjadwalan == 2
              ? 'Tebang Habis'
              : 'Tebang Pangkas'; // Default to Tebang Pangkas if tujuanPenjadwalan is not 1 or 2
    });
  }

  Future<void> _saveEksekusi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Require image for both Tebang Pangkas and Tebang Habis
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto setelah eksekusi wajib diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use today's date and current WITA time, formatted as string
      final nowWita = DateTime.now().toUtc().add(const Duration(hours: 8)); // Convert to WITA (UTC+8)
      final formattedTanggalEksekusi = DateFormat('dd/MM/yyyy HH:mm').format(nowWita) + ' WITA';

      final eksekusi = Eksekusi(
        id: '',
        dataPohonId: widget.pohon.id, // References DataPohon.id
        statusEksekusi: _selectedAction == 'Tebang Pangkas' ? 1 : 2, // Maps to 1=Tebang Pangkas, 2=Tebang Habis
        tanggalEksekusi: formattedTanggalEksekusi, // Store as string
        fotoSetelah: null,
        createdBy: 1,
        createdDate: Timestamp.now(),
        status: 1,
        tinggiPohon: double.tryParse(_heightController.text) ?? 0.0,
        diameterPohon: double.tryParse(_diameterController.text) ?? 0.0,
      );

      await Provider.of<EksekusiProvider>(context, listen: false).addEksekusi(eksekusi, _selectedImage!); // Use non-nullable File
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Sukses!', style: TextStyle(color: Colors.green)),
          content: const Text('Data eksekusi berhasil disimpan.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _clearForm();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal!', style: TextStyle(color: Colors.red)),
          content: Text('Terjadi kesalahan saat menyimpan data:\n${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Eksekusi Pohon #${widget.pohon.idPohon}',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearForm,
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Pohon',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF125E72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.pohon.prioritas == 1
                                      ? Colors.green
                                      : widget.pohon.prioritas == 2
                                          ? const Color(0xFFFFD700)
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Prioritas: ${widget.pohon.prioritas == 1 ? "Rendah" : widget.pohon.prioritas == 2 ? "Sedang" : "Tinggi"}',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID Pohon',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.pohon.idPohon.isNotEmpty ? widget.pohon.idPohon : 'P023',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sektor',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.pohon.up3.isNotEmpty && widget.pohon.ulp.isNotEmpty
                                        ? '${widget.pohon.up3}, ${widget.pohon.ulp}'
                                        : 'Parepare, Sulawesi Selatan',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Penyulang',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.pohon.penyulang.isNotEmpty ? widget.pohon.penyulang : 'Tidak tersedia',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tujuan Penindakan',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.pohon.tujuanPenjadwalan == 1
                                        ? 'Pemangkasan'
                                        : widget.pohon.tujuanPenjadwalan == 2
                                            ? 'Penebangan'
                                            : widget.pohon.tujuanPenjadwalan == null
                                                ? 'Tidak diketahui'
                                                : 'Penanaman ulang strategis',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nama Pohon',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.pohon.namaPohon.isNotEmpty ? widget.pohon.namaPohon : 'Tidak tersedia',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Penanganan Pohon',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF125E72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.height, size: 20),
                              const SizedBox(width: 5),
                              const Text('Tinggi Pohon'),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: screenWidth * 0.2,
                                child: TextFormField(
                                  controller: _heightController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Masukkan tinggi',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Tinggi wajib diisi';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Masukkan angka valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Text(' m'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.aspect_ratio, size: 20),
                              const SizedBox(width: 5),
                              const Text('Diameter Pohon'),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: screenWidth * 0.2,
                                child: TextFormField(
                                  controller: _diameterController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Masukkan diameter',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Diameter wajib diisi';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Masukkan angka valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Text(' cm'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 5),
                              const Text('Tanggal Eksekusi'),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: screenWidth * 0.3,
                                child: TextFormField(
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true, // Keep read-only to prevent input
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Tanggal wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.camera_alt, size: 20),
                              const SizedBox(width: 5),
                              const Text('Foto Setelah Eksekusi'),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF125E72),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  _selectedImage == null ? 'Pilih Foto' : 'Ganti Foto',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImage != null) ...[
                            const SizedBox(height: 10),
                            Image.file(
                              _selectedImage!,
                              height: screenHeight * 0.2,
                              width: screenWidth * 0.4,
                              fit: BoxFit.cover,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Aksi:'),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: _selectedAction,
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                                elevation: 16,
                                style: const TextStyle(color: Colors.black, fontSize: 16),
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFF125E72),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedAction = newValue!;
                                  });
                                },
                                items: <String>['Tebang Pangkas', 'Tebang Habis'].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
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
                            'Batal',
                            style: TextStyle(color: Color(0xFF125E72)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEksekusi,
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
                              : const Text('Simpan Eksekusi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF125E72)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}