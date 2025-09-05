import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final Function(String?) onChanged;

  const CustomDropdown({super.key, required this.value, required this.items, required this.labelText, required this.onChanged});

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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
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
                        decoration: BoxDecoration(color: widget.value == widget.items[index] ? const Color(0xFFF0F9FF) : null),
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
        Text(widget.labelText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _dropdownKey,
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(child: Text(widget.value ?? 'Pilih unit kerja', style: TextStyle(fontSize: 16, color: widget.value != null ? Colors.black87 : Colors.grey.shade500))),
                  AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600)),
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
  final units = ["ULP MATTIROTASI", "ULP BARRU", "ULP RAPPANG", "ULP PANGSID", "ULP TANRUTEDONG", "ULP SOPPENG", "ULP PAJALESANG", "ULP MAKASSAR", "ULP BONE"];
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final telegramUsernameController = TextEditingController();
  final telegramChatIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false, _isLoading = false;

  String getCurrentDate() {
    final now = DateTime.now();
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _saveUser() async {
    if (selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pilih unit kerja terlebih dahulu"), backgroundColor: Colors.red));
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newUser = {
          "name": fullNameController.text.trim(),
          "username": usernameController.text.trim().startsWith('@') ? usernameController.text.trim() : '@${usernameController.text.trim()}',
          "unit": selectedUnit!,
          "added": getCurrentDate(),
          "password": passwordController.text.trim(),
          "telegramUsername": telegramUsernameController.text.trim(),
          "telegramChatId": telegramChatIdController.text.trim(),
        };

        final docRef = await FirebaseFirestore.instance.collection("users").add(newUser);
        newUser["id"] = docRef.id;

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog(Map<String, String>.from(newUser));
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan user: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showSuccessDialog(Map<String, String> newUser) {
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
                decoration: BoxDecoration(color: const Color(0xFF2E5D6F), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text("Berhasil!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E5D6F))),
              const SizedBox(height: 10),
              Text("User ${newUser["name"]} berhasil ditambahkan ke sistem", style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ("Nama", newUser["name"] ?? ""),
                    ("Username", newUser["username"] ?? ""),
                    ("Unit", newUser["unit"] ?? ""),
                    ("Ditambahkan", newUser["added"] ?? ""),
                    ("Username Telegram", newUser["telegramUsername"] ?? ""),
                    ("Chat ID Telegram", newUser["telegramChatId"] ?? ""),
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
                        _resetForm();
                      },
                      icon: Icon(Icons.person_add_rounded, color: Colors.grey.shade700, size: 20),
                      label: Text("Tambah Lagi", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5D6F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(context, newUser);
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      selectedUnit = null;
      fullNameController.clear();
      usernameController.clear();
      telegramUsernameController.clear();
      telegramChatIdController.clear();
      passwordController.clear();
    });
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscureText = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F9FF),
            border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8))),
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        title: const Text("Tambah User Baru", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CustomDropdown(value: selectedUnit, items: units, labelText: "Pilih Unit Kerja", onChanged: (value) => setState(() => selectedUnit = value)),
              const SizedBox(height: 20),
              _buildField("Nama Lengkap", fullNameController, validator: (value) => value?.isEmpty ?? true ? "Nama tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField("Username", usernameController, validator: (value) => value?.isEmpty ?? true ? "Username tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField("Username Telegram", telegramUsernameController, validator: (value) => value?.isEmpty ?? true ? "Username Telegram tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField("Chat ID Telegram", telegramChatIdController, validator: (value) => value?.isEmpty ?? true ? "Chat ID Telegram tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField(
                "Password", 
                passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                validator: (value) => (value?.length ?? 0) < 6 ? "Password minimal 6 karakter" : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5D6F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan User"),
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
  fullNameController.dispose();
  usernameController.dispose();
  telegramUsernameController.dispose();
  telegramChatIdController.dispose();
  passwordController.dispose();
  super.dispose();
  }
}