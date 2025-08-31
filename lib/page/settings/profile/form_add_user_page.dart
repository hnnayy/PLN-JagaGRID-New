import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ✅ Tanggal sekarang
  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ✅ Format username (tambah @)
  String formatUsername(String username) {
    if (username.startsWith('@')) return username;
    return '@$username';
  }

  // ✅ Simpan user ke Firestore
  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final newUser = {
          "name": fullNameController.text.trim(),
          "username": formatUsername(usernameController.text.trim()),
          "unit": selectedUnit!,
          "added": getCurrentDate(),
          "password": passwordController.text.trim(),
        };

        // 🔥 Simpan ke koleksi users (sinkron dengan EditUserPage)
        final docRef = await FirebaseFirestore.instance
            .collection("users")
            .add(newUser);

        // Tambahkan docId ke map biar bisa dipakai di EditUserPage
        newUser["id"] = docRef.id;

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog(Map<String, String>.from(newUser));
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan user: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Success dialog
  void _showSuccessDialog(Map<String, String> newUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B5F6D), Color(0xFF0B5F6D)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Icon sukses
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 50,
                    color: Color(0xFF14A2B9),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Berhasil!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  "User ${newUser["name"]} berhasil ditambahkan",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ✅ Detail user
                _buildDetailRow("Nama", newUser["name"] ?? ""),
                _buildDetailRow("Username", newUser["username"] ?? ""),
                _buildDetailRow("Unit", newUser["unit"] ?? ""),
                _buildDetailRow("Ditambahkan", newUser["added"] ?? ""),

                const SizedBox(height: 20),

                // ✅ Tombol aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD700)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        icon: const Icon(Icons.person_add, color: Color(0xFFFFD700)),
                        label: const Text(
                          "Tambah Lagi",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF14A2B9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pop(context, newUser); // ⬅️ kirim balik ke UserListPage
                        },
                        icon: const Icon(Icons.list_rounded),
                        label: const Text("Lihat List"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Detail row
  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 UI tetap sama persis dengan versi kamu
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
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildForm(), // ⬅️ tetap pakai form lama
    );
  }

  // ✅ Pisahin form biar rapi
  Widget _buildForm() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
            // 🔹 Dropdown Unit
            DropdownButtonFormField<String>(
              value: selectedUnit,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Pilih Unit Kerja",
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: units
                  .map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit)))
                  .toList(),
              onChanged: (value) => setState(() => selectedUnit = value),
              validator: (value) =>
                  value == null ? "Pilih unit kerja terlebih dahulu" : null,
            ),
            const SizedBox(height: 20),

            // 🔹 Full name
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
                filled: true,
                fillColor: Color(0xFFF0F9FF),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Nama tidak boleh kosong" : null,
            ),
            const SizedBox(height: 20),

            // 🔹 Username
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                filled: true,
                fillColor: Color(0xFFF0F9FF),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Username tidak boleh kosong" : null,
            ),
            const SizedBox(height: 20),

            // 🔹 Password
            TextFormField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
              ),
              validator: (value) =>
                  value == null || value.length < 6 ? "Password minimal 6 karakter" : null,
            ),
            const SizedBox(height: 32),

            // 🔹 Tombol Simpan
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
                onPressed: _isLoading ? null : _saveUser,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan User"),
              ),
            ),
          ],
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
