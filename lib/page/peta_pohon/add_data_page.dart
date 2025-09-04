import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../notification/notification_page.dart';
import '../../providers/notification_provider.dart';
import '../../providers/data_pohon_provider.dart';
import '../../models/data_pohon.dart';
import 'pick_location_page.dart';

class AddDataPage extends StatefulWidget {
  const AddDataPage({Key? key}) : super(key: key);

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _up3Controller = TextEditingController();
  final _ulpController = TextEditingController();
  final _penyulangController = TextEditingController();
  final _zonaProteksiController = TextEditingController();
  final _sectionController = TextEditingController();
  final _kmsAsetController = TextEditingController();
  final _vendorController = TextEditingController();
  final _dateController = TextEditingController();
  final _coordinatesController = TextEditingController();
  final _noteController = TextEditingController();
  File? _fotoPohon;

  int? _selectedTujuan;
  int? _selectedPrioritas;
  String? _selectedNamaPohon;
  bool _isLoading = false;

  final Map<int, String> _tujuanOptions = {
    1: 'Tebang Pangkas',
    2: 'Tebang Habis',
  };

  final Map<int, String> _prioritasOptions = {
    1: 'Rendah',
    2: 'Sedang',
    3: 'Tinggi',
  };

  InputDecoration _buildInputDecoration(String label, String hint,
      {Icon? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFD3E0EA),
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.black54, fontWeight: FontWeight.w400),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.black54, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<String?> _getCurrentLocation() async {
    try {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Izin lokasi ditolak. Tidak dapat mengambil lokasi saat ini.')),
        );
        return null;
      }

