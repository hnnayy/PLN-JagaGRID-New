import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../notification/notification_page.dart';
import '../../providers/notification_provider.dart';
import '../../providers/data_pohon_provider.dart';
import '../../models/data_pohon.dart';
import '../../models/asset_model.dart';
import '../../services/asset_service.dart';
import 'pick_location_page.dart';

// CustomDropdown Widget
class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
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
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () {
                        widget.onChanged(widget.items[index]);
                        _closeDropdown();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.value == widget.items[index] ? const Color(0xFFF0F9FF) : null,
                        ),
                        child: Text(
                          widget.items[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.value == widget.items[index]
                                ? const Color(0xFF2E5D6F)
                                : Colors.black87,
                            fontWeight: widget.value == widget.items[index]
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
                      widget.value ?? 'Pilih ${widget.labelText.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
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
  String? _selectedUlp;

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

  final List<String> _ulpOptions = [
    "UNIT INDUK UP3 PAREPARE",
    "ULP MATTIROTASI",
    "ULP BARRU",
    "ULP RAPPANG",
    "ULP PANGSID",
    "ULP TANRUTEDONG",
    "ULP SOPPENG",
    "ULP PAJALESANG",
    "ULP MAKASSAR",
    "ULP BONE",
  ];

  List<String> _penyulangOptions = [];
  List<String> _zonaProteksiOptions = [];
  List<String> _sectionOptions = [];
  List<String> _vendorOptions = [];
  bool _dropdownDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _generateRandomIdPohon();
    _loadSessionUnit();
    _loadDropdownData();
    _initLocalNotification();
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
      _selectedUlp = _ulpOptions.contains(unit) ? unit : null;
      _ulpController.text = unit;
    });
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool readOnly = false, Icon? suffixIcon, void Function()? onTap, String? Function(String?)? validator, TextInputType? keyboardType}) {
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
              ),
              const SizedBox(height: 20),
              _buildField(
                'UP3',
                _up3Controller,
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'UP3 wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedUlp,
                items: _ulpOptions,
                labelText: 'ULP',
                onChanged: (value) {
                  setState(() {
                    _selectedUlp = value;
                    _ulpController.text = value ?? '';
                  });
                },
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
                    ),
              const SizedBox(height: 20),
              _buildField(
                'Kms Aset',
                _kmsAsetController,
                validator: (value) => value!.isEmpty ? 'Kms Aset wajib diisi' : null,
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
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedNamaPohon,
                items: DataPohon.growthRates.keys.toList(),
                labelText: 'Nama Pohon',
                onChanged: (value) {
                  setState(() {
                    _selectedNamaPohon = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Tinggi Awal (meter)',
                _initialHeightController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Tinggi awal wajib diisi';
                  final height = double.tryParse(value);
                  if (height == null || height < 0) return 'Tinggi awal harus angka valid';
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
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
              ),
              const SizedBox(height: 20),
              _buildField(
                'Catatan',
                _noteController,
                validator: (value) => null, // Optional field
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
                                if (_formKey.currentState!.validate() &&
                                    _selectedPenyulang != null &&
                                    _selectedZonaProteksi != null &&
                                    _selectedSection != null &&
                                    _selectedVendor != null &&
                                    _selectedNamaPohon != null &&
                                    _selectedTujuan != null &&
                                    _selectedPrioritas != null &&
                                    _selectedUlp != null) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    // Parse tanggal dari d-M-y ke DateTime dalam WITA
                                    final DateFormat formatter = DateFormat('d-M-y');
                                    final DateTime parsedDate = formatter.parse(_dateController.text);
                                    final DateTime scheduleDate = DateTime(
                                      parsedDate.year,
                                      parsedDate.month,
                                      parsedDate.day,
                                    );

                                    final double initialHeight = double.parse(_initialHeightController.text);

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
                                      scheduleDate: scheduleDate,
                                      prioritas: _selectedPrioritas ?? 1,
                                      namaPohon: _selectedNamaPohon ?? '',
                                      fotoPohon: '',
                                      koordinat: _coordinatesController.text,
                                      tujuanPenjadwalan: _selectedTujuan ?? 1,
                                      catatan: _noteController.text,
                                      createdBy: 1,
                                      createdDate: DateTime.now(),
                                      growthRate: DataPohon.growthRates[_selectedNamaPohon!] ?? 0,
                                      initialHeight: initialHeight,
                                      notificationDate: scheduleDate.subtract(const Duration(days: 3)),
                                    );

                                    // Simpan data pohon ke database
                                    await Provider.of<DataPohonProvider>(context, listen: false)
                                        .addPohon(pohon, _fotoPohon);

                                    final notifMsg =
                                        '${_selectedNamaPohon ?? ''} dengan ID ${_idController.text} baru ditambahkan dengan tanggal penjadwalan ${_dateController.text}.';
                                    final notification = AppNotification(
                                      title: 'Pohon Baru Ditambahkan',
                                      message: notifMsg,
                                      date: DateTime.now(),
                                    );

                                    // Tambah notifikasi (termasuk scheduling)
                                    await Provider.of<NotificationProvider>(context, listen: false)
                                        .addNotification(
                                      notification,
                                      scheduleDate: scheduleDate,
                                      pohonId: _idController.text,
                                      namaPohon: _selectedNamaPohon ?? '',
                                    );

                                    if (!mounted) return;
                                    await _requestNotificationPermission();
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
                                                  color: const Color(0xFF2E5D6F),
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
                                              ElevatedButton(
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
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
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
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 55,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                "Gagal!",
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E5D6F),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Terjadi kesalahan saat menyimpan data:\n${e.toString()}",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey.shade600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2E5D6F),
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
                                            ],
                                          ),
                                        ),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Harap lengkapi semua field wajib'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
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