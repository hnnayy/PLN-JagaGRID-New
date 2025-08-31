import 'package:flutter/material.dart';

class FormAddUserPage extends StatefulWidget {
  const FormAddUserPage({super.key});

  @override
  State<FormAddUserPage> createState() => _FormAddUserPageState();
}

class _FormAddUserPageState extends State<FormAddUserPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedUnit;
  final List<String> units = [
    "ULP MATTIROTASI",
    "ULP BARRU",
    "ULP RAPPANG",
    "ULP PANGSID",
    "ULP TANRUTEDONG",
    "ULP SOPPENG",
    "ULP PAJALESANG",
    "ULP MAKASSAR",
    "ULP BONE",
  ];

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Ambil tanggal sekarang
  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // Format username
  String formatUsername(String username) {
    if (username.startsWith('@')) {
      return username;
    }
    return '@$username';
  }

  // Simpan user
  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      final newUser = {
        "name": fullNameController.text.trim(),
        "username": formatUsername(usernameController.text.trim()),
        "unit": selectedUnit!,
        "added": getCurrentDate(),
        "password": passwordController.text,
      };

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSuccessDialog(newUser);
      }
    }
  }

  // Dialog sukses dengan background putih dan text hitam
  void _showSuccessDialog(Map<String, String> newUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white, // Background putih
              border: Border.all(
                color: const Color(0xFF14A2B9), 
                width: 2
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon sukses
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14A2B9), // Ubah dari kuning ke biru
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14A2B9).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 50, color: Colors.white), // Ikon putih
                ),
                const SizedBox(height: 20),
                const Text(
                  "Berhasil!",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black), // Text hitam
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "User ${newUser["name"]} berhasil ditambahkan",
                  style: const TextStyle(
                    fontSize: 16, 
                    color: Colors.black87 // Text hitam
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF14A2B9)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _formKey.currentState?.reset();
                          setState(() {
                            selectedUnit = null;
                            fullNameController.clear();
                            usernameController.clear();
                            passwordController.clear();
                          });
                        },
                        icon: const Icon(Icons.person_add,
                            color: Color(0xFF14A2B9), size: 18),
                        label: const Text("Tambah Lagi",
                            style: TextStyle(
                                color: Color(0xFF14A2B9), // Text biru
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14A2B9), // Background biru
                          foregroundColor: Colors.white, // Text putih
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pop(context, newUser);
                        },
                        icon: const Icon(Icons.list_rounded, size: 18),
                        label: const Text("Lihat List",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
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
          "Tambah User Baru",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_add,
                      size: 40, color: Color(0xFF14A2B9)),
                ),
              ),
              const SizedBox(height: 32),
              // Dropdown Unit dengan scroll dan menampilkan 3 item
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Pilih Unit Kerja",
                  filled: true,
                  fillColor: const Color(0xFFF0F9FF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                value: selectedUnit,
                menuMaxHeight: 200, // Membatasi tinggi dropdown
                items: units
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedUnit = v),
                validator: (v) =>
                    v == null ? "Pilih unit kerja terlebih dahulu" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    filled: true,
                    fillColor: Color(0xFFF0F9FF),
                    border: OutlineInputBorder(borderSide: BorderSide.none)),
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama lengkap wajib diisi" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                    labelText: "Username",
                    filled: true,
                    fillColor: Color(0xFFF0F9FF),
                    border: OutlineInputBorder(borderSide: BorderSide.none)),
                validator: (v) =>
                    v == null || v.isEmpty ? "Username wajib diisi" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0F9FF),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.length < 6
                    ? "Password minimal 6 karakter"
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14A2B9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan User",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF14A2B9)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Batal",
                      style: TextStyle(
                          color: Color(0xFF14A2B9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
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
    passwordController.dispose();
    super.dispose();
  }
}