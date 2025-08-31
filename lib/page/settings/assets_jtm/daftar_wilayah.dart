import 'package:flutter/material.dart';
import 'daftar_section.dart'; // Import halaman DaftarSectionPage

class DaftarWilayahPage extends StatefulWidget {
  @override
  _DaftarWilayahPageState createState() => _DaftarWilayahPageState();
}

class _DaftarWilayahPageState extends State<DaftarWilayahPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _ulpList = [
    'DATABASE',
  ];
  
  List<String> _filteredUlpList = [];

  @override
  void initState() {
    super.initState();
    _filteredUlpList = _ulpList;
    _searchController.addListener(_filterUlpList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUlpList() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUlpList = _ulpList
          .where((ulp) => ulp.toLowerCase().contains(query))
          .toList();
    });
  }

  // Fungsi untuk handle navigasi ketika item diklik
  void _onItemTap(String ulpName) {
    if (ulpName == 'DATABASE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DaftarSectionPage(),
        ),
      );
    }
    // Anda bisa menambahkan kondisi lain untuk item-item lainnya di masa depan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF125E72), // Warna teal seperti di gambar
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daftar Wilayah', // Ubah title menjadi "Daftar Wilayah"
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.02,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.04,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: MediaQuery.of(context).size.width * 0.06,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            // ULP List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
                itemCount: _filteredUlpList.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFF125E72),
                  thickness: 1,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  return _buildUlpListItem(_filteredUlpList[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUlpListItem(String ulpName) {
    return InkWell( // Tambahkan InkWell untuk membuat item dapat diklik
      onTap: () => _onItemTap(ulpName), // Panggil fungsi navigasi
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.02,
          horizontal: MediaQuery.of(context).size.width * 0.02,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ulpName,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: MediaQuery.of(context).size.width * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}