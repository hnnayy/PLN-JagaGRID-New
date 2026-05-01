import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/unit.dart';
import '../../../services/unit_service.dart';

class FormAddUnitPage extends StatefulWidget {
  /// Jika [docId] diisi → mode Edit, sebaliknya → mode Tambah
  final String? docId;
  final String? namaUnit;
  final String? kodeUnit;

  const FormAddUnitPage({
    super.key,
    this.docId,
    this.namaUnit,
    this.kodeUnit,
  });

  @override
  State<FormAddUnitPage> createState() => _FormAddUnitPageState();
}

class _FormAddUnitPageState extends State<FormAddUnitPage> {
  final _formKey = GlobalKey<FormState>();
  final namaUnitController = TextEditingController();
  final kodeUnitController = TextEditingController();
  final UnitService _unitService = UnitService();

  bool _isLoading = false;
  bool _kodeEdited = false;
  String? _namaUnitError;
  String? _kodeUnitError;

  bool get _isEditMode => widget.docId != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form jika mode edit
    if (_isEditMode) {
      namaUnitController.text = widget.namaUnit ?? '';
      kodeUnitController.text = widget.kodeUnit ?? '';
      _kodeEdited = true; // anggap sudah manual karena dari data existing
    }
  }

  String _generateKodeUnit(String namaUnit) {
    String cleaned = namaUnit
        .toUpperCase()
        .replaceAll("UNIT INDUK UP3 ", "")
        .replaceAll("UNIT INDUK ", "")
        .replaceAll("UP3 ", "")
        .replaceAll("ULP ", "")
        .trim();

    if (cleaned.isEmpty) return '';

    String firstWord = cleaned.split(' ').first;
    return firstWord.length >= 3 ? firstWord.substring(0, 3) : firstWord;
  }

  void _clearAllErrors() {
    setState(() {
      _namaUnitError = null;
      _kodeUnitError = null;
    });
  }

  bool _validateAllFields() {
    _clearAllErrors();
    bool isValid = true;

    if (namaUnitController.text.trim().isEmpty) {
      setState(() => _namaUnitError = 'Nama unit tidak boleh kosong');
      isValid = false;
    } else if (namaUnitController.text.trim().length < 3) {
      setState(() => _namaUnitError = 'Nama unit minimal 3 karakter');
      isValid = false;
    }

    if (kodeUnitController.text.trim().isEmpty) {
      setState(() => _kodeUnitError = 'Kode unit tidak boleh kosong');
      isValid = false;
    } else if (kodeUnitController.text.trim().length < 2) {
      setState(() => _kodeUnitError = 'Kode unit minimal 2 karakter');
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9]+$')
        .hasMatch(kodeUnitController.text.trim())) {
      setState(() => _kodeUnitError = 'Kode unit hanya boleh huruf dan angka');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _saveUnit() async {
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final kode = kodeUnitController.text.trim().toUpperCase();
      final namaUnit = namaUnitController.text.trim().toUpperCase();

      if (_isEditMode) {
        // ── MODE EDIT ──────────────────────────────────────────
        // Cek kode unit sudah ada, kecuali milik dirinya sendiri
        final kodeExist = await _unitService.isKodeUnitExistExclude(
            kode, widget.docId!);
        if (kodeExist) {
          setState(() {
            _isLoading = false;
            _kodeUnitError = 'Kode unit sudah terdaftar, gunakan kode lain';
          });
          return;
        }

        // Cek nama unit sudah ada, kecuali milik dirinya sendiri
        final namaExist = await _unitService.isNamaUnitExistExclude(
            namaUnit, widget.docId!);
        if (namaExist) {
          setState(() {
            _isLoading = false;
            _namaUnitError = 'Nama unit sudah terdaftar dalam sistem';
          });
          return;
        }

        await _unitService.updateUnit(
          UnitModel(
            id: widget.docId,
            namaUnit: namaUnit,
            kodeUnit: kode,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } else {
        // ── MODE TAMBAH ────────────────────────────────────────
        final kodeExist = await _unitService.isKodeUnitExist(kode);
        if (kodeExist) {
          setState(() {
            _isLoading = false;
            _kodeUnitError = 'Kode unit sudah terdaftar, gunakan kode lain';
          });
          return;
        }

        final namaExist = await _unitService.isNamaUnitExist(namaUnit);
        if (namaExist) {
          setState(() {
            _isLoading = false;
            _namaUnitError = 'Nama unit sudah terdaftar dalam sistem';
          });
          return;
        }

        await _unitService.addUnit(
          UnitModel(
            namaUnit: namaUnit,
            kodeUnit: kode,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessAlert();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5D6F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5D6F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isEditMode
                    ? 'Unit berhasil diperbarui'
                    : 'Unit berhasil ditambahkan ke sistem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tag,
                        color: Color(0xFF2E5D6F), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Kode: ${kodeUnitController.text.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5D6F),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contoh ID Pohon: ${kodeUnitController.text.toUpperCase()}-XXXXXXXX',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // tutup dialog
                    if (_isEditMode) {
                      Navigator.of(context).pop(); // kembali ke list
                    } else {
                      _resetForm();
                    }
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      namaUnitController.clear();
      kodeUnitController.clear();
      _kodeEdited = false;
    });
    _clearAllErrors();
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
        title: Text(
          _isEditMode ? "Edit Unit" : "Tambah Unit Baru",
          style: const TextStyle(
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
              const SizedBox(height: 8),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E5D6F).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF2E5D6F), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kode unit otomatis ter-generate dari nama unit dan bisa diedit manual. Kode ini akan menjadi prefix ID Pohon.\nContoh: ULP BARRU → BRR → BRR-012910029923',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Nama Unit ──
              _buildLabel("Nama Unit"),
              const SizedBox(height: 8),
              TextFormField(
                controller: namaUnitController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration("Contoh: ULP BARRU"),
                onChanged: (value) {
                  if (!_kodeEdited) {
                    setState(() {
                      kodeUnitController.text = _generateKodeUnit(value);
                    });
                  }
                  if (_namaUnitError != null) {
                    setState(() => _namaUnitError = null);
                  }
                },
              ),
              if (_namaUnitError != null) _buildError(_namaUnitError!),

              const SizedBox(height: 24),

              // ── Kode Unit ──
              Row(
                children: [
                  _buildLabel("Kode Unit"),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kodeEdited
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _kodeEdited ? '✏️ Manual' : '⚡ Auto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kodeEdited
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: kodeUnitController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                decoration: _inputDecoration("Contoh: BRR"),
                onChanged: (value) {
                  setState(() => _kodeEdited = value.isNotEmpty);
                  if (_kodeUnitError != null) {
                    setState(() => _kodeUnitError = null);
                  }
                },
              ),
              if (_kodeUnitError != null) _buildError(_kodeUnitError!),

              if (_kodeEdited && !_isEditMode) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _kodeEdited = false;
                      kodeUnitController.text =
                          _generateKodeUnit(namaUnitController.text);
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Reset ke auto-generate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              
              const SizedBox(height: 32),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveUnit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditMode ? "Simpan Perubahan" : "Simpan Unit",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildError(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F9FF),
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  @override
  void dispose() {
    namaUnitController.dispose();
    kodeUnitController.dispose();
    super.dispose();
  }
}