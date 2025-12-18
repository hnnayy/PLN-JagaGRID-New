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

// Simple coordinator to ensure only one dropdown is open at a time across the page
class DropdownCoordinator {
  static VoidCallback? _closeCurrent;

  static void register(VoidCallback closeThis) {
    if (_closeCurrent != null && _closeCurrent != closeThis) {
      try {
        _closeCurrent!.call();
      } catch (_) {}
    }
    _closeCurrent = closeThis;
  }

  static void clearIfSame(VoidCallback closeThis) {
    if (identical(_closeCurrent, closeThis)) {
      _closeCurrent = null;
    }
  }

  static void closeAny() {
    try {
      _closeCurrent?.call();
    } catch (_) {}
    _closeCurrent = null;
  }
}

// CustomDropdown Widget - DIKETIK LANGSUNG DI KOLOM BIRU (COMBOBOX STYLE)
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
  
  // Controller untuk input text di kolom biru
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _inputController.text = widget.value ?? '';
    
    // Listen ketika user mulai mengetik
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      }
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
    
    // Filter items based on current input
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
                      child: Text(
                        'Tidak ada hasil',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
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
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
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
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                  ),
                ),
              ),
              onChanged: (value) {
                _filterItems(value);
                if (!isExpanded) {
                  _openDropdown();
                }
              },
              onTap: () {
                if (!isExpanded) {
                  _openDropdown();
                }
              },
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
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

  final Map<int, String> _tujuanOptions = {
    1: 'Tebang Pangkas',
    2: 'Tebang Habis',
  };

  final Map<int, String> _prioritasOptions = {
    1: 'Rendah',
    2: 'Sedang',
    3: 'Tinggi',
  };

  List<String> _penyulangOptions = [];
  List<String> _zonaProteksiOptions = [];
  List<String> _sectionOptions = [];
  List<String> _vendorOptions = [];
  bool _dropdownDataLoaded = false;

  // Error messages for inline validation
  String? _idError;
  String? _up3Error;
  String? _ulpError;
  String? _kmsAsetError;
  String? _dateError;
  String? _coordinatesError;
  String? _initialHeightError;
  String? _namaPohonError;
  String? _tujuanError;
  String? _prioritasError;
  String? _selectedPenyulangError;
  String? _selectedZonaProteksiError;
  String? _selectedSectionError;
  String? _selectedVendorError;
  String? _fotoError;
  String? _catatanError;

  @override
  void initState() {
    super.initState();
    _generateRandomIdPohon();
    _loadSessionUnit();
    _loadDropdownData();
    _initLocalNotification();
    // Load master tree growth list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreeGrowthProvider>().load();
    });
  }

  Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadDropdownData() async {
    final assetService = AssetService();
    final assets = await assetService.getAssets().first;
    setState(() {
      _penyulangOptions = assets.map((asset) => asset.penyulang).toSet().toList();
      _zonaProteksiOptions = assets.map((asset) => asset.zonaProteksi).toSet().toList();
      _sectionOptions = assets.map((asset) => asset.section).toSet().toList();
      _vendorOptions = assets.map((asset) => asset.vendorVb).toSet().toList();
      _dropdownDataLoaded = true;
    });
  }

  void _generateRandomIdPohon() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomId = List.generate(
        8, (index) => chars[(DateTime.now().microsecondsSinceEpoch + index * 997) % chars.length]).join();
    randomId = randomId + DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    randomId = randomId.substring(0, 8);
    _idController.text = randomId;
  }

  Future<void> _loadSessionUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final unit = prefs.getString('session_unit') ?? '';
    setState(() {
      _ulpController.text = unit;
    });
  }

  void _clearAllErrors() {
    setState(() {
      _idError = null;
      _up3Error = null;
      _ulpError = null;
      _kmsAsetError = null;
      _dateError = null;
      _coordinatesError = null;
      _initialHeightError = null;
      _namaPohonError = null;
      _tujuanError = null;
      _prioritasError = null;
      _selectedPenyulangError = null;
      _selectedZonaProteksiError = null;
      _selectedSectionError = null;
      _selectedVendorError = null;
      _fotoError = null;
      _catatanError = null;
    });
  }

  bool _validateAllFields() {
    _clearAllErrors();
    bool isValid = true;

    // Validate ID Pohon
    if (_idController.text.trim().isEmpty) {
      setState(() => _idError = 'ID Pohon tidak boleh kosong');
      isValid = false;
    } else if (_idController.text.trim().length < 3) {
      setState(() => _idError = 'ID Pohon terlalu pendek');
      isValid = false;
    }

    // Validate UP3
    if (_up3Controller.text.trim().isEmpty) {
      setState(() => _up3Error = 'UP3 tidak boleh kosong');
      isValid = false;
    } else if (_up3Controller.text.trim().length < 2) {
      setState(() => _up3Error = 'Nama UP3 terlalu pendek');
      isValid = false;
    }

    // Validate ULP
    if (_ulpController.text.trim().isEmpty) {
      setState(() => _ulpError = 'ULP tidak boleh kosong');
      isValid = false;
    } else if (_ulpController.text.trim().length < 2) {
      setState(() => _ulpError = 'Nama ULP terlalu pendek');
      isValid = false;
    }

    // Validate Penyulang
    if (_selectedPenyulang == null || _selectedPenyulang!.trim().isEmpty) {
      setState(() => _selectedPenyulangError = 'Penyulang harus dipilih');
      isValid = false;
    }

    // Validate Zona Proteksi
    if (_selectedZonaProteksi == null || _selectedZonaProteksi!.trim().isEmpty) {
      setState(() => _selectedZonaProteksiError = 'Zona proteksi harus dipilih');
      isValid = false;
    }

    // Validate Section
    if (_selectedSection == null || _selectedSection!.trim().isEmpty) {
      setState(() => _selectedSectionError = 'Section harus dipilih');
      isValid = false;
    }

    // Validate Vendor
    if (_selectedVendor == null || _selectedVendor!.trim().isEmpty) {
      setState(() => _selectedVendorError = 'Vendor harus dipilih');
      isValid = false;
    }

    // Validate KMS Aset (wajib)
    if (_kmsAsetController.text.trim().isEmpty) {
      setState(() => _kmsAsetError = 'Kms Aset tidak boleh kosong');
      isValid = false;
    }

    // Validate Date
    if (_dateController.text.trim().isEmpty) {
      setState(() => _dateError = 'Tanggal penjadwalan tidak boleh kosong');
      isValid = false;
    }

    // Validate Coordinates
    if (_coordinatesController.text.trim().isEmpty) {
      setState(() => _coordinatesError = 'Koordinat tidak boleh kosong');
      isValid = false;
    }

    // Validate Initial Height
    if (_initialHeightController.text.trim().isEmpty) {
      setState(() => _initialHeightError = 'Tinggi awal tidak boleh kosong');
      isValid = false;
    } else {
      double? height = double.tryParse(_initialHeightController.text.trim());
      if (height == null) {
        setState(() => _initialHeightError = 'Masukkan angka yang valid');
        isValid = false;
      } else if (height <= 0) {
        setState(() => _initialHeightError = 'Tinggi awal harus lebih dari 0');
        isValid = false;
      }
    }

    // Validate Nama Pohon
    if (_selectedNamaPohon == null) {
      setState(() => _namaPohonError = 'Nama pohon harus dipilih');
      isValid = false;
    }

    // Validate Tujuan
    if (_selectedTujuan == null) {
      setState(() => _tujuanError = 'Tujuan penjadwalan harus dipilih');
      isValid = false;
    }

    // Validate Prioritas
    if (_selectedPrioritas == null) {
      setState(() => _prioritasError = 'Prioritas harus dipilih');
      isValid = false;
    }

    // Validate Selected Penyulang
    if (_selectedPenyulang == null) {
      setState(() => _selectedPenyulangError = 'Penyulang harus dipilih');
      isValid = false;
    }

    // Validate Selected Zona Proteksi
    if (_selectedZonaProteksi == null) {
      setState(() => _selectedZonaProteksiError = 'Zona proteksi harus dipilih');
      isValid = false;
    }

    // Validate Selected Section
    if (_selectedSection == null) {
      setState(() => _selectedSectionError = 'Section harus dipilih');
      isValid = false;
    }

    // Validate Selected Vendor
    if (_selectedVendor == null) {
      setState(() => _selectedVendorError = 'Vendor harus dipilih');
      isValid = false;
    }

    // Validate Foto
    if (_fotoPohon == null) {
      setState(() => _fotoError = 'Foto pohon harus dipilih');
      isValid = false;
    }

    // Validate Catatan
    if (_noteController.text.trim().isEmpty) {
      setState(() => _catatanError = 'Catatan tidak boleh kosong');
      isValid = false;
    }

    return isValid;
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool readOnly = false, Icon? suffixIcon, void Function()? onTap, String? Function(String?)? validator, TextInputType? keyboardType, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
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
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
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
          const SnackBar(content: Text('Izin lokasi ditolak. Tidak dapat mengambil lokasi saat ini.')),
        );
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
      return null;
    }
  }

  // Method untuk menampilkan success alert
  Future<void> _showSuccessAlert() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                "Data pohon berhasil ditambahkan ke sistem",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method untuk menampilkan error alert dengan style merah
  Future<void> _showErrorAlert(String errorMessage) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Gagal!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Gagal menyimpan, perbaiki kesalahan",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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
    final dateFormat = DateFormat('d-M-y'); // Format d-M-y for UI
    
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
        title: const Text(
          "Tambah Data Pohon",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
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
              _buildField(
                'Id Pohon',
                _idController,
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'ID wajib diisi' : null,
                errorText: _idError,
              ),
              const SizedBox(height: 20),
              _buildField(
                'UP3',
                _up3Controller,
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'UP3 wajib diisi' : null,
                errorText: _up3Error,
              ),
              const SizedBox(height: 20),
              _buildField(
                'ULP',
                _ulpController,
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'ULP wajib diisi' : null,
                errorText: _ulpError,
              ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedPenyulang,
                      items: _penyulangOptions,
                      labelText: 'Penyulang',
                      onChanged: (value) {
                        setState(() {
                          _selectedPenyulang = value;
                          _penyulangController.text = value ?? '';
                        });
                      },
                      errorText: _selectedPenyulangError,
                    ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedZonaProteksi,
                      items: _zonaProteksiOptions,
                      labelText: 'Zona Proteksi',
                      onChanged: (value) {
                        setState(() {
                          _selectedZonaProteksi = value;
                          _zonaProteksiController.text = value ?? '';
                        });
                      },
                      errorText: _selectedZonaProteksiError,
                    ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedSection,
                      items: _sectionOptions,
                      labelText: 'Section',
                      onChanged: (value) {
                        setState(() {
                          _selectedSection = value;
                          _sectionController.text = value ?? '';
                        });
                      },
                      errorText: _selectedSectionError,
                    ),
              const SizedBox(height: 20),
              _buildField(
                'Kms Aset',
                _kmsAsetController,
                validator: (value) => value!.isEmpty ? 'Kms Aset wajib diisi' : null,
                errorText: _kmsAsetError,
              ),
              const SizedBox(height: 20),
              !_dropdownDataLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomDropdown(
                      value: _selectedVendor,
                      items: _vendorOptions,
                      labelText: 'Vendor VB',
                      onChanged: (value) {
                        setState(() {
                          _selectedVendor = value;
                          _vendorController.text = value ?? '';
                        });
                      },
                      errorText: _selectedVendorError,
                    ),
              const SizedBox(height: 20),
              _buildField(
                'Tanggal Penjadwalan',
                _dateController,
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
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
                            primary: Color(0xFF2E5D6F),
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(foregroundColor: Color(0xFF2E5D6F)),
                          ),
                        ),
                        child: child!,
                      );
                    },
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
                  List<String> treeNames;
                  if (snapshot.hasData) {
                    treeNames = snapshot.data!.map((e) => e.name).toSet().toList();
                    treeNames.sort();
                  } else {
                    treeNames = <String>[];
                  }
                  
                  return CustomDropdown(
                    value: _selectedNamaPohon,
                    items: treeNames,
                    labelText: 'Nama Pohon',
                    onChanged: (value) {
                      setState(() {
                        _selectedNamaPohon = value;
                      });
                    },
                    errorText: _namaPohonError,
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Tinggi Awal (dalam cm)',
                _initialHeightController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Tinggi awal wajib diisi';
                  final height = double.tryParse(value);
                  if (height == null || height < 0) return 'Tinggi awal harus angka valid';
                  return null;
                },
                errorText: _initialHeightError,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Pohon',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                      final picked = await picker.pickImage(source: ImageSource.camera);
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
                                    title: const Text('Pilih dari Galeri', style: TextStyle(fontSize: 18)),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(source: ImageSource.gallery);
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
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _fotoPohon == null ? Icons.camera_alt : Icons.check_circle,
                            size: 28,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fotoPohon == null ? 'Pilih Foto Pohon' : 'Foto Dipilih',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_fotoError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _fotoError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                'Koordinat',
                _coordinatesController,
                readOnly: true,
                suffixIcon: const Icon(Icons.location_on, color: Colors.grey),
                validator: (value) => value!.isEmpty ? 'Koordinat wajib diisi' : null,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                                title: const Text('Pilih dari Peta', style: TextStyle(fontSize: 18)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final String? selectedCoord = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PickLocationPage()),
                                  );
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
                                title: const Text('Gunakan Lokasi Saat Ini', style: TextStyle(fontSize: 18)),
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
                errorText: _coordinatesError,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedTujuan != null ? _tujuanOptions[_selectedTujuan] : null,
                items: _tujuanOptions.values.toList(),
                labelText: 'Tujuan Penjadwalan',
                onChanged: (value) {
                  setState(() {
                    _selectedTujuan = _tujuanOptions.entries
                        .firstWhere((entry) => entry.value == value, orElse: () => const MapEntry(1, ''))
                        .key;
                  });
                },
                errorText: _tujuanError,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedPrioritas != null ? _prioritasOptions[_selectedPrioritas] : null,
                items: _prioritasOptions.values.toList(),
                labelText: 'Prioritas',
                onChanged: (value) {
                  setState(() {
                    _selectedPrioritas = _prioritasOptions.entries
                        .firstWhere((entry) => entry.value == value, orElse: () => const MapEntry(1, ''))
                        .key;
                  });
                },
                errorText: _prioritasError,
              ),
              const SizedBox(height: 20),
              _buildField(
                'Catatan',
                _noteController,
                validator: (value) => null,
                errorText: _catatanError,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_validateAllFields()) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    final DateFormat formatter = DateFormat('d-M-y');
                                    final DateTime parsedDate = formatter.parse(_dateController.text);
                                    final DateTime scheduleDate = DateTime(
                                      parsedDate.year,
                                      parsedDate.month,
                                      parsedDate.day,
                                    );

                                    final double initialHeight = double.parse(_initialHeightController.text);

                                    final prefs = await SharedPreferences.getInstance();
                                    final creatorId = prefs.getString('session_id') ?? '';

                                    double selectedGrowth = 0;
                                    final provider = context.read<TreeGrowthProvider>();
                                    final trees = await provider.watchAll().first;
                                    if (trees.isNotEmpty && _selectedNamaPohon != null) {
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
                                      zonaProteksi: _zonaProteksiController.text,
                                      section: _sectionController.text,
                                      kmsAset: _kmsAsetController.text,
                                      vendor: _vendorController.text,
                                      asetJtmId: int.tryParse(_kmsAsetController.text) ?? 0,
                                      scheduleDate: scheduleDate,
                                      prioritas: _selectedPrioritas ?? 1,
                                      namaPohon: _selectedNamaPohon ?? '',
                                      fotoPohon: '',
                                      koordinat: _coordinatesController.text,
                                      tujuanPenjadwalan: _selectedTujuan ?? 1,
                                      catatan: _noteController.text,
                                      createdBy: creatorId,
                                      createdDate: DateTime.now(),
                                      growthRate: selectedGrowth,
                                      initialHeight: initialHeight,
                                      notificationDate: scheduleDate.subtract(const Duration(days: 3)),
                                    );

                                    final documentId = await Provider.of<DataPohonProvider>(context, listen: false)
                                        .addPohon(pohon, _fotoPohon);

                  final ulpText = (_ulpController.text.trim().isNotEmpty)
                    ? ' oleh ULP ${_ulpController.text.trim()}'
                    : '';
                  final notifMsg =
                    '${_selectedNamaPohon ?? ''} dengan ID ${_idController.text} baru ditambahkan$ulpText dengan tanggal penjadwalan ${_dateController.text}.';
                                    final notification = AppNotification(
                                      title: 'Pohon Baru Ditambahkan',
                                      message: notifMsg,
                                      date: DateTime.now(),
                                      idPohon: _idController.text,
                                    );

                                    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

                                    await notifProvider.addNotification(
                                      notification,
                                      scheduleDate: null,
                                      documentIdPohon: documentId,
                                    );

                                    await notifProvider.addNotification(
                                      notification,
                                      scheduleDate: scheduleDate,
                                      pohonId: _idController.text,
                                      namaPohon: _selectedNamaPohon ?? '',
                                      documentIdPohon: documentId,
                                    );

                                    if (!mounted) return;
                                    await _requestNotificationPermission();
                                    await _showSuccessAlert();
                                  } catch (e) {
                                    if (!mounted) return;
                                    await _showErrorAlert(e.toString());
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
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