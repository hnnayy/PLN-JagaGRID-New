import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../providers/eksekusi_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/growth_prediction.dart';

class EksekusiPage extends StatefulWidget {
  final DataPohon pohon;

  const EksekusiPage({super.key, required this.pohon});

  @override
  _EksekusiPageState createState() => _EksekusiPageState();
}

class _EksekusiPageState extends State<EksekusiPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAction = 'Tebang Pangkas';
  // FIX: Pre-fill dikosongkan — teknisi wajib input tinggi setelah dipangkas
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _diameterController = TextEditingController(text: '200');
  final TextEditingController _dateController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  DateTime? _latestPlannedDate;
  bool _accessChecked = false;
  bool _isAllowed = true;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.pohon.tujuanPenjadwalan == 1
        ? 'Tebang Pangkas'
        : widget.pohon.tujuanPenjadwalan == 2
            ? 'Tebang Habis'
            : 'Tebang Pangkas';
    // FIX: Tidak pre-fill tinggi dari initialHeight
    // Teknisi harus input sendiri tinggi pohon setelah dipangkas
    _prefillExecutionDate();
    _checkAccess();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _diameterController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';
      bool allowed = true;
      if (level == 2) {
        allowed = (widget.pohon.up3 == sessionUnit || widget.pohon.ulp == sessionUnit);
      }
      setState(() {
        _isAllowed = allowed;
        _accessChecked = true;
      });
      if (!allowed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akses ditolak: pohon bukan dalam unit Anda')),
          );
          Navigator.of(context).maybePop();
        });
      }
    } catch (_) {
      setState(() {
        _isAllowed = true;
        _accessChecked = true;
      });
    }
  }

  Future<void> _prefillExecutionDate() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('growth_predictions')
          .where('data_pohon_id', isEqualTo: widget.pohon.id)
          .where('status', isEqualTo: 1)
          .get();
      if (snap.docs.isEmpty) {
        _latestPlannedDate = widget.pohon.scheduleDate;
        _dateController.text = _formatDate(_latestPlannedDate!);
        return;
      }
      final preds = snap.docs
          .map((d) => GrowthPrediction.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
      _latestPlannedDate = preds.first.predictedNextExecution;
      _dateController.text = _formatDate(_latestPlannedDate!);
      setState(() {});
    } catch (_) {
      _latestPlannedDate = widget.pohon.scheduleDate;
      _dateController.text = _formatDate(_latestPlannedDate!);
    }
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
                    setState(() => _selectedImage = File(image.path));
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
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveEksekusi() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto setelah eksekusi wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawInput = _dateController.text.trim();
      DateTime? selectedDate;
      try {
        selectedDate = DateFormat('dd/MM/yyyy').parseStrict(rawInput);
      } catch (_) {
        selectedDate = null;
      }
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal eksekusi tidak valid. Gunakan format DD/MM/YYYY.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final formattedTanggalEksekusi = '${_formatDate(selectedDate)} 09:00 WITA';

      final prefs = await SharedPreferences.getInstance();
      final creatorId = prefs.getString('session_id') ?? '';

      final eksekusi = Eksekusi(
        id: '',
        dataPohonId: widget.pohon.id,
        statusEksekusi: _selectedAction == 'Tebang Pangkas' ? 1 : 2,
        tanggalEksekusi: formattedTanggalEksekusi,
        fotoSetelah: null,
        createdBy: creatorId,
        createdDate: Timestamp.now(),
        status: 1,
        tinggiPohon: double.tryParse(_heightController.text) ?? 0.0,
        diameterPohon: double.tryParse(_diameterController.text) ?? 0.0,
      );

      await Provider.of<EksekusiProvider>(context, listen: false)
          .addEksekusi(eksekusi, _selectedImage!);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAllowed) {
      return const Scaffold(body: Center(child: Text('Akses ditolak untuk pohon ini')));
    }
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
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
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
                                ),
                              ),
                            ),
                          ),
                          _infoRow('ID Pohon',
                              widget.pohon.idPohon.isNotEmpty ? widget.pohon.idPohon : 'P023',
                              screenWidth),
                          _infoRow('UP3',
                              widget.pohon.up3.isNotEmpty ? widget.pohon.up3 : '-',
                              screenWidth),
                          _infoRow('ULP',
                              widget.pohon.ulp.isNotEmpty ? widget.pohon.ulp : '-',
                              screenWidth),
                          _infoRow('Penyulang',
                              widget.pohon.penyulang.isNotEmpty ? widget.pohon.penyulang : '-',
                              screenWidth),
                          _infoRow('Zona Proteksi',
                              widget.pohon.zonaProteksi.isNotEmpty ? widget.pohon.zonaProteksi : '-',
                              screenWidth),
                          _infoRow('Section',
                              widget.pohon.section.isNotEmpty ? widget.pohon.section : '-',
                              screenWidth),
                          _infoRow('KMS Aset',
                              widget.pohon.kmsAset.isNotEmpty ? widget.pohon.kmsAset : '-',
                              screenWidth),
                          _infoRow('Vendor',
                              widget.pohon.vendor.isNotEmpty ? widget.pohon.vendor : '-',
                              screenWidth),
                          _infoRow('Koordinat',
                              widget.pohon.koordinat.isNotEmpty ? widget.pohon.koordinat : '-',
                              screenWidth),
                          _infoRow('Tanggal Penjadwalan',
                              _formatDate(_latestPlannedDate ?? widget.pohon.scheduleDate),
                              screenWidth),
                          _infoRow(
                              'Tujuan Penjadwalan',
                              widget.pohon.tujuanPenjadwalan == 1
                                  ? 'Tebang Pangkas'
                                  : widget.pohon.tujuanPenjadwalan == 2
                                      ? 'Tebang Habis'
                                      : 'Tidak diketahui',
                              screenWidth),
                          _infoRow('Laju Pertumbuhan',
                              '${widget.pohon.growthRate} cm/tahun', screenWidth),
                          _infoRow('Tinggi Awal',
                              '${widget.pohon.initialHeight} m', screenWidth),
                          _infoRow('Catatan',
                              widget.pohon.catatan.isNotEmpty ? widget.pohon.catatan : '-',
                              screenWidth),
                          _infoRow('Nama Pohon',
                              widget.pohon.namaPohon.isNotEmpty ? widget.pohon.namaPohon : '-',
                              screenWidth),
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
                          // FIX: Label diubah menjadi "Tinggi Pohon Setelah Dipangkas"
                          // Pre-fill dikosongkan — teknisi wajib input sendiri
                          Row(
                            children: [
                              const Icon(Icons.height, size: 20),
                              const SizedBox(width: 5),
                              const Text('Tinggi Pohon Setelah Dipangkas'),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: screenWidth * 0.2,
                                child: TextFormField(
                                  controller: _heightController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Contoh: 4.5',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    final h = double.tryParse(value);
                                    if (h == null) return 'Angka tidak valid';
                                    if (h <= 0) return 'Harus > 0';
                                    if (h > 10) return 'Maks 10 m';
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
                                    hintText: 'DD/MM/YYYY',
                                  ),
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
                          const SizedBox(height: 6),
                          _ActionDropdown(
                            value: _selectedAction,
                            onChanged: (val) =>
                                setState(() => _selectedAction = val ?? _selectedAction),
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

  Widget _infoRow(String label, String value, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.04),
              softWrap: true,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ActionDropdown({required this.value, required this.onChanged});

  @override
  State<_ActionDropdown> createState() => _ActionDropdownState();
}

class _ActionDropdownState extends State<_ActionDropdown>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  final List<String> _items = const ['Tebang Pangkas', 'Tebang Habis'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() => isExpanded ? _closeDropdown() : _openDropdown();

  void _openDropdown() {
    setState(() => isExpanded = true);
    _controller.forward();

    final renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.scale(
                scaleY: _controller.value,
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _items.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () {
                        widget.onChanged(_items[index]);
                        _closeDropdown();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.value == _items[index]
                              ? const Color(0xFFF0F9FF)
                              : null,
                        ),
                        child: Text(
                          _items[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.value == _items[index]
                                ? const Color(0xFF2E5D6F)
                                : Colors.black87,
                            fontWeight: widget.value == _items[index]
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() => isExpanded = false);
    _controller.reverse().then((_) => _overlayEntry?.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _dropdownKey,
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? 'Pilih aksi',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}