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

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String docId;

  const EditUserPage({super.key, required this.user, required this.docId});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController, usernameController, addedDateController, usernameTelegramController, chatIdTelegramController, passwordController;
  String? selectedUnit;
  int selectedLevel = 2; // Default: 2 untuk unit layanan
  bool _isLoading = false;
  bool _obscurePassword = true;

  final units = ["ULP MATTIROTASI", "ULP BARRU", "ULP RAPPANG", "ULP PANGSID", "ULP TANRUTEDONG", "ULP SOPPENG", "ULP PAJALESANG", "ULP MAKASSAR", "ULP BONE"];

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.user["name"]);
    usernameController = TextEditingController(text: widget.user["username"]);
    usernameTelegramController = TextEditingController(text: widget.user["username_telegram"]);
    chatIdTelegramController = TextEditingController(text: widget.user["chat_id_telegram"]);
    passwordController = TextEditingController(text: widget.user["password"]);
    selectedUnit = widget.user["unit"];
    selectedLevel = widget.user["level"] ?? 2; // Set level dari data user atau default 2
    addedDateController = TextEditingController(text: widget.user["added"] ?? "");
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    usernameTelegramController.dispose();
    chatIdTelegramController.dispose();
    passwordController.dispose();
    addedDateController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pilih unit kerja terlebih dahulu"), backgroundColor: Colors.red));
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final updatedUser = {
        "name": fullNameController.text.trim(),
        "username": usernameController.text.trim().startsWith('@') ? usernameController.text.trim() : '@${usernameController.text.trim()}',
        "unit": selectedUnit!,
        "level": selectedLevel,
        "username_telegram": usernameTelegramController.text.trim(),
        "chat_id_telegram": chatIdTelegramController.text.trim(),
        "password": passwordController.text.trim(),
        "added": addedDateController.text,
      };

      try {
        await FirebaseFirestore.instance.collection("users").doc(widget.docId).update(updatedUser);
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog(updatedUser);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update user: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> updatedUser) {
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
              Text("User ${updatedUser["name"]} berhasil diupdate", style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ("Nama", updatedUser["name"] ?? ""),
                    ("Username", updatedUser["username"] ?? ""),
                    ("Unit", updatedUser["unit"] ?? ""),
                    ("Level", updatedUser["level"] == 1 ? "Unit Induk" : "Unit Layanan"),
                    ("Username Telegram", updatedUser["username_telegram"] ?? "-"),
                    ("Chat ID Telegram", updatedUser["chat_id_telegram"] ?? "-"),
                    ("Ditambahkan", updatedUser["added"] ?? ""),
                  ].map((detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 120, child: Text("${detail.$1}:", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14))),
                        Expanded(child: Text(detail.$2, style: const TextStyle(color: Color(0xFF2E5D6F), fontSize: 14, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context); // Hanya kembali ke halaman sebelumnya tanpa mengirim data
                  },
                  icon: const Icon(Icons.list_rounded, size: 20),
                  label: const Text("Kembali ke List", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true, String? Function(String?)? validator, bool obscureText = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
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
        title: const Text("Edit User", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CustomDropdown(value: selectedUnit, items: units, labelText: "Unit Kerja", onChanged: (value) => setState(() => selectedUnit = value)),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pilih Level Unit", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
                            const Text('Unit Induk', style: TextStyle(fontSize: 16, color: Colors.black87)),
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
                            const Text('Unit Layanan', style: TextStyle(fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField("Nama Lengkap", fullNameController, validator: (value) => value?.isEmpty ?? true ? "Nama tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField("Username", usernameController, validator: (value) => value?.isEmpty ?? true ? "Username tidak boleh kosong" : null),
              const SizedBox(height: 20),
              _buildField("Username Telegram", usernameTelegramController),
              const SizedBox(height: 20),
              _buildField("Chat ID Telegram", chatIdTelegramController),
              const SizedBox(height: 20),
              _buildField(
                "Password", 
                passwordController, 
                obscureText: _obscurePassword,
                validator: (value) => value?.isEmpty ?? true ? "Password tidak boleh kosong" : null,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey.shade600),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),
              _buildField("Ditambahkan", addedDateController, enabled: false),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5D6F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update User", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}