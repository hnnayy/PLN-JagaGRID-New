// ═══════════════════════════════════════════════════════════
// PERUBAHAN DI add_data_page.dart
// Hanya bagian onPressed Simpan yang perlu diupdate
// Ganti bagian notifikasi di dalam try block _validateAllFields()
// ═══════════════════════════════════════════════════════════
//
// CARI bagian ini di add_data_page.dart:
//
//   final notifProvider = Provider.of<NotificationProvider>(
//       context, listen: false);
//
//   await notifProvider.addNotification(
//     AppNotification(
//       title: 'Pohon Baru Ditambahkan',
//       message: '${_selectedNamaPohon ?? ''} dengan ID ...',
//       ...
//     ),
//     documentIdPohon: documentId,
//   );
//
// GANTI DENGAN:
// ═══════════════════════════════════════════════════════════

/*
  final notifProvider =
      Provider.of<NotificationProvider>(context, listen: false);

  // Helper title case
  String toTitleCase(String s) => s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');

  final ulpFormatted = toTitleCase(_ulpController.text.trim());
  final dateFormatted = _dateController.text; // sudah format d-M-y

  // ── Notif APP — ringkas, tanpa Markdown ──
  final appTitle = '🌱 Pohon Baru — ${_selectedNamaPohon ?? ''}';
  final appMessage =
      '${_idController.text} • $ulpFormatted • $dateFormatted';

  // ── Telegram — profesional, Markdown ──
  final telegramMessage =
'🌱 *Pohon Baru Ditambahkan*\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'Pohon      : ${_selectedNamaPohon ?? '-'}\n'
'ID         : ${_idController.text}\n'
'ULP        : $ulpFormatted\n'
'Jadwal     : $dateFormatted\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'_PLN JagaGRID_';

  // Kirim notif app (ringkas)
  await notifProvider.addNotification(
    AppNotification(
      title: appTitle,
      message: appMessage,
      date: DateTime.now(),
      idPohon: _idController.text,
    ),
    documentIdPohon: documentId,
  );

  // Kirim Telegram (profesional + tombol Maps)
  await notifProvider.sendTelegramMessageForTree(
    telegramMessage,
    dataPohonId: documentId,
    koordinat: _coordinatesController.text,
  );
*/

// ═══════════════════════════════════════════════════════════
// VERSI LENGKAP FILE add_data_page.dart
// (copy paste seluruh file ini)
// ═══════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../providers/data_pohon_provider.dart';
import '../../models/data_pohon.dart';
import '../../services/asset_service.dart';
import 'pick_location_page.dart';
import '../../providers/tree_growth_provider.dart';
import '../../models/tree_growth.dart';

