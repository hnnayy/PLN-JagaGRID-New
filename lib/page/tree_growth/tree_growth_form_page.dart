import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tree_growth.dart';
import '../../providers/tree_growth_provider.dart';

class TreeGrowthFormPage extends StatefulWidget {
  final TreeGrowth? item;
  const TreeGrowthFormPage({super.key, this.item});

  @override
  State<TreeGrowthFormPage> createState() => _TreeGrowthFormPageState();
}

class _TreeGrowthFormPageState extends State<TreeGrowthFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _rateController.text = widget.item!.growthRate.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // Alert Dialog untuk Berhasil
  Future<void> _showSuccessDialog({bool isEdit = false}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
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
                // Icon Success (circular check)
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFF256D78),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEdit 
                    ? 'Data pertumbuhan pohon berhasil diperbarui'
                    : 'Data pertumbuhan pohon berhasil ditambahkan',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF256D78),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Alert Dialog untuk Gagal
  void _showFailureDialog() {
    final isEdit = widget.item != null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
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
                // Icon Error
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Gagal!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'Gagal menyimpan, perbaiki kesalahan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close alert only
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method untuk detail row
  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isError ? Colors.grey.shade600 : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isError ? Colors.grey.shade800 : const Color(0xFF2E5D6F),
            ),
          ),
        ),
      ],
    );
  }

  // Validasi dan pembersihan input data
  String _cleanString(String input) {
    return input
        .replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/]'), '')
        .trim();
  }

  // Validasi data sebelum disimpan
  bool _validateData() {
    final cleanName = _cleanString(_nameController.text);
    final rateText = _rateController.text.trim();
    
    if (cleanName.isEmpty || cleanName.length < 2) {
      return false;
    }
    
    final rate = double.tryParse(rateText);
    if (rate == null || rate <= 0 || rate > 1000) {
      return false;
    }
    
    _nameController.text = cleanName;
    return true;
  }

  // Format tanggal
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} WITA';
  }

  // Reset form
  void _resetForm() {
    _nameController.clear();
    _rateController.clear();
    setState(() {});
  }

  // Save data to database
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      // Form validation akan menampilkan pesan error di field
      // Tidak perlu alert "Gagal!" tambahan
      return;
    }
    
    if (!_validateData()) {
      // Custom validation juga tidak perlu alert "Gagal!"
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<TreeGrowthProvider>();
      final name = _nameController.text.trim();
      final rate = double.parse(_rateController.text.trim());
      
      if (widget.item != null) {
        // Update existing item
        final updatedItem = TreeGrowth(
          id: widget.item!.id,
          name: name,
          growthRate: rate,
          createdAt: widget.item!.createdAt,
          status: widget.item!.status,
          deletedAt: widget.item!.deletedAt,
        );
        
        final success = await provider.update(updatedItem);
        if (success && mounted) {
          // Show success dialog, then return updated item
          await _showSuccessDialog(isEdit: true);
          if (mounted) {
            Navigator.of(context).pop(updatedItem);
          }
          return;
        }
      } else {
        // Create new item
        final success = await provider.add(name, rate);
        if (success && mounted) {
          // Show success dialog first
          await _showSuccessDialog(isEdit: false);
          if (mounted) {
            // Get the newly created item from provider
            final newItem = TreeGrowth(
              id: '', // Will be set by service
              name: name,
              growthRate: rate,
              createdAt: DateTime.now(),
              status: 1,
            );
            Navigator.of(context).pop(newItem);
          }
          return;
        }
      }
      
      // If we get here, something went wrong
      if (mounted) {
        _showFailureDialog();
      }
    } catch (e) {
      if (mounted) {
        _showFailureDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
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
          isEdit ? 'Edit Pertumbuhan Pohon' : 'Tambah Pertumbuhan Pohon',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
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
                label: 'Nama Pohon',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                  if (v.trim().length < 2) return 'Nama minimal 2 karakter';
                  if (RegExp(r'[^\w\s\-\.\,\(\)\/]').hasMatch(v)) {
                    return 'Nama tidak boleh mengandung karakter khusus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildField(
                label: 'Pertumbuhan pohon (cm/tahun)',
                controller: _rateController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Pertumbuhan pohon wajib diisi';
                  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(v)) {
                    return 'Hanya angka yang diizinkan';
                  }
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Masukkan nilai > 0';
                  if (d > 1000) return 'Maksimal 1000 cm/tahun';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Buttons
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
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                        onPressed: _isLoading ? null : _saveData,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isEdit ? 'Perbarui' : 'Simpan',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFF0F9FF),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.all(16),
            ),
        ),
      ],
    );
  }
}