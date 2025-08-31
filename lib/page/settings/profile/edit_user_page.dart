import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user; // pakai dynamic biar fleksibel
  final String docId;              // ID dokumen di Firestore

  const EditUserPage({
    super.key,
    required this.user,
    required this.docId,
  });

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController fullNameController;
  late TextEditingController usernameController;
  late TextEditingController addedDateController;
  String? selectedUnit;

  final List<String> units = [
    "Ulp Sengkang",
    "Ulp Parepare",
    "Ulp Makassar",
    "Ulp Bone",
    "Ulp Sidrap",
  ];

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.user["name"]);
    usernameController = TextEditingController(text: widget.user["username"]);
    selectedUnit = widget.user["unit"];
    addedDateController = TextEditingController(text: widget.user["added"] ?? "");
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _saveUser() async {
    final updatedUser = {
      "name": fullNameController.text,
      "username": usernameController.text,
      "unit": selectedUnit ?? "",
      "added": addedDateController.text,
    };

    try {
      await FirebaseFirestore.instance
          .collection("data_pohon")   // ✅ sesuai struktur Firestore kamu
          .doc(widget.docId)
          .update(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User berhasil diupdate"),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update user: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF14A2B9),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: _inputDecoration("Full Name"),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: usernameController,
              decoration: _inputDecoration("Username"),
            ),
            const SizedBox(height: 16),

            DropdownSearch<String>(
              items: (f, cs) => units,
              selectedItem: selectedUnit,
              decoratorProps: DropDownDecoratorProps(
                decoration: _inputDecoration("Unit"),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
              ),
              onChanged: (value) {
                setState(() {
                  selectedUnit = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              enabled: false,
              controller: addedDateController,
              decoration: _inputDecoration("Ditambahkan"),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "Save Changes",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14A2B9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveUser,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
