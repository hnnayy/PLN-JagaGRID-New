import 'package:flutter/material.dart';

// File: lib/page/add_assets.dart
class AddAssetsPage extends StatefulWidget {
  const AddAssetsPage({Key? key}) : super(key: key);

  @override
  State<AddAssetsPage> createState() => _AddAssetsPageState();
}

class _AddAssetsPageState extends State<AddAssetsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers untuk text fields
  final TextEditingController _panjangKmsController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _vendorVbController = TextEditingController();
  
  // Dropdown values
  String? _selectedSection;
  String? _selectedUlp;
  String? _selectedPenyulang;
  String? _selectedZonaProteksi;
  String? _selectedHealthIndex;
  
  // Dropdown options
  final List<String> _sectionOptions = ['LBS', 'FCO'];
  final List<String> _ulpOptions = [
    'ULP BARRU',
    'MATTIROTASI', 
    'PAJALESANG',
    'PANGSID',
    'RAPPANG',
    'SOPPENG',
    'TANRU TEDONG'
  ];
  final List<String> _penyulangOptions = ['LAJOA', 'TAKALALLA'];
  final List<String> _zonaProteksiOptions = ['REC_TEPPOE', 'P_TAKALALLA'];
  final List<String> _healthIndexOptions = ['SEMPURNA', 'SEHAT', 'SAKIT'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF125E72), 
            Color(0xFF14A2B9),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tambah Assets JTM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Dropdown
                        _buildDropdownField(
                          label: 'Section',
                          value: _selectedSection,
                          items: _sectionOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedSection = value;
                            });
                          },
                          hint: 'Pilih Section',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // UP3 Display (Static)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UP3',
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'UP3 PAREPARE',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // ULP Dropdown
                        _buildDropdownField(
                          label: 'ULP',
                          value: _selectedUlp,
                          items: _ulpOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedUlp = value;
                            });
                          },
                          hint: 'Pilih ULP',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Penyulang Dropdown
                        _buildDropdownField(
                          label: 'Penyulang',
                          value: _selectedPenyulang,
                          items: _penyulangOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedPenyulang = value;
                            });
                          },
                          hint: 'Pilih Penyulang',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Zona Proteksi Dropdown
                        _buildDropdownField(
                          label: 'Zona Proteksi',
                          value: _selectedZonaProteksi,
                          items: _zonaProteksiOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedZonaProteksi = value;
                            });
                          },
                          hint: 'Pilih Zona Proteksi',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Panjang KMS Text Field
                        _buildTextField(
                          label: 'Panjang KMS',
                          controller: _panjangKmsController,
                          hint: 'Masukkan Panjang KMS',
                          keyboardType: TextInputType.number,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Role Text Field
                        _buildTextField(
                          label: 'Role',
                          controller: _roleController,
                          hint: 'Masukkan Role',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Health Index Dropdown
                        _buildDropdownField(
                          label: 'Health Index',
                          value: _selectedHealthIndex,
                          items: _healthIndexOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedHealthIndex = value;
                            });
                          },
                          hint: 'Pilih Health Index',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Vendor VB Text Field
                        _buildTextField(
                          label: 'Vendor VB',
                          controller: _vendorVbController,
                          hint: 'Masukkan Vendor VB',
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Simpan Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleSimpan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF125E72), 
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Simpan',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (label == 'Panjang KMS' || label == 'Role' || label == 'Vendor VB') {
                if (value == null || value.isEmpty) {
                  return 'Field $label tidak boleh kosong';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  void _handleSimpan() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validasi dropdown yang wajib
      if (_selectedSection == null) {
        _showSnackBar('Pilih Section terlebih dahulu');
        return;
      }
      if (_selectedUlp == null) {
        _showSnackBar('Pilih ULP terlebih dahulu');
        return;
      }
      if (_selectedPenyulang == null) {
        _showSnackBar('Pilih Penyulang terlebih dahulu');
        return;
      }
      if (_selectedZonaProteksi == null) {
        _showSnackBar('Pilih Zona Proteksi terlebih dahulu');
        return;
      }
      if (_selectedHealthIndex == null) {
        _showSnackBar('Pilih Health Index terlebih dahulu');
        return;
      }
      
      // Jika validasi berhasil
      _showSnackBar('Data berhasil disimpan!');
      
      // Di sini Anda bisa menambahkan logika untuk menyimpan data
      // Misalnya ke database, API, dll.
      
      // Clear form setelah berhasil simpan
      _clearForm();
      
      // Kembali ke halaman sebelumnya
      Navigator.pop(context);
    }
  }
  
  void _clearForm() {
    setState(() {
      _selectedSection = null;
      _selectedUlp = null;
      _selectedPenyulang = null;
      _selectedZonaProteksi = null;
      _selectedHealthIndex = null;
    });
    _panjangKmsController.clear();
    _roleController.clear();
    _vendorVbController.clear();
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: message.contains('berhasil') 
            ? Colors.green 
            : Colors.red,
      ),
    );
  }
  
  @override
  void dispose() {
    _panjangKmsController.dispose();
    _roleController.dispose();
    _vendorVbController.dispose();
    super.dispose();
  }
}