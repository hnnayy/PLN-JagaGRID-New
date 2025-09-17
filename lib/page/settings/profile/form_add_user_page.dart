import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.onChanged
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), 
      vsync: this
    );
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
                          color: widget.value == widget.items[index] 
                            ? const Color(0xFFF0F9FF) 
                            : null
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
                      widget.value ?? 'Pilih unit kerja', 
                      style: TextStyle(
                        fontSize: 16, 
                        color: widget.value != null 
                          ? Colors.black87 
                          : Colors.grey.shade500
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

class FormAddUserPage extends StatefulWidget {
  const FormAddUserPage({super.key});

  @override
  State<FormAddUserPage> createState() => _FormAddUserPageState();
}

class _FormAddUserPageState extends State<FormAddUserPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedUnit;
  int selectedLevel = 2; // Default: 2 untuk unit layanan
  final units = [
    "UNIT INDUK UP3 PAREPARE",
    "ULP MATTIROTASI", 
    "ULP BARRU", 
    "ULP RAPPANG", 
    "ULP PANGSID", 
    "ULP TANRUTEDONG", 
    "ULP SOPPENG", 
    "ULP PAJALESANG", 
    "ULP MAKASSAR", 
    "ULP BONE"
  ];
  
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final telegramUsernameController = TextEditingController();
  final telegramChatIdController = TextEditingController();
  final passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _saveUser() async {
    if (selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih unit kerja terlebih dahulu"), 
          backgroundColor: Colors.red
        )
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Cek username sudah ada atau belum
        final username = usernameController.text.trim().startsWith('@') 
          ? usernameController.text.trim() 
          : '@${usernameController.text.trim()}';

        final existingUser = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

        if (existingUser.docs.isNotEmpty) {
          setState(() => _isLoading = false);
          _showErrorAlert("Username sudah terdaftar dalam sistem");
          return;
        }

        final newUser = {
          "name": fullNameController.text.trim(),
          "username": username,
          "unit": selectedUnit!,
          "level": selectedLevel,
          "password": passwordController.text.trim(),
          "added": getCurrentDate(),
          "username_telegram": telegramUsernameController.text.trim(),
          "chat_id_telegram": telegramChatIdController.text.trim(),
          "status": 1,
        };

        final docRef = await FirebaseFirestore.instance
            .collection("users")
            .add(newUser);
        
        newUser["id"] = docRef.id;

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessAlert();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorAlert("Gagal menyimpan user: ${e.toString()}");
      }
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16), 
            color: Colors.white
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
                  shape: BoxShape.circle
                ),
                child: const Icon(
                  Icons.check, 
                  size: 45, 
                  color: Colors.white
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                "Berhasil!",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF2E5D6F)
                )
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                "User berhasil ditambahkan ke sistem",
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey.shade600
                ), 
                textAlign: TextAlign.center
              ),
              
              const SizedBox(height: 32),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _resetForm(); // Reset form
                  },
                  child: const Text(
                    "OK", 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 16
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorAlert(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16), 
            color: Colors.white
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                width: 80, 
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red, 
                  shape: BoxShape.circle
                ),
                child: const Icon(
                  Icons.close, 
                  size: 45, 
                  color: Colors.white
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                "Gagal!",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF2E5D6F)
                )
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey.shade600
                ), 
                textAlign: TextAlign.center
              ),
              
              const SizedBox(height: 32),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "OK", 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 16
                    )
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
      selectedUnit = null;
      selectedLevel = 2; // Reset ke default
      fullNameController.clear();
      usernameController.clear();
      telegramUsernameController.clear();
      telegramChatIdController.clear();
      passwordController.clear();
      _isPasswordVisible = false;
    });
  }

  Widget _buildField(
    String label, 
    TextEditingController controller, {
    bool obscureText = false, 
    Widget? suffixIcon, 
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            color: Colors.grey.shade600, 
            fontWeight: FontWeight.w500
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none, 
              borderRadius: BorderRadius.all(Radius.circular(8))
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2E5D6F), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffixIcon,
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
          onPressed: () => Navigator.of(context).pop()
        ),
        title: const Text(
          "Tambah User Baru", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white, 
            fontSize: 20
          )
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), 
            topRight: Radius.circular(32)
          )
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Unit Kerja Dropdown
              CustomDropdown(
                value: selectedUnit, 
                items: units, 
                labelText: "Pilih Unit Kerja", 
                onChanged: (value) => setState(() => selectedUnit = value)
              ),
              
              const SizedBox(height: 20),
              
              // Radio Pilihan Level (setelah unit kerja)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Level Unit", 
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.grey.shade600, 
                      fontWeight: FontWeight.w500
                    )
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 1,
                              groupValue: selectedLevel,
                              onChanged: (value) => setState(() => selectedLevel = value!),
                              activeColor: const Color(0xFF2E5D6F),
                            ),
                            const Text(
                              'Unit Induk',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 2,
                              groupValue: selectedLevel,
                              onChanged: (value) => setState(() => selectedLevel = value!),
                              activeColor: const Color(0xFF2E5D6F),
                            ),
                            const Text(
                              'Unit Layanan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Nama Lengkap
              _buildField(
                "Nama Lengkap", 
                fullNameController, 
                validator: (value) => value?.trim().isEmpty ?? true 
                  ? "Nama tidak boleh kosong" 
                  : null
              ),
              
              const SizedBox(height: 20),
              
              // Username
              _buildField(
                "Username", 
                usernameController, 
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return "Username tidak boleh kosong";
                  }
                  if (value!.trim().length < 3) {
                    return "Username minimal 3 karakter";
                  }
                  return null;
                }
              ),
              
              const SizedBox(height: 20),
              
              // Username Telegram
              _buildField(
                "Username Telegram", 
                telegramUsernameController, 
                validator: (value) => value?.trim().isEmpty ?? true 
                  ? "Username Telegram tidak boleh kosong" 
                  : null
              ),
              
              const SizedBox(height: 20),
              
              // Chat ID Telegram
              _buildField(
                "Chat ID Telegram", 
                telegramChatIdController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.trim().isEmpty ?? true 
                  ? "Chat ID Telegram tidak boleh kosong" 
                  : null
              ),
              
              const SizedBox(height: 20),
              
              // Password
              _buildField(
                "Password", 
                passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                    color: Colors.grey
                  ), 
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Password tidak boleh kosong";
                  }
                  if (value!.length < 6) {
                    return "Password minimal 6 karakter";
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Simpan User",
                        style: TextStyle(
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

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    telegramUsernameController.dispose();
    telegramChatIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}