import 'package:flutter/material.dart';
import '../../models/tree_growth.dart';

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
        title: const Text(
          'Pertumbuhan pohon',
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
                label: 'Nama Pohon',
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Pertumbuhan pohon (cm/tahun)',
                controller: _rateController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Pertumbuhan pohon wajib diisi';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Masukkan nilai > 0';
                  return null;
                },
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
                        onPressed: () => Navigator.of(context).pop(),
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
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          final rate = double.parse(_rateController.text);
                          if (isEdit) {
                            final updated = widget.item!.copyWith(
                              name: _nameController.text.trim(),
                              growthRate: rate,
                            );
                            Navigator.pop(context, updated);
                          } else {
                            final created = TreeGrowth(
                              id: '',
                              name: _nameController.text.trim(),
                              growthRate: rate,
                              createdAt: DateTime.now(),
                            );
                            Navigator.pop(context, created);
                          }
                        },
                        child: const Text('Simpan'),
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
