import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/asset_model.dart';
import 'package:flutter_application_2/services/asset_service.dart';

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key, 
    required this.value, 
    required this.items, 
    required this.labelText, 
    required this.onChanged,
    this.validator,
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
                    border: Border.all(color: Colors.grey.shade300)
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
                          color: widget.value == widget.items[index] ? const Color(0xFFF0F9FF) : null
                        ),
                        child: Text(
                          widget.items[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.value == widget.items[index] ? const Color(0xFF2E5D6F) : Colors.black87,
                            fontWeight: widget.value == widget.items[index] ? FontWeight.w500 : FontWeight.normal,
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
            fontWeight: FontWeight.w500
          )
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
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? 'Pilih status', 
                      style: TextStyle(
                        fontSize: 16, 
                        color: widget.value != null ? Colors.black87 : Colors.grey.shade500
                      )
                    )
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0, 
                    duration: const Duration(milliseconds: 200), 
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600)
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

  String? _selectedStatus;
  final List<String> _statusOptions = ['Sempurna', 'Sehat', 'Sakit'];

  bool _isLoading = false;

  String getCurrentDate() {
    final now = DateTime.now();
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showValidationAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Gagal!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Data yang dimasukkan tidak valid.\nSilakan periksa kembali form.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _showSimpleValidationAlert(List<String> errors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Gagal!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Mohon isi data dengan benar dan lengkap",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  List<String> _getValidationErrors() {
    List<String> errors = [];
    
    if (_wilayahController.text.trim().isEmpty || _wilayahController.text.trim() == '1') {
      errors.add('Wilayah harus diisi dengan nama yang valid');
    }
    if (_subWilayahController.text.trim().isEmpty || _subWilayahController.text.trim() == '1') {
      errors.add('Sub Wilayah harus diisi dengan nama yang valid');
    }
    if (_sectionController.text.trim().isEmpty || _sectionController.text.trim() == '1') {
      errors.add('Section harus diisi dengan nama yang valid');
    }
    if (_up3Controller.text.trim().isEmpty || _up3Controller.text.trim() == '1') {
      errors.add('UP3 harus diisi dengan nama yang valid');
    }
    if (_ulpController.text.trim().isEmpty || _ulpController.text.trim() == '1') {
      errors.add('ULP harus diisi dengan nama yang valid');
    }
    if (_penyulangController.text.trim().isEmpty || _penyulangController.text.trim() == '1') {
      errors.add('Penyulang harus diisi dengan nama yang valid');
    }
    if (_zonaProteksiController.text.trim().isEmpty || _zonaProteksiController.text.trim() == '1') {
      errors.add('Zona Proteksi harus diisi dengan nama yang valid');
    }
    if (_roleController.text.trim().isEmpty || _roleController.text.trim() == '1') {
      errors.add('Role harus diisi dengan nama yang valid');
    }
    if (_vendorVbController.text.trim().isEmpty || _vendorVbController.text.trim() == '1') {
      errors.add('Vendor VB harus diisi dengan nama yang valid');
    }
    if (_selectedStatus == null) {
      errors.add('Status harus dipilih');
    }
    
    // Validasi panjang KMS
    String panjangText = _panjangKmsController.text.trim();
    if (panjangText.isEmpty || panjangText == '1') {
      errors.add('Panjang KMS harus diisi dengan angka yang valid');
    } else {
      double? panjang = double.tryParse(panjangText.replaceAll(',', '.'));
      if (panjang == null) {
        errors.add('Panjang KMS harus berupa angka (contoh: 12.5)');
      } else if (panjang <= 0) {
        errors.add('Panjang KMS harus lebih dari 0');
      }
    }
    
    return errors;
  }

  void _showDetailedValidationAlert(List<String> errors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Data Belum Lengkap",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mohon perbaiki data berikut:",
                style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Jangan hanya memasukkan angka '1'. Isi dengan data yang sebenarnya.",
                        style: TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK, Perbaiki Data",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tambahAsset() async {
    // Cek validasi custom terlebih dahulu
    List<String> validationErrors = _getValidationErrors();
    if (validationErrors.isNotEmpty) {
      _showSimpleValidationAlert(validationErrors);
      return;
    }

    // Validasi form standar
    if (!_formKey.currentState!.validate()) {
      _showValidationAlert();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
        status: _selectedStatus!,
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
              const Text("Berhasil!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E5D6F))),
              const SizedBox(height: 10),
              Text("Asset ${newAsset.wilayah} - ${newAsset.section} berhasil ditambahkan", style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ("Wilayah", newAsset.wilayah),
                    ("Sub Wilayah", newAsset.subWilayah),
                    ("Section", newAsset.section),
                    ("Status", newAsset.status),
                    ("Ditambahkan", getCurrentDate()),
                  ].map((detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 90, child: Text("${detail.$1}:", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14))),
                        Expanded(child: Text(detail.$2, style: const TextStyle(color: Color(0xFF2E5D6F), fontSize: 14, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade400, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearForm();
                      },
                      icon: Icon(Icons.add_circle_outline_rounded, color: Colors.grey.shade700, size: 20),
                      label: Text("Tambah Lagi", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5D6F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(context, newAsset);
                      },
                      icon: const Icon(Icons.list_rounded, size: 20),
                      label: const Text("Lihat List", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedStatus = null;
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
  }

  Widget _buildField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? suffixText,
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
            fillColor: const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixText: suffixText,
            hintText: label == 'Panjang (KMS)' ? 'Contoh: 12.5' : 'Masukkan $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          validator: validator,
        ),
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
              _buildField(
                "Wilayah",
                _wilayahController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Wilayah tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama wilayah yang valid";
                  if (value.trim().length < 2) return "Nama wilayah terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Sub Wilayah",
                _subWilayahController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Sub wilayah tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama sub wilayah yang valid";
                  if (value.trim().length < 2) return "Nama sub wilayah terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Section",
                _sectionController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Section tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama section yang valid";
                  if (value.trim().length < 2) return "Nama section terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "UP3",
                _up3Controller,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "UP3 tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama UP3 yang valid";
                  if (value.trim().length < 2) return "Nama UP3 terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "ULP",
                _ulpController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "ULP tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama ULP yang valid";
                  if (value.trim().length < 2) return "Nama ULP terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Penyulang",
                _penyulangController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Penyulang tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama penyulang yang valid";
                  if (value.trim().length < 2) return "Nama penyulang terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Zona Proteksi",
                _zonaProteksiController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Zona proteksi tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama zona proteksi yang valid";
                  if (value.trim().length < 2) return "Nama zona proteksi terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Panjang (KMS)",
                _panjangKmsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffixText: "km",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Panjang tidak boleh kosong';
                  }
                  if (value.trim() == '1') {
                    return 'Masukkan panjang yang sebenarnya (contoh: 12.5)';
                  }
                  
                  String cleanValue = value.trim().replaceAll(',', '.');
                  double? panjang = double.tryParse(cleanValue);
                  
                  if (panjang == null) {
                    return 'Masukkan angka yang valid (contoh: 12.5)';
                  }
                  if (panjang <= 0) {
                    return 'Panjang harus lebih dari 0';
                  }
                  if (panjang > 999999) {
                    return 'Panjang terlalu besar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Role",
                _roleController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Role tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama role yang valid";
                  if (value.trim().length < 2) return "Nama role terlalu pendek";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomDropdown(
                value: _selectedStatus,
                items: _statusOptions,
                labelText: "Status",
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Vendor VB",
                _vendorVbController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Vendor VB tidak boleh kosong";
                  if (value!.trim() == '1') return "Masukkan nama vendor VB yang valid";
                  if (value.trim().length < 2) return "Nama vendor VB terlalu pendek";
                  return null;
                },
              ),
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
              
              // Info box
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