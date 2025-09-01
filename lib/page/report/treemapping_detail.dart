import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../providers/eksekusi_provider.dart';
import '../../constants/colors.dart';
import '../../services/eksekusi_service.dart';
import 'eksekusi.dart';

class TreeMappingDetailPage extends StatefulWidget {
  final DataPohon? pohon;

  const TreeMappingDetailPage({super.key, this.pohon});

  @override
  _TreeMappingDetailPageState createState() => _TreeMappingDetailPageState();
}

class _TreeMappingDetailPageState extends State<TreeMappingDetailPage> {
  late GoogleMapController _mapController;
  late LatLng _initialPosition;
  MapType _currentMapType = MapType.satellite;
  Set<Marker> _markers = {};
  final EksekusiService _eksekusiService = EksekusiService();

  @override
  void initState() {
    super.initState();
    if (widget.pohon != null && widget.pohon!.koordinat.isNotEmpty) {
      try {
        final coords = widget.pohon!.koordinat.split(',');
        if (coords.length == 2) {
          final lat = double.parse(coords[0].trim());
          final lng = double.parse(coords[1].trim());
          _initialPosition = LatLng(lat, lng);
        } else {
          developer.log('Koordinat tidak valid: ${widget.pohon!.koordinat}', name: 'TreeMappingDetailPage');
          _initialPosition = const LatLng(-4.0167, 120.1833);
        }
      } catch (e) {
        developer.log('Error parsing koordinat: $e', name: 'TreeMappingDetailPage');
        _initialPosition = const LatLng(-4.0167, 120.1833);
      }
    } else {
      developer.log('Koordinat kosong atau pohon null', name: 'TreeMappingDetailPage');
      _initialPosition = const LatLng(-4.0167, 120.1833);
    }

    _markers.add(
      Marker(
        markerId: MarkerId('tree_${widget.pohon?.id ?? "unknown"}'),
        position: _initialPosition,
        infoWindow: InfoWindow(title: 'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Load eksekusi data when the page initializes
    _loadEksekusi();
  }

  Future<void> _loadEksekusi() async {
    try {
      final eksekusiProvider = Provider.of<EksekusiProvider>(context, listen: false);
      eksekusiProvider.setEksekusiStream(_eksekusiService.getAllEksekusi());
    } catch (e) {
      developer.log('Error loading eksekusi: $e', name: 'TreeMappingDetailPage');
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double fontSize = screenWidth * 0.04; // Calculate font size dynamically

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: fontSize, // Use the dynamic font size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: widget.pohon == null
          ? const Center(child: Text('Data pohon tidak tersedia'))
          : SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Tipe Peta:',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.white,
                                iconTheme: const IconThemeData(color: Colors.white),
                              ),
                              child: DropdownButton<MapType>(
                                value: _currentMapType,
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: fontSize),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                    value: MapType.normal,
                                    child: Text('Normal', style: TextStyle(color: Colors.black)),
                                  ),
                                  DropdownMenuItem(
                                    value: MapType.satellite,
                                    child: Text('Satelit', style: TextStyle(color: Colors.black)),
                                  ),
                                  DropdownMenuItem(
                                    value: MapType.terrain,
                                    child: Text('Terrain', style: TextStyle(color: Colors.black)),
                                  ),
                                  DropdownMenuItem(
                                    value: MapType.hybrid,
                                    child: Text('Hybrid', style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                                onChanged: (type) {
                                  if (type != null) {
                                    setState(() {
                                      _currentMapType = type;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition,
                            zoom: 15.0,
                          ),
                          mapType: _currentMapType,
                          minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                      ),
                    ],
                  ),
                  Consumer<EksekusiProvider>(
                    builder: (context, eksekusiProvider, child) {
                      final eksekusiList = eksekusiProvider.eksekusiList;
                      developer.log('eksekusiList: $eksekusiList', name: 'TreeMappingDetailPage');
                      final latestEksekusi = widget.pohon != null
                          ? eksekusiList.firstWhere(
                              (eksekusi) => eksekusi.dataPohonId == widget.pohon!.id,
                              orElse: () => Eksekusi(
                                id: '',
                                dataPohonId: widget.pohon!.id,
                                statusEksekusi: 0,
                                tanggalEksekusi: Timestamp.now(),
                                fotoSetelah: '',
                                createdBy: 0,
                                createdDate: Timestamp.now(),
                                status: 0,
                                tinggiPohon: 0.0,
                                diameterPohon: 0.0,
                              ),
                            )
                          : null;
                      final relatedEksekusi = widget.pohon != null
                          ? eksekusiList.where((eksekusi) => eksekusi.dataPohonId == widget.pohon!.id).toList()
                          : <Eksekusi>[];
                      developer.log('relatedEksekusi: $relatedEksekusi', name: 'TreeMappingDetailPage');

                      return DraggableScrollableSheet(
                        initialChildSize: 0.1,
                        minChildSize: 0.1,
                        maxChildSize: 0.9,
                        builder: (BuildContext context, ScrollController scrollController) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(0),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      Center(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          width: screenWidth * 0.15,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                        child: Text(
                                          'Pohon ID #${widget.pohon!.idPohon}',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlue[50],
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: widget.pohon!.fotoPohon.isNotEmpty
                                                    ? widget.pohon!.fotoPohon
                                                    : 'https://via.placeholder.com/150?text=Foto+Sebelum',
                                                width: screenWidth * 0.8,
                                                height: screenHeight * 0.25,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  width: screenWidth * 0.8,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(child: CircularProgressIndicator()),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  width: screenWidth * 0.8,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(child: Text('Gambar Tidak Tersedia')),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Sektor',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.up3.isNotEmpty && widget.pohon!.ulp.isNotEmpty
                                                      ? '${widget.pohon!.up3}, ${widget.pohon!.ulp}'
                                                      : 'Parepare, Sulawesi Selatan',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Vendor VB',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.vendor.isNotEmpty
                                                      ? widget.pohon!.vendor
                                                      : 'PT PLN PERAMBAS',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Nama Pohon',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.namaPohon.isNotEmpty
                                                      ? widget.pohon!.namaPohon
                                                      : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Penyulang',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.penyulang.isNotEmpty
                                                      ? widget.pohon!.penyulang
                                                      : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Zona Proteksi',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.zonaProteksi.isNotEmpty
                                                      ? widget.pohon!.zonaProteksi
                                                      : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Section',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.section.isNotEmpty
                                                      ? widget.pohon!.section
                                                      : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'KMS Aset',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.kmsAset.isNotEmpty
                                                      ? widget.pohon!.kmsAset
                                                      : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Tanggal Penjadwalan',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${widget.pohon!.scheduleDate.day}/${widget.pohon!.scheduleDate.month}/${widget.pohon!.scheduleDate.year}',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Tujuan Penindakan',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.tujuanPenjadwalan == 1
                                                      ? 'Penebangan'
                                                      : widget.pohon!.tujuanPenjadwalan == 2
                                                          ? 'Pemangkasan'
                                                          : 'Penanaman ulang strategis',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Deskripsi',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.tujuanPenjadwalan == 1
                                                      ? 'Pohon akan ditebang.'
                                                      : widget.pohon!.tujuanPenjadwalan == 2
                                                          ? 'Pohon akan dipangkas.'
                                                          : 'Pohon ini berada di lokasi strategis untuk penanaman ulang.',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Catatan Tambahan',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  widget.pohon!.catatan.isNotEmpty
                                                      ? widget.pohon!.catatan
                                                      : 'Perlu perhatian khusus',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              latestEksekusi != null && latestEksekusi.fotoSetelah != null && latestEksekusi.fotoSetelah!.isNotEmpty
                                                  ? 'Sudah Dieksekusi'
                                                  : 'Belum Dieksekusi',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: latestEksekusi != null && latestEksekusi.fotoSetelah != null && latestEksekusi.fotoSetelah!.isNotEmpty
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (latestEksekusi != null && latestEksekusi.id.isNotEmpty && latestEksekusi.fotoSetelah != null && latestEksekusi.fotoSetelah!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.lightGreen[50],
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Eksekusi Terbaru',
                                                style: TextStyle(
                                                  fontSize: fontSize * 1.125, // Slightly larger for title
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: CachedNetworkImage(
                                                  imageUrl: latestEksekusi.fotoSetelah!,
                                                  width: screenWidth * 0.8,
                                                  height: screenHeight * 0.25,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: screenWidth * 0.8,
                                                    height: screenHeight * 0.25,
                                                    color: Colors.grey,
                                                    child: const Center(child: CircularProgressIndicator()),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    width: screenWidth * 0.8,
                                                    height: screenHeight * 0.25,
                                                    color: Colors.grey,
                                                    child: const Center(child: Text('Gambar Tidak Tersedia')),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Tanggal Eksekusi',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${latestEksekusi.tanggalEksekusi.toDate().day}/${latestEksekusi.tanggalEksekusi.toDate().month}/${latestEksekusi.tanggalEksekusi.toDate().year}',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Tinggi Pohon',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${latestEksekusi.tinggiPohon} m',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Diameter',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${latestEksekusi.diameterPohon} cm',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Status Eksekusi',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    latestEksekusi.statusEksekusi == 1
                                                        ? 'Penebangan'
                                                        : latestEksekusi.statusEksekusi == 2
                                                            ? 'Pemangkasan'
                                                            : 'Lainnya',
                                                    style: TextStyle(
                                                      fontSize: fontSize,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlue[50],
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Riwayat Eksekusi',
                                              style: TextStyle(
                                                fontSize: fontSize * 1.125, // Slightly larger for title
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            if (relatedEksekusi.isEmpty)
                                              const Text(
                                                'Belum ada riwayat eksekusi',
                                                style: TextStyle(
                                                  fontSize: 16.0, // Default size if screenWidth is unavailable
                                                  color: Colors.grey,
                                                ),
                                              )
                                            else
                                              Column(
                                                children: relatedEksekusi.map((eksekusi) {
                                                  developer.log('Rendering eksekusi: $eksekusi', name: 'TreeMappingDetailPage');
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 16.0),
                                                    padding: const EdgeInsets.all(12.0),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(color: Colors.grey[300]!),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'ID',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${eksekusi.id ?? 'Tidak tersedia'}',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Tanggal Eksekusi',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          eksekusi.tanggalEksekusi != null
                                                              ? '${eksekusi.tanggalEksekusi!.toDate().day}/${eksekusi.tanggalEksekusi!.toDate().month}/${eksekusi.tanggalEksekusi!.toDate().year}'
                                                              : 'Tidak tersedia',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Tinggi Pohon',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${eksekusi.tinggiPohon ?? 'Tidak tersedia'} m',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Diameter',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${eksekusi.diameterPohon ?? 'Tidak tersedia'} cm',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Status Eksekusi',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          eksekusi.statusEksekusi == 1
                                                              ? 'Penebangan'
                                                              : eksekusi.statusEksekusi == 2
                                                                  ? 'Pemangkasan'
                                                                  : 'Lainnya',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Foto Setelah',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        if (eksekusi.fotoSetelah != null && eksekusi.fotoSetelah!.isNotEmpty)
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(12),
                                                            child: CachedNetworkImage(
                                                              imageUrl: eksekusi.fotoSetelah!,
                                                              width: screenWidth * 0.8,
                                                              height: screenHeight * 0.25,
                                                              fit: BoxFit.cover,
                                                              placeholder: (context, url) => Container(
                                                                width: screenWidth * 0.8,
                                                                height: screenHeight * 0.25,
                                                                color: Colors.grey,
                                                                child: const Center(child: CircularProgressIndicator()),
                                                              ),
                                                              errorWidget: (context, url, error) => Container(
                                                                width: screenWidth * 0.8,
                                                                height: screenHeight * 0.25,
                                                                color: Colors.grey,
                                                                child: const Center(child: Text('Gambar Tidak Tersedia')),
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            width: screenWidth * 0.8,
                                                            height: screenHeight * 0.25,
                                                            color: Colors.grey,
                                                            child: const Center(child: Text('Gambar Tidak Tersedia')),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => EksekusiPage(pohon: widget.pohon!)),
                                            );
                                            // Refresh eksekusi data after returning
                                            await _loadEksekusi();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0B5F6D),
                                            minimumSize: Size(screenWidth * 0.9, screenHeight * 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'Eksekusi',
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}