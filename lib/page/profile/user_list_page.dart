import 'package:flutter/material.dart';
import 'edit_user_page.dart';
import 'form_add_user_page.dart'; // ✅ Ganti dari add_user_page.dart

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController searchController = TextEditingController();

  // ✅ Data users dengan format yang lebih konsisten
  List<Map<String, String>> users = [
    {
      "name": "Master John Walkin",
      "username": "@JohnWalkin",
      "unit": "ULP Makassar",
      "added": "01 Juli 2024",
    },
    {
      "name": "Jane Doe",
      "username": "@JaneDoe",
      "unit": "ULP Bone",
      "added": "05 Juli 2024",
    },
    {
      "name": "Michael Scott",
      "username": "@Michael",
      "unit": "ULP Makassar",
      "added": "10 Juli 2024",
    },
  ];

  String searchQuery = "";

  // ✅ Function untuk mendapatkan tanggal sekarang dalam format Indonesia
  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ✅ Function untuk menambah user baru
  void _addNewUser() async {
    try {
      final newUser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FormAddUserPage(),
        ),
      );

      print('Debug: Data yang diterima dari FormAddUserPage: $newUser'); // ✅ Debug log

      if (newUser != null && mounted) {
        setState(() {
          // ✅ Pastikan format data konsisten
          Map<String, String> userToAdd = {
            "name": newUser["name"]?.toString() ?? "User Baru",
            "username": newUser["username"]?.toString() ?? "@newuser",
            "unit": newUser["unit"]?.toString() ?? "Unit Tidak Diketahui", 
            "added": newUser["added"]?.toString() ?? getCurrentDate(),
          };
          
          users.add(userToAdd);
        });

        // ✅ Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User ${newUser["name"] ?? "baru"} berhasil ditambahkan"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saat menambah user: $e'); // ✅ Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menambahkan user. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Function untuk edit user
  void _editUser(Map<String, String> user, int index) async {
    try {
      final updatedUser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditUserPage(user: user),
        ),
      );

      if (updatedUser != null && mounted) {
        setState(() {
          // ✅ Update user di index yang tepat
          users[index] = Map<String, String>.from(updatedUser);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${updatedUser["name"]} berhasil diupdate"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saat edit user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengupdate user. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Function untuk hapus user
  void _deleteUser(Map<String, String> user, int index) {
    // ✅ Tampilkan dialog konfirmasi
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus ${user["name"]}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  users.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${user["name"]} berhasil dihapus"),
                    backgroundColor: Colors.orange,
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
    // ✅ Filter users berdasarkan search query
    final filteredUsers = users.where((user) {
      final query = searchQuery.toLowerCase();
      return user["name"]!.toLowerCase().contains(query) ||
          user["username"]!.toLowerCase().contains(query) ||
          user["unit"]!.toLowerCase().contains(query) ||
          user["added"]!.toLowerCase().contains(query);
    }).toList();

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
          "Daftar User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            fontSize: 20,
          ),
        ),
        actions: [
          // ✅ Badge untuk menampilkan jumlah user
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${users.length} User',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
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
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // 📋 List User
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
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
                              ? "User tidak ditemukan untuk '${searchQuery}'"
                              : "Belum ada user",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
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
                              style: TextStyle(color: Color(0xFFFFD700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final originalIndex = users.indexOf(user); // ✅ Get original index
                      
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
                                          user["name"]!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          user["username"]!,
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
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Unit: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: user["unit"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Ditambahkan
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Ditambahkan: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: user["added"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              
                              // ✅ Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFD700),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _editUser(user, originalIndex),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text(
                                        "Edit",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC6B21F),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _deleteUser(user, originalIndex),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text(
                                        "Hapus",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ✅ Floating Action Button untuk tambah user
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        onPressed: _addNewUser,
        icon: const Icon(Icons.person_add),
        label: const Text(
          "Tambah User",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}