      Position position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _up3Controller.dispose();
    _ulpController.dispose();
    _penyulangController.dispose();
    _zonaProteksiController.dispose();
    _sectionController.dispose();
    _kmsAsetController.dispose();
    _vendorController.dispose();
    _dateController.dispose();
    _coordinatesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5D6F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text("Tambah Data Pohon",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      ),
      body: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _idController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Id Pohon', 'Masukkan ID pohon'),
                validator: (value) => value!.isEmpty ? 'ID wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _up3Controller,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('UP3', 'Masukkan UP3'),
                validator: (value) => value!.isEmpty ? 'UP3 wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ulpController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('ULP', 'Masukkan ULP'),
                validator: (value) => value!.isEmpty ? 'ULP wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _penyulangController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Penyulang', 'Masukkan Penyulang'),
                validator: (value) => value!.isEmpty ? 'Penyulang wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _zonaProteksiController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration:
                    _buildInputDecoration('Zona Proteksi', 'Masukkan Zona Proteksi'),
                validator: (value) =>
                    value!.isEmpty ? 'Zona Proteksi wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _sectionController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Section', 'Masukkan section'),
                validator: (value) => value!.isEmpty ? 'Section wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _kmsAsetController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Kms Aset', 'Masukkan Kms Aset'),
                validator: (value) => value!.isEmpty ? 'Kms Aset wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _vendorController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Vendor VB', 'Masukkan vendor'),
                validator: (value) => value!.isEmpty ? 'Vendor wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.datetime,
                decoration: _buildInputDecoration('Tanggal Penjadwalan', 'Pilih tanggal',
                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.black)),
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'Tanggal wajib diisi' : null,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF125E72),
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF125E72)),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    _dateController.text =
                        "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedNamaPohon,
                decoration: _buildInputDecoration('Nama Pohon', 'Pilih nama pohon'),
                items: DataPohon.growthRates.keys.map((String species) {
                  return DropdownMenuItem<String>(
                    value: species,
                    child: Text(species, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedNamaPohon = newValue);
                },
                validator: (value) => value == null ? 'Nama pohon wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pilih Sumber Foto',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              ListTile(
                                leading: const Icon(Icons.camera_alt, size: 32),
                                title: const Text('Ambil Foto', style: TextStyle(fontSize: 18)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final picker = ImagePicker();
                                  final picked =
                                      await picker.pickImage(source: ImageSource.camera);
                                  if (picked != null) {
                                    setState(() {
                                      _fotoPohon = File(picked.path);
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: const Icon(Icons.photo_library, size: 32),
                                title:
                                    const Text('Pilih dari Galeri', style: TextStyle(fontSize: 18)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final picker = ImagePicker();
                                  final picked =
                                      await picker.pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    setState(() {
                                      _fotoPohon = File(picked.path);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3E0EA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(_fotoPohon == null ? Icons.camera_alt : Icons.check_circle,
                          size: 28, color: Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fotoPohon == null ? 'Pilih Foto Pohon' : 'Foto Dipilih',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _coordinatesController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Koordinat', 'Pilih koordinat',
                    suffixIcon: const Icon(Icons.location_on, color: Colors.black)),
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'Koordinat wajib diisi' : null,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Pilih Sumber Koordinat',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              ListTile(
                                leading: const Icon(Icons.map, size: 32),
                                title:
                                    const Text('Pilih dari Peta', style: TextStyle(fontSize: 18)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final String? selectedCoord = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PickLocationPage()));
                                  if (selectedCoord != null) {
                                    setState(() {
                                      _coordinatesController.text = selectedCoord;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: const Icon(Icons.my_location, size: 32),
                                title: const Text('Gunakan Lokasi Saat Ini',
                                    style: TextStyle(fontSize: 18)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final String? currentCoord = await _getCurrentLocation();
                                  if (currentCoord != null) {
                                    setState(() {
                                      _coordinatesController.text = currentCoord;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _selectedTujuan,
                decoration:
                    _buildInputDecoration('Tujuan Penjadwalan', 'Pilih tujuan penjadwalan'),
                items: _tujuanOptions.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTujuan = value;
                  });
                },
                validator: (value) => value == null ? 'Tujuan wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _selectedPrioritas,
                decoration: _buildInputDecoration('Prioritas', 'Pilih prioritas'),
                items: _prioritasOptions.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPrioritas = value;
                  });
                },
                validator: (value) => value == null ? 'Prioritas wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                keyboardType: TextInputType.multiline,
                decoration: _buildInputDecoration('Catatan', 'Masukkan catatan'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E5D6F),
                          side: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Batal',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5D6F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  List<String> dateParts = _dateController.text.split('-');
                                  if (dateParts.length == 3) {
                                    try {
                                      final pohon = DataPohon(
                                        id: '',
                                        idPohon: _idController.text,
                                        up3: _up3Controller.text,
                                        ulp: _ulpController.text,
                                        penyulang: _penyulangController.text,
                                        zonaProteksi: _zonaProteksiController.text,
                                        section: _sectionController.text,
                                        kmsAset: _kmsAsetController.text,
                                        vendor: _vendorController.text,
                                        parentId: int.tryParse(_up3Controller.text) ?? 0,
                                        unitId: int.tryParse(_ulpController.text) ?? 0,
                                        asetJtmId: int.tryParse(_kmsAsetController.text) ?? 0,
                                        scheduleDate: DateTime(int.parse(dateParts[2]),
                                            int.parse(dateParts[1]), int.parse(dateParts[0])),
                                        prioritas: _selectedPrioritas ?? 1,
                                        namaPohon: _selectedNamaPohon ?? '',
                                        fotoPohon: '',
                                        koordinat: _coordinatesController.text,
                                        tujuanPenjadwalan: _selectedTujuan ?? 1,
                                        catatan: _noteController.text,
                                        createdBy: 1,
                                        createdDate: DateTime.now(),
                                        growthRate: DataPohon.growthRates[_selectedNamaPohon!]!,
                                        initialHeight: 0,
                                        notificationDate: DateTime.now(),
                                      );

                                      await Provider.of<DataPohonProvider>(context,
                                              listen: false)
                                          .addPohon(pohon, _fotoPohon);
                                      final notifMsg =
                                          '${_selectedNamaPohon ?? ''} dengan ID ${_idController.text} baru ditambahkan dengan perkiraan tanggal penebangan ${_dateController.text}.';
                                      await Provider.of<NotificationProvider>(context,
                                              listen: false)
                                          .addNotification(
                                        AppNotification(
                                          title: 'Pohon Baru Ditambahkan',
                                          message: notifMsg,
                                          date: DateTime.now(),
                                        ),
                                      );
                                      if (!mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Sukses!',
                                              style: TextStyle(color: Colors.green)),
                                          content:
                                              const Text('Data pohon berhasil disimpan.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Gagal!',
                                              style: TextStyle(color: Colors.red)),
                                          content: Text(
                                              'Terjadi kesalahan saat menyimpan data:\n${e.toString()}'),
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
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Simpan',
                                style:
                                    TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}