class DropdownCoordinator {
  static VoidCallback? _closeCurrent;
  static void register(VoidCallback closeThis) {
    if (_closeCurrent != null && _closeCurrent != closeThis) {
      try { _closeCurrent!.call(); } catch (_) {}
    }
    _closeCurrent = closeThis;
  }
  static void clearIfSame(VoidCallback closeThis) {
    if (identical(_closeCurrent, closeThis)) _closeCurrent = null;
  }
  static void closeAny() {
    try { _closeCurrent?.call(); } catch (_) {}
    _closeCurrent = null;
  }
}

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;
  final String? errorText;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool isExpanded = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  bool _overlayInserted = false;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _inputController.text = widget.value ?? '';
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _openDropdown();
    });
  }

  @override
  void didUpdateWidget(CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _inputController.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    if (_overlayInserted) {
      try { _overlayEntry?.remove(); } catch (_) {}
      _overlayInserted = false;
    }
    _overlayEntry = null;
    super.dispose();
  }

  void _openDropdown() {
    if (isExpanded) return;
    DropdownCoordinator.register(_closeDropdown);
    setState(() => isExpanded = true);
    _filterItems(_inputController.text);
    final renderBox = _dropdownKey.currentContext!.findRenderObject() as RenderBox;
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
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Tidak ada hasil',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) => InkWell(
                        onTap: () {
                          _inputController.text = _filteredItems[index];
                          widget.onChanged(_filteredItems[index]);
                          _closeDropdown();
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.value == _filteredItems[index]
                                ? const Color(0xFFF0F9FF)
                                : null,
                          ),
                          child: Text(
                            _filteredItems[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.value == _filteredItems[index]
                                  ? const Color(0xFF2E5D6F)
                                  : Colors.black87,
                              fontWeight: widget.value == _filteredItems[index]
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
    );
    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);
    _overlayInserted = true;
  }

  void _closeDropdown() {
    if (!isExpanded) return;
    setState(() => isExpanded = false);
    if (_overlayInserted) {
      try { _overlayEntry?.remove(); } catch (_) {}
      _overlayInserted = false;
    }
    _overlayEntry = null;
    DropdownCoordinator.clearIfSame(_closeDropdown);
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? widget.items
          : widget.items
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _dropdownKey,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Pilih ${widget.labelText.toLowerCase()}',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: GestureDetector(
                  onTap: () {
                    if (isExpanded) {
                      _closeDropdown();
                      _focusNode.unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                  ),
                ),
              ),
              onChanged: (value) {
                _filterItems(value);
                if (!isExpanded) _openDropdown();
              },
              onTap: () {
                if (!isExpanded) _openDropdown();
              },
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(widget.errorText!,
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class AddDataPage extends StatefulWidget {
  const AddDataPage({Key? key}) : super(key: key);

  @override
  State<AddDataPage> createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _up3Controller = TextEditingController(text: 'PAREPARE');
  final _ulpController = TextEditingController();
  final _penyulangController = TextEditingController();
  final _zonaProteksiController = TextEditingController();
  final _sectionController = TextEditingController();
  final _kmsAsetController = TextEditingController();
  final _vendorController = TextEditingController();
  final _dateController = TextEditingController();
  final _coordinatesController = TextEditingController();
  final _noteController = TextEditingController();
  final _initialHeightController = TextEditingController();
  File? _fotoPohon;

  int? _selectedTujuan;
  int? _selectedPrioritas;
  String? _selectedNamaPohon;
  String? _selectedPenyulang;
  String? _selectedZonaProteksi;
  String? _selectedSection;
  String? _selectedVendor;
  bool _isLoading = false;

  final Map<int, String> _tujuanOptions = {1: 'Tebang Pangkas', 2: 'Tebang Habis'};
  final Map<int, String> _prioritasOptions = {1: 'Rendah', 2: 'Sedang', 3: 'Tinggi'};

  List<String> _penyulangOptions = [];
  List<String> _zonaProteksiOptions = [];
  List<String> _sectionOptions = [];
  List<String> _vendorOptions = [];
  bool _dropdownDataLoaded = false;

  String? _idError, _up3Error, _ulpError, _kmsAsetError, _dateError;
  String? _coordinatesError, _initialHeightError, _namaPohonError;
  String? _tujuanError, _prioritasError, _selectedPenyulangError;
  String? _selectedZonaProteksiError, _selectedSectionError;
  String? _selectedVendorError, _fotoError, _catatanError;

  String _sessionKodeUnit = '';

  // ── Helper: title case ──
  String _toTitleCase(String s) => s.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }).join(' ');

  @override
  void initState() {
    super.initState();
    _loadSessionUnit();
    _loadDropdownData();
    _initLocalNotification();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreeGrowthProvider>().load();
    });
  }

  Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings init =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: init));
  }

  Future<void> _loadDropdownData() async {
    final assetService = AssetService();
    final assets = await assetService.getAssets().first;
    setState(() {
      _penyulangOptions = assets.map((a) => a.penyulang).toSet().toList();
      _zonaProteksiOptions = assets.map((a) => a.zonaProteksi).toSet().toList();
      _sectionOptions = assets.map((a) => a.section).toSet().toList();
      _vendorOptions = assets.map((a) => a.vendorVb).toSet().toList();
      _dropdownDataLoaded = true;
    });
  }

  Future<void> _loadSessionUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ulpController.text = prefs.getString('session_unit') ?? '';
      _sessionKodeUnit = prefs.getString('session_kode_unit') ?? '';
    });
    _generateRandomIdPohon();
  }

  void _generateRandomIdPohon() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomPart = List.generate(8, (i) =>
        chars[(DateTime.now().microsecondsSinceEpoch + i * 997) % chars.length]).join();
    _idController.text = _sessionKodeUnit.isNotEmpty
        ? '${_sessionKodeUnit.toUpperCase()}-$randomPart'
        : randomPart;
  }

  void _clearAllErrors() {
    setState(() {
      _idError = _up3Error = _ulpError = _kmsAsetError = _dateError = null;
      _coordinatesError = _initialHeightError = _namaPohonError = null;
      _tujuanError = _prioritasError = _selectedPenyulangError = null;
      _selectedZonaProteksiError = _selectedSectionError = null;
      _selectedVendorError = _fotoError = _catatanError = null;
    });
  }

  bool _validateAllFields() {
    _clearAllErrors();
    bool isValid = true;

    if (_idController.text.trim().isEmpty) {
      setState(() => _idError = 'ID Pohon tidak boleh kosong');
      isValid = false;
    } else if (_idController.text.trim().length < 3) {
      setState(() => _idError = 'ID Pohon terlalu pendek');
      isValid = false;
    }
    if (_up3Controller.text.trim().isEmpty) {
      setState(() => _up3Error = 'UP3 tidak boleh kosong');
      isValid = false;
    }
    if (_ulpController.text.trim().isEmpty) {
      setState(() => _ulpError = 'ULP tidak boleh kosong');
      isValid = false;
    }
    if (_selectedPenyulang == null || _selectedPenyulang!.trim().isEmpty) {
      setState(() => _selectedPenyulangError = 'Penyulang harus dipilih');
      isValid = false;
    }
    if (_selectedZonaProteksi == null || _selectedZonaProteksi!.trim().isEmpty) {
      setState(() => _selectedZonaProteksiError = 'Zona proteksi harus dipilih');
      isValid = false;
    }
    if (_selectedSection == null || _selectedSection!.trim().isEmpty) {
      setState(() => _selectedSectionError = 'Section harus dipilih');
      isValid = false;
    }
    if (_selectedVendor == null || _selectedVendor!.trim().isEmpty) {
      setState(() => _selectedVendorError = 'Vendor harus dipilih');
      isValid = false;
    }
    if (_kmsAsetController.text.trim().isEmpty) {
      setState(() => _kmsAsetError = 'Kms Aset tidak boleh kosong');
      isValid = false;
    }
    if (_dateController.text.trim().isEmpty) {
      setState(() => _dateError = 'Tanggal penjadwalan tidak boleh kosong');
      isValid = false;
    }
    if (_coordinatesController.text.trim().isEmpty) {
      setState(() => _coordinatesError = 'Koordinat tidak boleh kosong');
      isValid = false;
    }
    if (_initialHeightController.text.trim().isEmpty) {
      setState(() => _initialHeightError = 'Tinggi awal tidak boleh kosong');
      isValid = false;
    } else {
      final height = double.tryParse(_initialHeightController.text.trim());
      if (height == null) {
        setState(() => _initialHeightError = 'Masukkan angka yang valid');
        isValid = false;
      } else if (height <= 0) {
        setState(() => _initialHeightError = 'Tinggi awal harus lebih dari 0');
        isValid = false;
      } else if (height > 10.0) {
        setState(() => _initialHeightError = 'Tinggi tidak wajar, maksimal 10 meter');
        isValid = false;
      }
    }
    if (_selectedNamaPohon == null) {
      setState(() => _namaPohonError = 'Nama pohon harus dipilih');
      isValid = false;
    }
    if (_selectedTujuan == null) {
      setState(() => _tujuanError = 'Tujuan penjadwalan harus dipilih');
      isValid = false;
    }
    if (_selectedPrioritas == null) {
      setState(() => _prioritasError = 'Prioritas harus dipilih');
      isValid = false;
    }
    if (_fotoPohon == null) {
      setState(() => _fotoError = 'Foto pohon harus dipilih');
      isValid = false;
    }
    if (_noteController.text.trim().isEmpty) {
      setState(() => _catatanError = 'Catatan tidak boleh kosong');
      isValid = false;
    }
    return isValid;
  }

  Widget _buildField(String label, TextEditingController controller, {
    bool readOnly = false,
    Icon? suffixIcon,
    void Function()? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText,
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<String?> _getCurrentLocation() async {
    try {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')));
        return null;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return '${position.latitude},${position.longitude}';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil lokasi: $e')));
      return null;
    }
  }

  Future<void> _showSuccessAlert() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85, height: 85,
                decoration: const BoxDecoration(
                    color: Color(0xFF2E5D6F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    size: 55, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Berhasil!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5D6F))),
              const SizedBox(height: 10),
              Text('Data pohon berhasil ditambahkan ke sistem',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pop(context);
                  },
                  child: const Text('OK',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showErrorAlert(String errorMessage) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85, height: 85,
                decoration: BoxDecoration(
                    color: Colors.red.shade600, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Gagal!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600)),
              const SizedBox(height: 10),
              Text('Gagal menyimpan, perbaiki kesalahan',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
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
    _coordinatesController.dispose();
    _noteController.dispose();
    _initialHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d-M-y');

    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5D6F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tambah Data Pohon',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildField('Id Pohon', _idController,
                  readOnly: true, errorText: _idError),
              const SizedBox(height: 20),
              _buildField('UP3', _up3Controller,
                  readOnly: true, errorText: _up3Error),
              const SizedBox(height: 20),
              _buildField('ULP', _ulpController,
                  readOnly: true, errorText: _ulpError),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedPenyulang,
                      items: _penyulangOptions,
                      labelText: 'Penyulang',
                      onChanged: (v) => setState(() {
                        _selectedPenyulang = v;
                        _penyulangController.text = v ?? '';
                      }),
                      errorText: _selectedPenyulangError,
                    ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedZonaProteksi,
                      items: _zonaProteksiOptions,
                      labelText: 'Zona Proteksi',
                      onChanged: (v) => setState(() {
                        _selectedZonaProteksi = v;
                        _zonaProteksiController.text = v ?? '';
                      }),
                      errorText: _selectedZonaProteksiError,
                    ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedSection,
                      items: _sectionOptions,
                      labelText: 'Section',
                      onChanged: (v) => setState(() {
                        _selectedSection = v;
                        _sectionController.text = v ?? '';
                      }),
                      errorText: _selectedSectionError,
                    ),
              const SizedBox(height: 20),
              _buildField('Kms Aset', _kmsAsetController,
                  errorText: _kmsAsetError),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedVendor,
                      items: _vendorOptions,
                      labelText: 'Vendor VB',
                      onChanged: (v) => setState(() {
                        _selectedVendor = v;
                        _vendorController.text = v ?? '';
                      }),
                      errorText: _selectedVendorError,
                    ),
              const SizedBox(height: 20),
              _buildField(
                'Tanggal Penjadwalan',
                _dateController,
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF2E5D6F),
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                              foregroundColor: Color(0xFF2E5D6F)),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    _dateController.text = dateFormat.format(pickedDate);
                  }
                },
                errorText: _dateError,
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<TreeGrowth>>(
                stream: context.read<TreeGrowthProvider>().watchAll(),
                builder: (context, snapshot) {
                  List<String> treeNames = snapshot.hasData
                      ? (snapshot.data!.map((e) => e.name).toSet().toList()..sort())
                      : [];
                  return CustomDropdown(
                    value: _selectedNamaPohon,
                    items: treeNames,
                    labelText: 'Nama Pohon',
                    onChanged: (v) => setState(() => _selectedNamaPohon = v),
                    errorText: _namaPohonError,
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildField('Tinggi Awal (dalam meter)', _initialHeightController,
                  keyboardType: TextInputType.number,
                  errorText: _initialHeightError),
              const SizedBox(height: 20),
              // ── Foto Pohon ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foto Pohon',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Pilih Sumber Foto',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt, size: 32),
                                  title: const Text('Ambil Foto',
                                      style: TextStyle(fontSize: 18)),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                        source: ImageSource.camera);
                                    if (picked != null) {
                                      setState(() =>
                                          _fotoPohon = File(picked.path));
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  leading: const Icon(Icons.photo_library,
                                      size: 32),
                                  title: const Text('Pilih dari Galeri',
                                      style: TextStyle(fontSize: 18)),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(() =>
                                          _fotoPohon = File(picked.path));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _fotoPohon == null
                                ? Icons.camera_alt
                                : Icons.check_circle,
                            size: 28,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fotoPohon == null
                                  ? 'Pilih Foto Pohon'
                                  : 'Foto Dipilih',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_fotoError != null) ...[
                    const SizedBox(height: 8),
                    Text(_fotoError!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              // ── Koordinat ──
              _buildField(
                'Koordinat',
                _coordinatesController,
                readOnly: true,
                suffixIcon: const Icon(Icons.location_on, color: Colors.grey),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pilih Sumber Koordinat',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: const Icon(Icons.map, size: 32),
                              title: const Text('Pilih dari Peta',
                                  style: TextStyle(fontSize: 18)),
                              onTap: () async {
                                Navigator.pop(context);
                                final String? selectedCoord =
                                    await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PickLocationPage()),
                                );
                                if (selectedCoord != null) {
                                  setState(() => _coordinatesController
                                      .text = selectedCoord);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading:
                                  const Icon(Icons.my_location, size: 32),
                              title: const Text('Gunakan Lokasi Saat Ini',
                                  style: TextStyle(fontSize: 18)),
                              onTap: () async {
                                Navigator.pop(context);
                                final String? currentCoord =
                                    await _getCurrentLocation();
                                if (currentCoord != null) {
                                  setState(() => _coordinatesController
                                      .text = currentCoord);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                errorText: _coordinatesError,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedTujuan != null
                    ? _tujuanOptions[_selectedTujuan]
                    : null,
                items: _tujuanOptions.values.toList(),
                labelText: 'Tujuan Penjadwalan',
                onChanged: (v) => setState(() {
                  _selectedTujuan = _tujuanOptions.entries
                      .firstWhere((e) => e.value == v,
                          orElse: () => const MapEntry(1, ''))
                      .key;
                }),
                errorText: _tujuanError,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedPrioritas != null
                    ? _prioritasOptions[_selectedPrioritas]
                    : null,
                items: _prioritasOptions.values.toList(),
                labelText: 'Prioritas',
                onChanged: (v) => setState(() {
                  _selectedPrioritas = _prioritasOptions.entries
                      .firstWhere((e) => e.value == v,
                          orElse: () => const MapEntry(1, ''))
                      .key;
                }),
                errorText: _prioritasError,
              ),
              const SizedBox(height: 20),
              _buildField('Catatan', _noteController,
                  errorText: _catatanError),
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
                          side: const BorderSide(
                              color: Color(0xFF2E5D6F), width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
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
                                if (_validateAllFields()) {
                                  setState(() => _isLoading = true);
                                  try {
                                    final formatter = DateFormat('d-M-y');
                                    final parsedDate =
                                        formatter.parse(_dateController.text);
                                    final scheduleDate = DateTime(
                                        parsedDate.year,
                                        parsedDate.month,
                                        parsedDate.day);

                                    final initialHeight = double.parse(
                                        _initialHeightController.text);

                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final creatorId =
                                        prefs.getString('session_id') ?? '';

                                    double selectedGrowth = 0;
                                    final provider =
                                        context.read<TreeGrowthProvider>();
                                    final trees =
                                        await provider.watchAll().first;
                                    if (trees.isNotEmpty &&
                                        _selectedNamaPohon != null) {
                                      final match = trees.firstWhere(
                                        (e) => e.name == _selectedNamaPohon,
                                        orElse: () => trees.first,
                                      );
                                      selectedGrowth = match.growthRate;
                                    }

                                    final pohon = DataPohon(
                                      id: '',
                                      idPohon: _idController.text,
                                      up3: _up3Controller.text,
                                      ulp: _ulpController.text,
                                      penyulang: _penyulangController.text,
                                      zonaProteksi:
                                          _zonaProteksiController.text,
                                      section: _sectionController.text,
                                      kmsAset: _kmsAsetController.text,
                                      vendor: _vendorController.text,
                                      asetJtmId: int.tryParse(
                                              _kmsAsetController.text) ??
                                          0,
                                      scheduleDate: scheduleDate,
                                      prioritas: _selectedPrioritas ?? 1,
                                      namaPohon: _selectedNamaPohon ?? '',
                                      fotoPohon: '',
                                      koordinat: _coordinatesController.text,
                                      tujuanPenjadwalan:
                                          _selectedTujuan ?? 1,
                                      catatan: _noteController.text,
                                      createdBy: creatorId,
                                      createdDate: DateTime.now(),
                                      growthRate: selectedGrowth,
                                      initialHeight: initialHeight,
                                      notificationDate: scheduleDate
                                          .subtract(const Duration(days: 3)),
                                    );

                                    final documentId =
                                        await Provider.of<DataPohonProvider>(
                                                context,
                                                listen: false)
                                            .addPohon(pohon, _fotoPohon);

                                    final notifProvider =
                                        Provider.of<NotificationProvider>(
                                            context,
                                            listen: false);

                                    final ulpFormatted =
                                        _toTitleCase(_ulpController.text.trim());

                                    // ── Notif APP — ringkas ──
                                    final appTitle =
                                        '🌱 Pohon Baru — ${_selectedNamaPohon ?? ''}';
                                    final appMessage =
                                        '${_idController.text} • $ulpFormatted • ${_dateController.text}';

                                    // ── Telegram — profesional ──
                                    final telegramMessage =
                                        '🌱 *Pohon Baru Ditambahkan*\n'
                                        '━━━━━━━━━━━━━━━━━━━━\n'
                                        'Pohon      : ${_selectedNamaPohon ?? '-'}\n'
                                        'ID         : ${_idController.text}\n'
                                        'ULP        : $ulpFormatted\n'
                                        'Jadwal     : ${_dateController.text}\n'
                                        '━━━━━━━━━━━━━━━━━━━━\n'
                                        '_PLN JagaGRID_';

                                    // Notif app (ringkas)
                                    await notifProvider.addNotification(
                                      AppNotification(
                                        title: appTitle,
                                        message: appMessage,
                                        date: DateTime.now(),
                                        idPohon: _idController.text,
                                      ),
                                      documentIdPohon: documentId,
                                    );

                                    // Telegram (profesional + tombol Maps)
                                    await notifProvider
                                        .sendTelegramMessageForTree(
                                      telegramMessage,
                                      dataPohonId: documentId,
                                      koordinat: _coordinatesController.text,
                                    );

                                    if (!mounted) return;
                                    await _requestNotificationPermission();
                                    await _showSuccessAlert();
                                  } catch (e) {
                                    if (!mounted) return;
                                    await _showErrorAlert(e.toString());
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Simpan',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
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