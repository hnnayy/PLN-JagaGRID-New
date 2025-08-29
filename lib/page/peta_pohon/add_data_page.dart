import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  final _treeNameController = TextEditingController();
  final _coordinatesController = TextEditingController();
  final _explanationController = TextEditingController();
  final _noteController = TextEditingController();
  final _priorityController = TextEditingController();
  File? _fotoPohon;

  InputDecoration _buildInputDecoration(String label, String hint, {Icon? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFD3E0EA),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w400),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.black54, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
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
    _treeNameController.dispose();
    _coordinatesController.dispose();
    _explanationController.dispose();
    _noteController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Data Pohon', style: TextStyle(color: Color(0xFFEFE62E), fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFEFE62E)), onPressed: () => Navigator.pop(context)),
        backgroundColor: const Color(0xFF125E72),
      ),
      body: Container(
        color: const Color(0xFF125E72),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Id Pohon', 'Masukkan ID pohon'),
                validator: (value) => value!.isEmpty ? 'ID wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _up3Controller,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('UP3', 'Masukkan UP3'),
                validator: (value) => value!.isEmpty ? 'UP3 wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ulpController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('ULP', 'Masukkan ULP'),
                validator: (value) => value!.isEmpty ? 'ULP wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _penyulangController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Penyulang', 'Masukkan Penyulang'),
                validator: (value) => value!.isEmpty ? 'Penyulang wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _zonaProteksiController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Zona Proteksi', 'Masukkan Zona Proteksi'),
                validator: (value) => value!.isEmpty ? 'Zona Proteksi wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sectionController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Section', 'Masukkan section'),
                validator: (value) => value!.isEmpty ? 'Section wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _kmsAsetController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Kms Aset', 'Masukkan Kms Aset'),
                validator: (value) => value!.isEmpty ? 'Kms Aset wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vendorController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Vendor VB', 'Masukkan vendor'),
                validator: (value) => value!.isEmpty ? 'Vendor wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.datetime,
                decoration: _buildInputDecoration('Tanggal Penjadwalan', 'Pilih tanggal', suffixIcon: const Icon(Icons.calendar_today, color: Colors.black)),
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
                            style: TextButton.styleFrom(foregroundColor: Color(0xFF125E72)),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    _dateController.text = "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _treeNameController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Nama Pohon', 'Masukkan nama pohon'),
                validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() {
                      _fotoPohon = File(picked.path);
                    });
                  }
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
                      const Icon(Icons.camera_alt, size: 32, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        _fotoPohon == null ? 'Foto Pohon' : 'Foto Dipilih',
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _coordinatesController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.text,
                decoration: _buildInputDecoration('Koordinat', 'Pilih koordinat', suffixIcon: const Icon(Icons.location_on, color: Colors.black)),
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'Koordinat wajib diisi' : null,
                onTap: () async {
                  final String? selectedCoord = await Navigator.push(context, MaterialPageRoute(builder: (_) => PickLocationPage()));
                  if (selectedCoord != null) {
                    _coordinatesController.text = selectedCoord;
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _explanationController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Tujuan Penjadwalan', 'Masukkan tujuan penjadwalan (1 atau 2)'),
                validator: (value) => value!.isEmpty ? 'Tujuan wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priorityController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Prioritas', 'Masukkan prioritas (1, 2, 3)'),
                validator: (value) => value!.isEmpty ? 'Prioritas wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                keyboardType: TextInputType.multiline,
                decoration: _buildInputDecoration('Catatan', 'Masukkan catatan'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFE62E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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
                            scheduleDate: DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0])),
                            prioritas: int.tryParse(_priorityController.text) ?? 1,
                            namaPohon: _treeNameController.text,
                            fotoPohon: '',
                            koordinat: _coordinatesController.text,
                            tujuanPenjadwalan: int.tryParse(_explanationController.text) ?? 1,
                            catatan: _noteController.text,
                            createdBy: 1,
                            createdDate: DateTime.now(),
                          );

                          await Provider.of<DataPohonProvider>(context, listen: false).addPohon(pohon, _fotoPohon);
                          if (!mounted) return;
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Sukses!', style: TextStyle(color: Colors.green)),
                              content: const Text('Data pohon berhasil disimpan.'),
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
                      }
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}