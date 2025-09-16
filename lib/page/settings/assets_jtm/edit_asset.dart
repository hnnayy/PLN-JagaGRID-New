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

// Custom Success Dialog Widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOkPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF2E5D6F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5D6F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // OK Button
            SizedBox(
              width: 120,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5D6F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onOkPressed != null) {
                    onOkPressed!();
                  }
                },
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
    );
  }
}

class EditAssetPage extends StatefulWidget {
  final AssetModel asset;
  
  const EditAssetPage({super.key, required this.asset});

  @override
  State<EditAssetPage> createState() => _EditAssetPageState();
}

class _EditAssetPageState extends State<EditAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _assetService = AssetService();
  
  // Controllers for form fields
  late TextEditingController _wilayahController;
  late TextEditingController _subWilayahController;
  late TextEditingController _sectionController;
  late TextEditingController _up3Controller;
  late TextEditingController _ulpController;
  late TextEditingController _penyulangController;
  late TextEditingController _zonaProteksiController;
  late TextEditingController _panjangKmsController;
  late TextEditingController _roleController;
  late TextEditingController _vendorVbController;
  
  String? _selectedStatus;
  final List<String> _statusOptions = ['Sempurna', 'Sehat', 'Sakit'];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current asset data
    _wilayahController = TextEditingController(text: widget.asset.wilayah);
    _subWilayahController = TextEditingController(text: widget.asset.subWilayah);
    _sectionController = TextEditingController(text: widget.asset.section);
    _up3Controller = TextEditingController(text: widget.asset.up3);
    _ulpController = TextEditingController(text: widget.asset.ulp);
    _penyulangController = TextEditingController(text: widget.asset.penyulang);
    _zonaProteksiController = TextEditingController(text: widget.asset.zonaProteksi);
    _panjangKmsController = TextEditingController(text: widget.asset.panjangKms.toString());
    _roleController = TextEditingController(text: widget.asset.role);
    _vendorVbController = TextEditingController(text: widget.asset.vendorVb);
    
    // Validasi dan set selectedStatus
    final validStatuses = ['Sempurna', 'Sehat', 'Sakit'];
    if (validStatuses.contains(widget.asset.status)) {
      _selectedStatus = widget.asset.status;
    } else {
      _selectedStatus = null; // Set null jika status tidak valid
      print('Warning: Invalid status "${widget.asset.status}" found, resetting to null');
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: "Berhasil!",
          message: "Asset berhasil diperbarui ke sistem",
          onOkPressed: () {
            // Navigate back to previous screen with success result
            Navigator.pop(context, true);
          },
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Error",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAsset() async {
    if (_selectedStatus == null) {
      _showErrorDialog("Pilih status terlebih dahulu");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated asset model
      AssetModel updatedAsset = widget.asset.copyWith(
        wilayah: _wilayahController.text.trim(),
        subWilayah: _subWilayahController.text.trim(),
        section: _sectionController.text.trim(),
        up3: _up3Controller.text.trim(),
        ulp: _ulpController.text.trim(),
        penyulang: _penyulangController.text.trim(),
        zonaProteksi: _zonaProteksiController.text.trim(),
        panjangKms: double.tryParse(_panjangKmsController.text) ?? 0.0,
        role: _roleController.text.trim(),
        status: _selectedStatus!,
        vendorVb: _vendorVbController.text.trim(),
      );

      // Update asset in Firestore
      await _assetService.updateAsset(updatedAsset);

      if (mounted) {
        // Show success dialog instead of snackbar
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        // Show error dialog instead of snackbar
        _showErrorDialog('Gagal memperbarui asset: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator
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
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFF0F9FF),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
          validator: validator,
        ),
      ],
    );
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
          "Edit Asset JTM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
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
                "Wilayah",
                _wilayahController,
                validator: (value) => value?.isEmpty ?? true ? "Wilayah tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Sub Wilayah",
                _subWilayahController,
                validator: (value) => value?.isEmpty ?? true ? "Sub wilayah tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Section",
                _sectionController,
                validator: (value) => value?.isEmpty ?? true ? "Section tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "UP3",
                _up3Controller,
                validator: (value) => value?.isEmpty ?? true ? "UP3 tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "ULP",
                _ulpController,
                validator: (value) => value?.isEmpty ?? true ? "ULP tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Penyulang",
                _penyulangController,
                validator: (value) => value?.isEmpty ?? true ? "Penyulang tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Zona Proteksi",
                _zonaProteksiController,
                validator: (value) => value?.isEmpty ?? true ? "Zona proteksi tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),
              
              _buildField(
                "Panjang (KMS)",
                _panjangKmsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Panjang tidak boleh kosong';
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
                validator: (value) => value?.isEmpty ?? true ? "Role tidak boleh kosong" : null,
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
                validator: (value) => value?.isEmpty ?? true ? "Vendor VB tidak boleh kosong" : null,
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
                  onPressed: _isLoading ? null : _updateAsset,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Simpan Perubahan",
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
}