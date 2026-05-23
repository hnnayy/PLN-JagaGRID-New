import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/data_pohon.dart';
import '../../constants/colors.dart';
import '../../providers/data_pohon_provider.dart';
import 'eksekusi.dart';
import 'riwayat_eksekusi.dart';
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
    if (widget.pohon != null && widget.pohon!.koordinat.isNotEmpty) {
      _initialPosition = _parseLatLngFromString(widget.pohon!.koordinat);
    } else {
      developer.log('Koordinat kosong atau pohon null',
          name: 'TreeMappingDetailPage');
      _initialPosition = const LatLng(-4.0167, 120.1833);
    }

    _markerId = MarkerId('tree_${widget.pohon?.idPohon ?? "unknown"}');

    final tujuan = widget.pohon?.tujuanPenjadwalan;
    final tujuanText = tujuan == 1
        ? 'Tebang Pangkas'
        : tujuan == 2
            ? 'Tebang Habis'
            : '-';

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
          title: widget.pohon?.namaPohon ?? 'Pohon',
          snippet: tujuanText,
        ),
        icon: icon,
      ),
    );

    if (widget.pohon != null) {
      developer.log(
          'tujuanPenjadwalan dari DataPohon: ${widget.pohon!.tujuanPenjadwalan}',
          name: 'TreeMappingDetailPage');
      _asetJtmNameFuture = _resolveAsetJtmName(widget.pohon!);
      _createdByNameFuture = _resolveCreatedByName(widget.pohon!);
      _latestPlannedDateFuture = _resolveLatestPlannedDate(widget.pohon!);
    }
  }

  // ─────────────────────────────────────────────
  // Fullscreen image viewer
  // ─────────────────────────────────────────────
  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Foto fullscreen + bisa zoom/pan
            InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),

            // Tombol silang tutup
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  LatLng _parseLatLngFromString(String input) {
    try {
      final numberMatches =
          RegExp(r'-?\d+(?:\.\d+)?').allMatches(input).toList();
      if (numberMatches.length < 2) {
        return const LatLng(-4.0167, 120.1833);
      }
      final a = double.parse(numberMatches[0].group(0)!);
      final b = double.parse(numberMatches[1].group(0)!);

      double lat = a;
      double lng = b;
      bool aLooksLon = a.abs() > 90 && a.abs() <= 180;
      bool bLooksLat = b.abs() <= 90;
      if (aLooksLon && bLooksLat) {
        lat = b;
        lng = a;
      }

      if (lat.abs() > 90 || lng.abs() > 180) {
        return const LatLng(-4.0167, 120.1833);
      }
      return LatLng(lat, lng);
    } catch (e) {
      return const LatLng(-4.0167, 120.1833);
    }
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _formatDateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm').format(d);

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
      return preds.first.predictedNextExecution;
    } catch (_) {
      return pohon.scheduleDate;
    }
  }

  Future<String> _resolveAsetJtmName(DataPohon pohon) async {
    try {
      final id = pohon.asetJtmId.toString();
      final service = AssetService();
      final asset = await service.getAssetById(id);
      if (asset != null) {
        final parts = [
          asset.penyulang,
          if (asset.section.isNotEmpty) 'Section ${asset.section}',
          if (asset.zonaProteksi.isNotEmpty) 'Zona ${asset.zonaProteksi}',
        ].where((e) => e.trim().isNotEmpty).join(' • ');
        return parts.isNotEmpty ? parts : 'Asset ${asset.id}';
      }
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
      developer.log('Gagal resolve Aset JTM: $e',
          name: 'TreeMappingDetailPage');
    }
    return pohon.kmsAset.isNotEmpty ? pohon.kmsAset : '-';
  }

  Future<String> _resolveCreatedByName(DataPohon pohon) async {
    try {
      final userId = pohon.createdBy.toString();
      final service = UserService();
      final user = await service.getUserById(userId);
      if (user != null && user.name.isNotEmpty) return user.name;
    } catch (e) {
      developer.log('Gagal resolve CreatedBy: $e',
          name: 'TreeMappingDetailPage');
    }
    return '-';
  }

  // ─── FITUR POHON MATI ────────────────────────────────────────────────────

  Future<void> _showPohonMatiDialog() async {
    final catatanController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Tandai Pohon Mati'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tandai pohon #${widget.pohon!.idPohon} sebagai mati sendiri?'),
            const SizedBox(height: 8),
            Text(
              'Pohon tidak akan muncul lagi di sistem dan semua prediksi akan dinonaktifkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                labelText: 'Penyebab kematian (opsional)',
                hintText: 'Contoh: hama, kekeringan, penyakit, dll',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Pohon Mati'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await context.read<DataPohonProvider>().markAsDead(
            widget.pohon!.id,
            catatan: catatanController.text.trim(),
          );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF125E72),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Berhasil!',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pohon berhasil ditandai mati',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF125E72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menandai pohon mati: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        _mapController.showMarkerInfoWindow(_markerId);
      } catch (_) {}
    });
  }

  Future<void> _openGoogleMapsApp(
      {required double lat,
      required double lng,
      String? label}) async {
    final query = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final encodedLabel = Uri.encodeComponent(label ?? 'Lokasi');
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=$encodedLabel');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final geo = Uri.parse('geo:$query?q=$query($encodedLabel)');
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections(
      {required double lat, required double lng}) async {
    final query = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // URL foto pohon
    final fotoUrl = widget.pohon != null &&
            widget.pohon!.fotoPohon.isNotEmpty
        ? widget.pohon!.fotoPohon
        : 'https://via.placeholder.com/150?text=Foto+Pohon';

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
          child: Text(
            'Pohon ID #${widget.pohon?.idPohon ?? "unknown"}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: widget.pohon == null
          ? const Center(child: Text('Data pohon tidak tersedia'))
          : SafeArea(
              child: Stack(
                children: [
                  // ── Map Section ──
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.map,
                                  color: Colors.black54, size: 20),
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
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 41, 41, 41),
                                        width: 1),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        color: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _getMapTypeLabel(
                                                    _currentMapType),
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
                                              child: const Text('Normal',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14)),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.satellite,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: const Text('Satelit',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14)),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.terrain,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: const Text('Terrain',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14)),
                                            ),
                                          ),
                                          PopupMenuItem<MapType>(
                                            value: MapType.hybrid,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: const Text('Hybrid',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14)),
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
                              minMaxZoomPreference:
                                  const MinMaxZoomPreference(10.0, 20.0),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapToolbarEnabled: false,
                            ),
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

                  // ── Draggable Sheet ──
                  DraggableScrollableSheet(
                    initialChildSize: 0.1,
                    minChildSize: 0.1,
                    maxChildSize: 0.9,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20)),
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
                                padding: EdgeInsets.zero,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: [
                                  // ── Handle bar ──
                                  Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      width: screenWidth * 0.15,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),

                                  // ── Judul ──
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 8),
                                    child: Text(
                                      'Pohon ID #${widget.pohon!.idPohon}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ── FOTO POHON (tap = fullscreen) ──
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: GestureDetector(
                                        onTap: () => _showFullscreenImage(
                                            context, fotoUrl),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: fotoUrl,
                                                width: screenWidth * 0.7,
                                                height: screenHeight * 0.25,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  width: screenWidth * 0.7,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  width: screenWidth * 0.7,
                                                  height: screenHeight * 0.25,
                                                  color: Colors.grey,
                                                  child: const Center(
                                                      child: Text(
                                                          'Gambar Tidak Tersedia')),
                                                ),
                                              ),
                                            ),

                                            // ── Icon zoom di pojok kanan bawah foto ──
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.zoom_in,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ── Hint ketuk ──
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app,
                                          size: 12, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ketuk foto untuk memperbesar',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),

                                  // ── Prioritas badge ──
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: widget.pohon!.prioritas == 1
                                              ? Colors.green
                                              : widget.pohon!.prioritas == 2
                                                  ? const Color(0xFFFFD700)
                                                  : Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Prioritas: ${widget.pohon!.prioritas == 1 ? "Rendah" : widget.pohon!.prioritas == 2 ? "Sedang" : "Tinggi"}',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ── Info rows ──
                                  _infoRow(
                                      'ID Pohon',
                                      widget.pohon!.idPohon.isNotEmpty
                                          ? widget.pohon!.idPohon
                                          : 'P023',
                                      screenWidth),
                                  _infoRow('ID Dokumen', widget.pohon!.id,
                                      screenWidth),
                                  _infoRow(
                                      'UP3',
                                      widget.pohon!.up3.isNotEmpty
                                          ? widget.pohon!.up3
                                          : '-',
                                      screenWidth),
                                  _infoRow(
                                      'ULP',
                                      widget.pohon!.ulp.isNotEmpty
                                          ? widget.pohon!.ulp
                                          : '-',
                                      screenWidth),
                                  _infoRow(
                                      'Vendor',
                                      widget.pohon!.vendor.isNotEmpty
                                          ? widget.pohon!.vendor
                                          : 'PT PLN PERAMBAS',
                                      screenWidth),
                                  _infoRow(
                                      'Nama Pohon',
                                      widget.pohon!.namaPohon.isNotEmpty
                                          ? widget.pohon!.namaPohon
                                          : 'Tidak tersedia',
                                      screenWidth),
                                  _infoRow(
                                      'Koordinat',
                                      widget.pohon!.koordinat.isNotEmpty
                                          ? widget.pohon!.koordinat
                                          : '-',
                                      screenWidth),
                                  _infoRow(
                                      'Penyulang',
                                      widget.pohon!.penyulang.isNotEmpty
                                          ? widget.pohon!.penyulang
                                          : 'Tidak tersedia',
                                      screenWidth),
                                  _infoRow(
                                      'Zona Proteksi',
                                      widget.pohon!.zonaProteksi.isNotEmpty
                                          ? widget.pohon!.zonaProteksi
                                          : 'Tidak tersedia',
                                      screenWidth),
                                  _infoRow(
                                      'Section',
                                      widget.pohon!.section.isNotEmpty
                                          ? widget.pohon!.section
                                          : 'Tidak tersedia',
                                      screenWidth),
                                  _infoRow(
                                      'KMS Aset',
                                      widget.pohon!.kmsAset.isNotEmpty
                                          ? widget.pohon!.kmsAset
                                          : 'Tidak tersedia',
                                      screenWidth),

                                  // ── Aset JTM (async) ──
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Aset JTM',
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.bold)),
                                        Flexible(
                                          child: FutureBuilder<String>(
                                            future: _asetJtmNameFuture,
                                            builder: (context, snapshot) {
                                              final val = snapshot
                                                          .connectionState ==
                                                      ConnectionState.done
                                                  ? (snapshot.data ?? '-')
                                                  : 'Memuat...';
                                              return Text(val,
                                                  style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.04),
                                                  textAlign: TextAlign.end);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Tanggal penjadwalan (async) ──
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Tanggal Penjadwalan',
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.bold)),
                                        Flexible(
                                          child: FutureBuilder<DateTime>(
                                            future: _latestPlannedDateFuture,
                                            builder: (context, snapshot) {
                                              final date = snapshot.data ??
                                                  widget.pohon!.scheduleDate;
                                              return Text(
                                                _formatDate(date),
                                                style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04),
                                                textAlign: TextAlign.end,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  _infoRow(
                                      'Tujuan Penjadwalan',
                                      widget.pohon!.tujuanPenjadwalan == 1
                                          ? 'Tebang Pangkas'
                                          : widget.pohon!.tujuanPenjadwalan ==
                                                  2
                                              ? 'Tebang Habis'
                                              : 'Tidak diketahui',
                                      screenWidth),
                                  _infoRow(
                                      'Deskripsi',
                                      widget.pohon!.tujuanPenjadwalan == 1
                                          ? 'Pohon akan dipangkas.'
                                          : widget.pohon!.tujuanPenjadwalan ==
                                                  2
                                              ? 'Pohon akan ditebang.'
                                              : 'Data tujuan tidak tersedia.',
                                      screenWidth),
                                  _infoRow(
                                      'Catatan Tambahan',
                                      widget.pohon!.catatan.isNotEmpty
                                          ? widget.pohon!.catatan
                                          : 'Perlu perhatian khusus untuk pemeliharaan.',
                                      screenWidth),

                                  // ── Created by (async) ──
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Created By',
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.bold)),
                                        Flexible(
                                          child: FutureBuilder<String>(
                                            future: _createdByNameFuture,
                                            builder: (context, snapshot) {
                                              final val = snapshot
                                                          .connectionState ==
                                                      ConnectionState.done
                                                  ? (snapshot.data ?? '-')
                                                  : 'Memuat...';
                                              return Text(val,
                                                  style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.04),
                                                  textAlign: TextAlign.end);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  _infoRow(
                                      'Dibuat Pada',
                                      '${_formatDateTime(widget.pohon!.createdDate)} WITA',
                                      screenWidth),
                                  _infoRow(
                                      'Pertumbuhan/Tahun',
                                      '${widget.pohon!.growthRate} cm',
                                      screenWidth),
                                  _infoRow(
                                      'Tinggi Awal',
                                      '${widget.pohon!.initialHeight} m',
                                      screenWidth),
                                  _infoRow(
                                      'Tanggal Notifikasi',
                                      _formatDate(
                                          widget.pohon!.notificationDate),
                                      screenWidth),
                                  _infoRow(
                                      'Status',
                                      widget.pohon!.status == 1
                                          ? 'Aktif'
                                          : widget.pohon!.status == 2
                                              ? 'Mati'
                                              : 'Nonaktif',
                                      screenWidth),

                                  // ── Action Buttons ──
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        // Tombol Eksekusi
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      EksekusiPage(
                                                          pohon:
                                                              widget.pohon!)),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0B5F6D),
                                            minimumSize: Size(screenWidth * 0.9,
                                                screenHeight * 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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

                                        // Tombol Lihat Riwayat Eksekusi
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      RiwayatEksekusiPage(
                                                          pohon:
                                                              widget.pohon!)),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0B5F6D),
                                            minimumSize: Size(screenWidth * 0.9,
                                                screenHeight * 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        const SizedBox(height: 10),

                                        // Tombol Tandai Pohon Mati
                                        ElevatedButton(
                                          onPressed: () =>
                                              _showPohonMatiDialog(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade700,
                                            minimumSize: Size(screenWidth * 0.9,
                                                screenHeight * 0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            '🌿 Tandai Pohon Mati',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
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

  Widget _infoRow(String label, String value, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.04),
              softWrap: true,
              textAlign: TextAlign.end,
            ),
          ),
        ],
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