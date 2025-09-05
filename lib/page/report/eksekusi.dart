import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
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
  String _selectedAction = 'Tebang Pangkas'; // Default to match tujuanPenjadwalan
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _diameterController = TextEditingController(text: '200');
  final TextEditingController _dateController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // Set initial dropdown value based on tujuanPenjadwalan from DataPohon
    _selectedAction = widget.pohon.tujuanPenjadwalan == 1
        ? 'Tebang Pangkas'
        : widget.pohon.tujuanPenjadwalan == 2
            ? 'Tebang Habis'
            : 'Tebang Pangkas';
    // Prepopulate height from DataPohon initialHeight with fallback
    _heightController.text = widget.pohon.initialHeight != null
        ? widget.pohon.initialHeight.toStringAsFixed(1)
        : '0.0';
    // Prepopulate date with current date
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
    return '${date.day}/${date.month}/${date.year}';
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID Pohon',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: widget.pohon.prioritas == 1
                                  ? Colors.green // Rendah
                                  : widget.pohon.prioritas == 2
                                      ? const Color(0xFFFFD700) // Sedang (kuning)
                                      : Colors.red, // Tinggi
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Prioritas: ${widget.pohon.prioritas == 1 ? "Rendah" : widget.pohon.prioritas == 2 ? "Sedang" : "Tinggi"}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.pohon.idPohon.isNotEmpty ? widget.pohon.idPohon : 'P023',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      Text(
                        'Sector',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pohon.up3.isNotEmpty && widget.pohon.ulp.isNotEmpty
                            ? '${widget.pohon.up3}, ${widget.pohon.ulp}'
                            : 'Parepare, Sulawesi Selatan',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      Text(
                        'Penyulang',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pohon.penyulang.isNotEmpty ? widget.pohon.penyulang : 'Tidak tersedia',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      Text(
                        'Tujuan Penindakan',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: Text(
                          widget.pohon.tujuanPenjadwalan == 1
                              ? 'Tebang Pangkas'
                              : widget.pohon.tujuanPenjadwalan == 2
                                  ? 'Tebang Habis'
                                  : 'Penanaman Ulang',
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ),
                      Text(
                        'Nama Pohon',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pohon.namaPohon.isNotEmpty ? widget.pohon.namaPohon : 'Tidak tersedia',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Penanganan Pohon',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
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
                            child: TextField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
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
                            child: TextField(
                              controller: _diameterController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
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
                            child: TextField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
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
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null // Disable button during loading
                        : () async {
                            if (_selectedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Foto setelah eksekusi wajib diisi')),
                              );
                              return;
                            }
                            if (_heightController.text.isEmpty || _diameterController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tinggi dan diameter pohon wajib diisi')),
                              );
                              return;
                            }
                            setState(() {
                              _isLoading = true; // Start loading
                            });
                            try {
                              final dateParts = _dateController.text.split('/');
                              final eksekusi = Eksekusi(
                                id: '', // Empty string, will be set by Firestore
                                dataPohonId: widget.pohon.id,
                                statusEksekusi: _selectedAction == 'Tebang Pangkas' ? 2 : 3,
                                tanggalEksekusi: Timestamp.fromDate(DateTime(
                                  int.parse(dateParts[2]),
                                  int.parse(dateParts[1]),
                                  int.parse(dateParts[0]),
                                )),
                                fotoSetelah: null, // Will be set by EksekusiService
                                createdBy: 1,
                                createdDate: Timestamp.now(),
                                status: 1,
                                tinggiPohon: double.tryParse(_heightController.text) ?? 0.0,
                                diameterPohon: double.tryParse(_diameterController.text) ?? 0.0,
                              );

                              print('Mencoba menyimpan eksekusi: ${eksekusi.toMap()}');
                              await Provider.of<EksekusiProvider>(context, listen: false).addEksekusi(eksekusi, _selectedImage);
                              if (!mounted) return;
                              setState(() {
                                _isLoading = false; // Stop loading
                              });
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Sukses!', style: TextStyle(color: Colors.green)),
                                  content: const Text('Data eksekusi berhasil disimpan.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).pop(); // Navigate back after dialog
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                _isLoading = false; // Stop loading on error
                              });
                              print('Error di EksekusiPage: $e');
                              if (!mounted) return;
                              await showDialog(
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
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF125E72),
                      minimumSize: Size(screenWidth * 0.5, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
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