import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final String? errorText;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.validator,
    this.errorText,
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
                color: widget.errorText != null ? Colors.red.shade50 : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: widget.errorText != null ? Border.all(color: Colors.red.shade300) : null,
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
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _vendorVbController = TextEditingController();

  String? _selectedHealthIndex;
  final List<String> _healthIndexOptions = ['SEMPURNA', 'SEHAT', 'SAKIT'];

  bool _isLoading = false;

  // Error messages for inline validation
  String? _wilayahError;
  String? _subWilayahError;
  String? _sectionError;
  String? _up3Error;
  String? _ulpError;
  String? _penyulangError;
  String? _zonaProteksiError;
  String? _panjangKmsError;
  String? _roleError;
  String? _vendorVbError;
  String? _healthIndexError;

  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _clearAllErrors() {
    setState(() {
      _wilayahError = null;
      _subWilayahError = null;
      _sectionError = null;
      _up3Error = null;
      _ulpError = null;
      _penyulangError = null;
      _zonaProteksiError = null;
      _panjangKmsError = null;
      _roleError = null;
      _vendorVbError = null;
      _healthIndexError = null;
    });
  }

  bool _validateAllFields() {
    _clearAllErrors();
    bool isValid = true;

    // Validate Wilayah
    if (_wilayahController.text.trim().isEmpty || _wilayahController.text.trim() == '1') {
      setState(() => _wilayahError = _wilayahController.text.trim().isEmpty
          ? 'Wilayah tidak boleh kosong'
          : 'Masukkan nama wilayah yang valid');
      isValid = false;
    } else if (_wilayahController.text.trim().length < 2) {
      setState(() => _wilayahError = 'Nama wilayah terlalu pendek');
      isValid = false;
    }

    // Validate Sub Wilayah
    if (_subWilayahController.text.trim().isEmpty || _subWilayahController.text.trim() == '1') {
      setState(() => _subWilayahError = _subWilayahController.text.trim().isEmpty
          ? 'Sub wilayah tidak boleh kosong'
          : 'Masukkan nama sub wilayah yang valid');
      isValid = false;
    } else if (_subWilayahController.text.trim().length < 2) {
      setState(() => _subWilayahError = 'Nama sub wilayah terlalu pendek');
      isValid = false;
    }

    // Validate Section
    if (_sectionController.text.trim().isEmpty || _sectionController.text.trim() == '1') {
      setState(() => _sectionError = _sectionController.text.trim().isEmpty
          ? 'Section tidak boleh kosong'
          : 'Masukkan nama section yang valid');
      isValid = false;
    } else if (_sectionController.text.trim().length < 2) {
      setState(() => _sectionError = 'Nama section terlalu pendek');
      isValid = false;
    }

    // Validate UP3
    if (_up3Controller.text.trim().isEmpty || _up3Controller.text.trim() == '1') {
      setState(() => _up3Error = _up3Controller.text.trim().isEmpty
          ? 'UP3 tidak boleh kosong'
          : 'Masukkan nama UP3 yang valid');
      isValid = false;
    } else if (_up3Controller.text.trim().length < 2) {
      setState(() => _up3Error = 'Nama UP3 terlalu pendek');
      isValid = false;
    }

    // Validate ULP
    if (_ulpController.text.trim().isEmpty || _ulpController.text.trim() == '1') {
      setState(() => _ulpError = _ulpController.text.trim().isEmpty
          ? 'ULP tidak boleh kosong'
          : 'Masukkan nama ULP yang valid');
      isValid = false;
    } else if (_ulpController.text.trim().length < 2) {
      setState(() => _ulpError = 'Nama ULP terlalu pendek');
      isValid = false;
    }

    // Validate Penyulang
    if (_penyulangController.text.trim().isEmpty || _penyulangController.text.trim() == '1') {
      setState(() => _penyulangError = _penyulangController.text.trim().isEmpty
          ? 'Penyulang tidak boleh kosong'
          : 'Masukkan nama penyulang yang valid');
      isValid = false;
    } else if (_penyulangController.text.trim().length < 2) {
      setState(() => _penyulangError = 'Nama penyulang terlalu pendek');
      isValid = false;
    }

    // Validate Zona Proteksi
    if (_zonaProteksiController.text.trim().isEmpty || _zonaProteksiController.text.trim() == '1') {
      setState(() => _zonaProteksiError = _zonaProteksiController.text.trim().isEmpty
          ? 'Zona proteksi tidak boleh kosong'
          : 'Masukkan nama zona proteksi yang valid');
      isValid = false;
    } else if (_zonaProteksiController.text.trim().length < 2) {
      setState(() => _zonaProteksiError = 'Nama zona proteksi terlalu pendek');
      isValid = false;
    }

    // Validate Panjang KMS
    String panjangText = _panjangKmsController.text.trim();
    if (panjangText.isEmpty || panjangText == '1') {
      setState(() => _panjangKmsError = panjangText.isEmpty
          ? 'Panjang tidak boleh kosong'
          : 'Masukkan panjang yang sebenarnya (contoh: 12.5)');
      isValid = false;
    } else {
      String cleanValue = panjangText.replaceAll(',', '.');
      double? panjang = double.tryParse(cleanValue);
      if (panjang == null) {
        setState(() => _panjangKmsError = 'Masukkan angka yang valid (contoh: 12.5)');
        isValid = false;
      } else if (panjang <= 0) {
        setState(() => _panjangKmsError = 'Panjang harus lebih dari 0');
        isValid = false;
      } else if (panjang > 999999) {
        setState(() => _panjangKmsError = 'Panjang terlalu besar');
        isValid = false;
      }
    }

    // Validate Role
    if (_roleController.text.trim().isEmpty || _roleController.text.trim() == '1') {
      setState(() => _roleError = _roleController.text.trim().isEmpty
          ? 'Role tidak boleh kosong'
          : 'Masukkan nama role yang valid');
      isValid = false;
    } else if (_roleController.text.trim().length < 2) {
      setState(() => _roleError = 'Nama role terlalu pendek');
      isValid = false;
    }

    // Validate Health Index
    if (_selectedHealthIndex == null) {
      setState(() => _healthIndexError = 'Health index harus dipilih');
      isValid = false;
    }

    // Validate Vendor VB
    if (_vendorVbController.text.trim().isEmpty || _vendorVbController.text.trim() == '1') {
      setState(() => _vendorVbError = _vendorVbController.text.trim().isEmpty
          ? 'Vendor VB tidak boleh kosong'
          : 'Masukkan nama vendor VB yang valid');
      isValid = false;
    } else if (_vendorVbController.text.trim().length < 2) {
      setState(() => _vendorVbError = 'Nama vendor VB terlalu pendek');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _tambahAsset() async {
    if (!_validateAllFields()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Konversi _selectedHealthIndex ke HealthIndex
      HealthIndex healthIndex = HealthIndex.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedHealthIndex,
      );

      final newAsset = AssetModel(
        id: '', // Firestore akan generate otomatis
        wilayah: _wilayahController.text.trim(),
        subWilayah: _subWilayahController.text.trim(),
        section: _sectionController.text.trim(),
        up3: _up3Controller.text.trim(),
        ulp: _ulpController.text.trim(),
        penyulang: _penyulangController.text.trim(),
        zonaProteksi: _zonaProteksiController.text.trim(),
        panjangKms: double.tryParse(_panjangKmsController.text.replaceAll(',', '.')) ?? 0,
        healthIndex: healthIndex,
        status: 1, // Default aktif
        role: _roleController.text.trim(),
        vendorVb: _vendorVbController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _assetService.addAsset(newAsset);

      if (mounted) {
        _showSuccessDialog(newAsset);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showSuccessDialog(AssetModel newAsset) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(color: Color(0xFF2E5D6F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "Berhasil!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E5D6F)),
              ),
              const SizedBox(height: 10),
              Text(
                "Asset ${newAsset.wilayah} - ${newAsset.section} berhasil ditambahkan",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context, newAsset);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedHealthIndex = null;
      _wilayahController.clear();
      _subWilayahController.clear();
      _sectionController.clear();
      _up3Controller.clear();
      _ulpController.clear();
      _penyulangController.clear();
      _zonaProteksiController.clear();
      _panjangKmsController.clear();
      _roleController.clear();
      _vendorVbController.clear();
    });
    _clearAllErrors();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: errorText != null ? Colors.red.shade50 : const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixText: suffixText,
            hintText: label == 'Panjang (KMS)' ? 'Contoh: 12.5' : 'Masukkan $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
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
    _roleController.dispose();
    _vendorVbController.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Tambah Asset JTM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearForm,
            child: const Text(
              "Reset",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
              _buildField("Wilayah", _wilayahController, errorText: _wilayahError),
              const SizedBox(height: 20),
              _buildField("Sub Wilayah", _subWilayahController, errorText: _subWilayahError),
              const SizedBox(height: 20),
              _buildField("Section", _sectionController, errorText: _sectionError),
              const SizedBox(height: 20),
              _buildField("UP3", _up3Controller, errorText: _up3Error),
              const SizedBox(height: 20),
              _buildField("ULP", _ulpController, errorText: _ulpError),
              const SizedBox(height: 20),
              _buildField("Penyulang", _penyulangController, errorText: _penyulangError),
              const SizedBox(height: 20),
              _buildField("Zona Proteksi", _zonaProteksiController, errorText: _zonaProteksiError),
              const SizedBox(height: 20),
              _buildField(
                "Panjang (KMS)",
                _panjangKmsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: "km",
                errorText: _panjangKmsError,
              ),
              const SizedBox(height: 20),
              _buildField("Role", _roleController, errorText: _roleError),
              const SizedBox(height: 20),
              CustomDropdown(
                value: _selectedHealthIndex,
                items: _healthIndexOptions,
                labelText: "Health Index",
                onChanged: (value) {
                  setState(() {
                    _selectedHealthIndex = value;
                    _healthIndexError = null; // Clear error when user selects
                  });
                },
                errorText: _healthIndexError,
                validator: (value) => value == null ? 'Health index harus dipilih' : null,
              ),
              const SizedBox(height: 20),
              _buildField("Vendor VB", _vendorVbController, errorText: _vendorVbError),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isLoading ? null : _tambahAsset,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan Asset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Pastikan semua data diisi dengan benar dan lengkap sebelum menyimpan asset.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}