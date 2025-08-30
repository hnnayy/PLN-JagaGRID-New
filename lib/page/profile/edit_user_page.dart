import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, String> user; // data user yang lama

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController fullNameController;
  late TextEditingController usernameController;
  String? selectedUnit;
  late String addedDate;

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
    addedDate = widget.user["added"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFC6B21F),
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
            // Full name
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: "Full name",
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // Username
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // 🔽 DropdownSearch (searchable)
            DropdownSearch<String>(
              items: (f, cs) => units, // ✅ versi terbaru v6.x
              selectedItem: selectedUnit,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Unit",
                  filled: true,
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true, // 🔥 bisa diketik
              ),
              onChanged: (value) {
                setState(() {
                  selectedUnit = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Added date (read-only)
            TextField(
              enabled: false,
              controller: TextEditingController(text: addedDate),
              decoration: const InputDecoration(
                labelText: "Ditambahkan",
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            // Button Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5D6F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final updatedUser = {
                    "name": fullNameController.text,
                    "username": usernameController.text,
                    "unit": selectedUnit ?? "",
                    "added": addedDate,
                  };

                  Navigator.pop(context, updatedUser); // kirim balik data baru
                },
                child: const Text(
                  "SIMPAN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}