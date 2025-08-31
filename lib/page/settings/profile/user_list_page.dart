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

  // ✅ Tambah user
  void _addNewUser() async {
    final newUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormAddUserPage()),
    );

    if (newUser != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User ${newUser["name"] ?? "baru"} berhasil ditambahkan"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ Edit user
  void _editUser(Map<String, dynamic> user, String docId) async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserPage(user: user, docId: docId),
      ),
    );

    if (updatedUser != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${updatedUser["name"]} berhasil diupdate"),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // ✅ Hapus user
  void _deleteUser(String docId, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(docId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$name berhasil dihapus"),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B5F6D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5F6D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Daftar User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: "Tambah User",
            onPressed: _addNewUser,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Cari user...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          // 📋 List User (dari Firestore)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .orderBy("added", descending: true) // urut berdasarkan tanggal ditambahkan
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final query = searchQuery.toLowerCase();
                  return data["name"].toString().toLowerCase().contains(query) ||
                      data["username"].toString().toLowerCase().contains(query) ||
                      data["unit"].toString().toLowerCase().contains(query) ||
                      data["added"].toString().toLowerCase().contains(query);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty ? Icons.search_off : Icons.person_off,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? "User tidak ditemukan untuk '$searchQuery'"
                              : "Belum ada user",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                searchQuery = "";
                              });
                            },
                            child: const Text(
                              "Hapus filter pencarian",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5A8CA7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data["name"] ?? "-",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        data["username"] ?? "-",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Unit
                            Text("Unit: ${data["unit"] ?? "-"}"),
                            Text("Ditambahkan: ${data["added"] ?? "-"}"),

                            const SizedBox(height: 16),

                            // ✅ Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF14A2B9),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: () => _editUser(data, docId),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text("Edit"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: () => _deleteUser(docId, data["name"] ?? ""),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text("Hapus"),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
