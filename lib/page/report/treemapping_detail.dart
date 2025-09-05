import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/data_pohon.dart';
import '../../constants/colors.dart';
import 'eksekusi.dart';
import 'riwayat_eksekusi.dart'; // Import the RiwayatEksekusiPage
import 'dart:developer' as developer;

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

  @override
  void initState() {
    super.initState();
    // Gunakan koordinat dari pohon jika tersedia, fallback ke Parepare
    if (widget.pohon != null && widget.pohon!.koordinat.isNotEmpty) {
      try {
        final coords = widget.pohon!.koordinat.split(',');
        if (coords.length == 2) {
          final lat = double.parse(coords[0].trim());
          final lng = double.parse(coords[1].trim());
          _initialPosition = LatLng(lat, lng);
        } else {
          developer.log('Koordinat tidak valid: ${widget.pohon!.koordinat}', name: 'TreeMappingDetailPage');
          _initialPosition = const LatLng(-4.0167, 120.1833); // Fallback
        }
      } catch (e) {
        developer.log('Error parsing koordinat: $e', name: 'TreeMappingDetailPage');
        _initialPosition = const LatLng(-4.0167, 120.1833); // Fallback
      }
    } else {
      developer.log('Koordinat kosong atau pohon null', name: 'TreeMappingDetailPage');
      _initialPosition = const LatLng(-4.0167, 120.1833); // Parepare, Sulawesi Selatan
    }

    _markers.add(
      Marker(
        markerId: MarkerId('tree_${widget.pohon?.idPohon ?? "unknown"}'),
        position: _initialPosition,
        infoWindow: InfoWindow(title: 'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Log the tujuanPenjadwalan value for debugging
    if (widget.pohon != null) {
      developer.log('tujuanPenjadwalan dari DataPohon: ${widget.pohon!.tujuanPenjadwalan}', name: 'TreeMappingDetailPage');
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: widget.pohon == null
          ? const Center(child: Text('Data pohon tidak tersedia'))
          : SafeArea(
              child: Stack(
                children: [
                  // Map Section
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
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  // Draggable Sheet with Details
                  DraggableScrollableSheet(
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
                                  if (scrollController.hasClients && scrollController.position.pixels < 50)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                      child: Text(
                                        'Pohon ID #${widget.pohon!.idPohon}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                          child: Text(
                                            'Pohon ID #${widget.pohon!.idPohon}',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: widget.pohon!.fotoPohon.isNotEmpty
                                                    ? widget.pohon!.fotoPohon
                                                    : 'https://via.placeholder.com/150?text=Foto+Pohon',
                                                width: screenWidth * 0.7,
                                                height: screenHeight * 0.25,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  width: screenWidth * 0.7,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(child: CircularProgressIndicator()),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  width: screenWidth * 0.7,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(child: Text('Gambar Tidak Tersedia')),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: widget.pohon!.prioritas == 1
                                                    ? Colors.green // Rendah
                                                    : widget.pohon!.prioritas == 2
                                                        ? const Color(0xFFFFD700) // Sedang (kuning)
                                                        : Colors.red, // Tinggi
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Prioritas: ${widget.pohon!.prioritas == 1 ? "Rendah" : widget.pohon!.prioritas == 2 ? "Sedang" : "Tinggi"}',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ID Pohon',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.idPohon.isNotEmpty ? widget.pohon!.idPohon : 'P023',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Sektor',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.up3.isNotEmpty && widget.pohon!.ulp.isNotEmpty
                                                      ? '${widget.pohon!.up3}, ${widget.pohon!.ulp}'
                                                      : 'Parepare, Sulawesi Selatan',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Vendor VB',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.vendor.isNotEmpty ? widget.pohon!.vendor : 'PT PLN PERAMBAS',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Nama Pohon',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.namaPohon.isNotEmpty ? widget.pohon!.namaPohon : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Penyulang',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.penyulang.isNotEmpty ? widget.pohon!.penyulang : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Zona Proteksi',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.zonaProteksi.isNotEmpty ? widget.pohon!.zonaProteksi : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Section',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.section.isNotEmpty ? widget.pohon!.section : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'KMS Aset',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.kmsAset.isNotEmpty ? widget.pohon!.kmsAset : 'Tidak tersedia',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tanggal Penjadwalan',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  '${widget.pohon!.scheduleDate.day}/${widget.pohon!.scheduleDate.month}/${widget.pohon!.scheduleDate.year}',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tujuan Penindakan',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.tujuanPenjadwalan == 1
                                                      ? 'Pemangkasan' // Matches "Tebang Pangkas"
                                                      : widget.pohon!.tujuanPenjadwalan == 2
                                                          ? 'Penebangan' // Matches "Tebang Habis"
                                                          : widget.pohon!.tujuanPenjadwalan == null
                                                              ? 'Tidak diketahui'
                                                              : 'Penanaman ulang strategis',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Deskripsi',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.tujuanPenjadwalan == 1
                                                      ? 'Pohon akan dipangkas.'
                                                      : widget.pohon!.tujuanPenjadwalan == 2
                                                          ? 'Pohon akan ditebang.'
                                                          : widget.pohon!.tujuanPenjadwalan == null
                                                              ? 'Data tujuan tidak tersedia.'
                                                              : 'Pohon ini berada di lokasi strategis untuk penanaman ulang.',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Catatan Tambahan',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.catatan.isNotEmpty ? widget.pohon!.catatan : 'Perlu perhatian khusus untuk pemeliharaan.',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => EksekusiPage(pohon: widget.pohon!)),
                                                  );
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
                                                    fontSize: screenWidth * 0.04,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => RiwayatEksekusiPage(pohon: widget.pohon!)),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0B5F6D),
                                                  minimumSize: Size(screenWidth * 0.9, screenHeight * 0.06),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Lihat Riwayat Eksekusi',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}