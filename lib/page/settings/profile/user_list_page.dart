import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_user_page.dart';
import 'form_add_user_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  void _addNewUser() async {
    final newUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormAddUserPage()),
    );
    if (newUser != null && mounted) {
      _showSnackBar("User ${newUser["name"] ?? "baru"} berhasil ditambahkan", Colors.green, Icons.check_circle);
    }
  }

  void _editUser(Map<String, dynamic> user, String docId) async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserPage(user: user, docId: docId)),
    );
    if (updatedUser != null && mounted) {
      _showSnackBar("${updatedUser["name"]} berhasil diupdate", const Color(0xFF125E72), Icons.edit);
    }
  }

  void _deleteUser(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection("users").doc(docId).delete();
              _showSnackBar("$name berhasil dihapus", Colors.red, Icons.delete);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
      body: Column(
        children: [
          // Extended AppBar Background
          Container(
            decoration: const BoxDecoration(color: Color(0xFF125E72)),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 56, // Standard AppBar height
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Daftar User",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 23),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.white, size: 34),
                          onPressed: _addNewUser,
                          tooltip: "Tambah User",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // Extended background height
                ],
              ),
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Cari berdasarkan nama, username, unit, atau telegram...",
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                        onPressed: () => setState(() {
                          searchController.clear();
                          searchQuery = "";
                        }),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          // User Count
          if (searchQuery.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF125E72), Color(0xFF14A2B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("users").snapshots(),
                builder: (context, snapshot) {
                  final totalUsers = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Total $totalUsers User Terdaftar",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          // User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("users").orderBy("added", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text("Terjadi kesalahan", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14A2B9))),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final query = searchQuery.toLowerCase();
                  return data["name"].toString().toLowerCase().contains(query) ||
                      data["username"].toString().toLowerCase().contains(query) ||
                      data["unit"].toString().toLowerCase().contains(query) ||
                      (data["username_telegram"] ?? "").toString().toLowerCase().contains(query) ||
                      (data["chat_id_telegram"] ?? "").toString().toLowerCase().contains(query);
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildUserCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isNotEmpty ? "Tidak ditemukan" : "Belum ada user",
            style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? "Tidak ada user yang cocok dengan '$searchQuery'"
                : "Tambahkan user pertama Anda",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                searchController.clear();
                searchQuery = "";
              }),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text("Hapus Pencarian"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF125E72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFF125E72), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      (data["name"] ?? "U").toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["name"] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF125E72)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data["username"] ?? "-",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: const Color(0xFF14A2B9),
                        onPressed: () => _editUser(data, docId),
                        tooltip: "Edit User",
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => _deleteUser(docId, data["name"] ?? ""),
                        tooltip: "Hapus User",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 16),
            // Info rows
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow("Unit", data["unit"] ?? "-"),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildInfoRow("Username Telegram", data["username_telegram"] ?? "-"),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildInfoRow("Chat ID Telegram", data["chat_id_telegram"] ?? "-"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}