import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/data_pohon.dart';
import '../../constants/colors.dart';
import 'eksekusi.dart';
import 'riwayat_eksekusi.dart'; // Import the RiwayatEksekusiPage
import 'dart:developer' as developer;
import '../../services/asset_service.dart';
import '../../services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/growth_prediction.dart';

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
  late MarkerId _markerId;
  Future<String>? _asetJtmNameFuture;
  Future<String>? _createdByNameFuture;
  Future<DateTime>? _latestPlannedDateFuture;

  @override
  void initState() {
    super.initState();
    // Gunakan koordinat dari pohon jika tersedia, fallback ke Parepare
    if (widget.pohon != null && widget.pohon!.koordinat.isNotEmpty) {
      _initialPosition = _parseLatLngFromString(widget.pohon!.koordinat);
    } else {
      developer.log('Koordinat kosong atau pohon null', name: 'TreeMappingDetailPage');
      _initialPosition = const LatLng(-4.0167, 120.1833); // Parepare, Sulawesi Selatan
    }

    _markerId = MarkerId('tree_${widget.pohon?.idPohon ?? "unknown"}');

    final tujuan = widget.pohon?.tujuanPenjadwalan;
    final tujuanText = tujuan == 1
        ? 'Tebang Pangkas'
        : tujuan == 2
            ? 'Tebang Habis'
            : '-';

    // Tentukan warna marker berdasarkan prioritas agar konsisten dengan Map Page
    BitmapDescriptor icon;
    final prioritas = widget.pohon?.prioritas ?? 1;
    if (prioritas == 1) {
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (prioritas == 2) {
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else if (prioritas == 3) {
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      icon = BitmapDescriptor.defaultMarker;
    }

    _markers.add(
      Marker(
        markerId: _markerId,
        position: _initialPosition,
        infoWindow: InfoWindow(
          // Samakan dengan Map Page: tampilkan nama pohon sebagai judul
          title: widget.pohon?.namaPohon ?? 'Pohon',
          snippet: tujuanText,
        ),
        icon: icon,
      ),
    );

    // Log the tujuanPenjadwalan value for debugging
    if (widget.pohon != null) {
      developer.log('tujuanPenjadwalan dari DataPohon: ${widget.pohon!.tujuanPenjadwalan}', name: 'TreeMappingDetailPage');
    }

    // Prepare human-readable values
    if (widget.pohon != null) {
      _asetJtmNameFuture = _resolveAsetJtmName(widget.pohon!);
      _createdByNameFuture = _resolveCreatedByName(widget.pohon!);
      _latestPlannedDateFuture = _resolveLatestPlannedDate(widget.pohon!);
    }
  }

  // Robust coordinate parser: extracts first two numbers, swaps if order looks reversed
  LatLng _parseLatLngFromString(String input) {
    try {
      final numberMatches = RegExp(r'-?\d+(?:\.\d+)?').allMatches(input).toList();
      if (numberMatches.length < 2) {
        developer.log('Tidak menemukan dua angka dalam koordinat: $input', name: 'TreeMappingDetailPage');
        return const LatLng(-4.0167, 120.1833);
      }
      final a = double.parse(numberMatches[0].group(0)!);
      final b = double.parse(numberMatches[1].group(0)!);

      double lat = a;
      double lng = b;
      // If first number is likely longitude (>|90|) and second is latitude (<=|90|), swap
      bool aLooksLon = a.abs() > 90 && a.abs() <= 180;
      bool bLooksLat = b.abs() <= 90;
      if (aLooksLon && bLooksLat) {
        lat = b;
        lng = a;
      }

      // Validate ranges, otherwise fallback
      if (lat.abs() > 90 || lng.abs() > 180) {
        developer.log('Koordinat di luar jangkauan: lat=$lat, lng=$lng, input=$input', name: 'TreeMappingDetailPage');
        return const LatLng(-4.0167, 120.1833);
      }
      return LatLng(lat, lng);
    } catch (e) {
      developer.log('Gagal parsing koordinat: $e, input=$input', name: 'TreeMappingDetailPage');
      return const LatLng(-4.0167, 120.1833);
    }
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _formatDateTime(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

  String _getMapTypeLabel(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return 'Normal';
      case MapType.satellite:
        return 'Satelit';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
      default:
        return 'Normal';
    }
  }

  // Ambil tanggal penjadwalan dinamis: jika ada prediksi, pakai predicted_next_execution terbaru; jika tidak ada, gunakan scheduleDate awal
  Future<DateTime> _resolveLatestPlannedDate(DataPohon pohon) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('growth_predictions')
          .where('data_pohon_id', isEqualTo: pohon.id)
          .where('status', isEqualTo: 1)
          .get();

      final preds = snap.docs
          .map((d) => GrowthPrediction.fromMap(d.data(), d.id))
          .toList();
      if (preds.isEmpty) return pohon.scheduleDate;

      preds.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      // Use the most recent created prediction's predicted date
      return preds.first.predictedNextExecution;
    } catch (_) {
      return pohon.scheduleDate;
    }
  }

  Future<String> _resolveAsetJtmName(DataPohon pohon) async {
    try {
      // Treat asetJtmId as Firestore doc id string if possible
      final id = pohon.asetJtmId.toString();
      final service = AssetService();
      final asset = await service.getAssetById(id);
      if (asset != null) {
        // Compose a meaningful label
        final parts = [
          asset.penyulang,
          if (asset.section.isNotEmpty) 'Section ${asset.section}',
          if (asset.zonaProteksi.isNotEmpty) 'Zona ${asset.zonaProteksi}',
        ].where((e) => e.trim().isNotEmpty).join(' • ');
        return parts.isNotEmpty ? parts : 'Asset ${asset.id}';
      }
      // Fallback: coba cari berdasarkan kombinasi field dari pohon
      final matched = await service.findBestMatchingAsset(
        penyulang: pohon.penyulang,
        section: pohon.section,
        zonaProteksi: pohon.zonaProteksi,
        up3: pohon.up3,
        ulp: pohon.ulp,
      );
      if (matched != null) {
        final parts = [
          matched.penyulang,
          if (matched.section.isNotEmpty) 'Section ${matched.section}',
          if (matched.zonaProteksi.isNotEmpty) 'Zona ${matched.zonaProteksi}',
        ].where((e) => e.trim().isNotEmpty).join(' • ');
        return parts.isNotEmpty ? parts : 'Asset ${matched.id}';
      }
    } catch (e) {
      developer.log('Gagal resolve Aset JTM: $e', name: 'TreeMappingDetailPage');
    }
    // Fallback to the stored KMS Aset text if available, else '-'
    return pohon.kmsAset.isNotEmpty ? pohon.kmsAset : '-';
  }

  Future<String> _resolveCreatedByName(DataPohon pohon) async {
    try {
      final userId = pohon.createdBy.toString();
      final service = UserService();
      final user = await service.getUserById(userId);
      if (user != null && user.name.isNotEmpty) return user.name;
    } catch (e) {
      developer.log('Gagal resolve CreatedBy: $e', name: 'TreeMappingDetailPage');
    }
    return '-';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Tampilkan info window marker secara otomatis (seperti label pada Map Page)
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        _mapController.showMarkerInfoWindow(_markerId);
      } catch (_) {}
    });
  }

  Future<void> _openGoogleMapsApp({required double lat, required double lng, String? label}) async {
    final query = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final encodedLabel = Uri.encodeComponent(label ?? 'Lokasi');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query&query_place_id=$encodedLabel');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: try geo URI for Android
      final geo = Uri.parse('geo:$query?q=$query($encodedLabel)');
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections({required double lat, required double lng}) async {
    final query = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.map, color: Colors.black54, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Tipe Peta',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color.fromARGB(255, 41, 41, 41), width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return PopupMenuButton<MapType>(
                                        initialValue: _currentMapType,
                                        offset: const Offset(0, 56),
                                        elevation: 8,
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                          maxWidth: constraints.maxWidth,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _getMapTypeLabel(_currentMapType),
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.black54,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem<MapType>(
                                            value: MapType.normal,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                'Normal',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.satellite,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                'Satelit',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.terrain,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                'Terrain',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.hybrid,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                'Hybrid',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        onSelected: (type) {
                                          setState(() {
                                            _currentMapType = type;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            GoogleMap(
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
                          // Matikan toolbar bawaan (Android) agar kita bisa posisikan custom tombol di kiri atas
                          mapToolbarEnabled: false,
                        ),
                            // Custom toolbar di kiri atas: Directions dan buka Google Maps
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Column(
                                children: [
                                  _MapToolButton(
                                    tooltip: 'Arahkan (Google Maps)',
                                    icon: Icons.directions,
                                    onTap: () => _openDirections(
                                      lat: _initialPosition.latitude,
                                      lng: _initialPosition.longitude,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _MapToolButton(
                                    tooltip: 'Buka di Google Maps',
                                    icon: Icons.map,
                                    onTap: () => _openGoogleMapsApp(
                                      lat: _initialPosition.latitude,
                                      lng: _initialPosition.longitude,
                                      label: widget.pohon?.namaPohon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                                        // Document ID
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ID Dokumen',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.id,
                                                  style: TextStyle(fontSize: screenWidth * 0.04),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // UP3
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'UP3',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.up3.isNotEmpty ? widget.pohon!.up3 : '-',
                                                  style: TextStyle(fontSize: screenWidth * 0.04),
                                                  softWrap: true,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // ULP
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ULP',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.ulp.isNotEmpty ? widget.pohon!.ulp : '-',
                                                  style: TextStyle(fontSize: screenWidth * 0.04),
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
                                                'Vendor',
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
                                        // Koordinat (as text)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Koordinat',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.koordinat.isNotEmpty ? widget.pohon!.koordinat : '-',
                                                  style: TextStyle(fontSize: screenWidth * 0.04),
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
                                        // Aset JTM ID
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Aset JTM',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: FutureBuilder<String>(
                                                  future: _asetJtmNameFuture,
                                                  builder: (context, snapshot) {
                                                    final val = snapshot.connectionState == ConnectionState.done
                                                        ? (snapshot.data ?? '-')
                                                        : 'Memuat...';
                                                    return Text(val, style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end);
                                                  },
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
                                                child: FutureBuilder<DateTime>(
                                                  future: _latestPlannedDateFuture,
                                                  builder: (context, snapshot) {
                                                    final date = snapshot.data ?? widget.pohon!.scheduleDate;
                                                    final text = _formatDate(date);
                                                    return Text(
                                                      text,
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.04,
                                                      ),
                                                      softWrap: true,
                                                      textAlign: TextAlign.end,
                                                    );
                                                  },
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
                                                'Tujuan Penjadwalan',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  widget.pohon!.tujuanPenjadwalan == 1
                                                      ? 'Tebang Pangkas'
                                                      : widget.pohon!.tujuanPenjadwalan == 2
                                                          ? 'Tebang Habis'
                                                          : 'Tidak diketahui',
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
                                                          : 'Data tujuan tidak tersedia.',
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
                                        // Additional complete fields
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Created By', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(
                                                child: FutureBuilder<String>(
                                                  future: _createdByNameFuture,
                                                  builder: (context, snapshot) {
                                                    final val = snapshot.connectionState == ConnectionState.done
                                                        ? (snapshot.data ?? '-')
                                                        : 'Memuat...';
                                                    return Text(val, style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end);
                                                  },
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
                                              Text('Dibuat Pada', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(child: Text(_formatDateTime(widget.pohon!.createdDate) + ' WITA', style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end)),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Pertumbuhan/Tahun', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(child: Text('${widget.pohon!.growthRate} cm', style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end)),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Tinggi Awal', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(child: Text('${widget.pohon!.initialHeight} m', style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end)),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Tanggal Notifikasi', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(child: Text(_formatDate(widget.pohon!.notificationDate), style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end)),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Status', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
                                              Flexible(child: Text(widget.pohon!.status == 1 ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: screenWidth * 0.04), textAlign: TextAlign.end)),
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

class _MapToolButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String tooltip;
  const _MapToolButton({
    required this.onTap,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.black87, size: 22),
          ),
        ),
      ),
    );
  }
}