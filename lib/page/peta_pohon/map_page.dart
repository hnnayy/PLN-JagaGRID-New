// map_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/data_pohon_provider.dart';
import '../../models/data_pohon.dart';
import '../../constants/colors.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DataPohon> _searchResults = [];
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(-4.0167, 120.1833); // Pare, Sulawesi

  MapType _currentMapType = MapType.satellite;

  // Map<int, BitmapDescriptor> _priorityIcons = {}; // dihapus, tidak dipakai

  @override
  void initState() {
    super.initState();
  // _loadMarkerIcons(); // dihapus, tidak dipakai
  }

  // Hapus _loadMarkerIcons, tidak perlu custom asset marker

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {}); // Pastikan update setelah map created
  }

  void _focusToMarker(LatLng pos) {
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 20.0));
  }

  void _addMarker(LatLng pos) {
    // Biar cuma tambah marker dari AddDataPage, kosongin dulu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tealGelap,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18, left: 0, right: 0, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.tealGelap,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Peta Pohon',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/addData');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Container
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari pohon (nama/id/prioritas)',
                          hintStyle: const TextStyle(color: Colors.black54, fontFamily: 'Poppins', fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        ),
                        onChanged: (query) {
                          final provider = Provider.of<DataPohonProvider>(context, listen: false);
                          setState(() {
                            final q = query.toLowerCase();
                            _searchResults = provider.pohonList.where((pohon) {
                              final nama = pohon.namaPohon.toLowerCase();
                              final id = pohon.idPohon.toLowerCase();
                              final prioritasStr = pohon.prioritas.toString();
                              String prioritasLabel = '';
                              if (pohon.prioritas == 1) prioritasLabel = 'rendah';
                              else if (pohon.prioritas == 2) prioritasLabel = 'sedang';
                              else if (pohon.prioritas == 3) prioritasLabel = 'tinggi';
                              return nama.contains(q) || id.contains(q) || prioritasStr == q || prioritasLabel.contains(q);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (ctx, idx) {
                            final pohon = _searchResults[idx];
                            String prioritasLabel = '-';
                            if (pohon.prioritas == 1) prioritasLabel = 'Rendah';
                            else if (pohon.prioritas == 2) prioritasLabel = 'Sedang';
                            else if (pohon.prioritas == 3) prioritasLabel = 'Tinggi';
                            return ListTile(
                              title: Text(pohon.namaPohon, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('ID: ${pohon.idPohon}  |  Prioritas: $prioritasLabel', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                              onTap: () {
                                _searchController.clear();
                                setState(() { _searchResults.clear(); });
                                final coords = pohon.koordinat.split(',');
                                if (coords.length == 2) {
                                  double? lat = double.tryParse(coords[0]);
                                  double? lng = double.tryParse(coords[1]);
                                  if (lat != null && lng != null) {
                                    _focusToMarker(LatLng(lat, lng));
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Tipe Peta Container
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                ),
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.black54, size: 20),
                    const SizedBox(width: 8),
                    const Text('Tipe Peta:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                    const SizedBox(width: 12),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.white,
                        iconTheme: const IconThemeData(color: Colors.black),
                      ),
                      child: DropdownButton<MapType>(
                        value: _currentMapType,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(child: Text('Normal', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 14)), value: MapType.normal),
                          DropdownMenuItem(child: Text('Satelit', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 14)), value: MapType.satellite),
                          DropdownMenuItem(child: Text('Terrain', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 14)), value: MapType.terrain),
                          DropdownMenuItem(child: Text('Hybrid', style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 14)), value: MapType.hybrid),
                        ],
                        onChanged: (type) {
                          setState(() {
                            _currentMapType = type!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Map Fullscreen
            Expanded(
              child: Padding(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: Consumer<DataPohonProvider>(
                    builder: (ctx, provider, _) {
                      Set<Marker> markers = {};
                      for (var pohon in provider.pohonList) {
                        print('DEBUG pohon: id=${pohon.id}, koordinat=${pohon.koordinat}, nama=${pohon.namaPohon}');
                        if (pohon.koordinat.isEmpty || !pohon.koordinat.contains(',')) {
                          print('SKIP pohon id=${pohon.id} karena koordinat kosong/salah format');
                          continue;
                        }
                        List<String> coords = pohon.koordinat.split(',');
                        if (coords.length != 2) {
                          print('SKIP pohon id=${pohon.id} karena koordinat tidak dua angka');
                          continue;
                        }
                        double? lat = double.tryParse(coords[0]);
                        double? lng = double.tryParse(coords[1]);
                        if (lat == null || lng == null) {
                          print('SKIP pohon id=${pohon.id} karena gagal parsing koordinat');
                          continue;
                        }
                        BitmapDescriptor icon;
                        if (pohon.prioritas == 1) {
                          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
                        } else if (pohon.prioritas == 2) {
                          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
                        } else if (pohon.prioritas == 3) {
                          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
                        } else {
                          icon = BitmapDescriptor.defaultMarker;
                        }
                        markers.add(Marker(
                          markerId: MarkerId(pohon.id),
                          position: LatLng(lat, lng),
                          infoWindow: InfoWindow(
                            title: pohon.namaPohon,
                            snippet: pohon.tujuanPenjadwalan == 1
                                ? 'Tebang Pangkas'
                                : pohon.tujuanPenjadwalan == 2
                                    ? 'Tebang Habis'
                                    : '-',
                          ),
                          icon: icon,
                        ));
                      }
                      print('DEBUG total marker: ${markers.length}');

                      return GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition,
                          zoom: 17.0,
                        ),
                        mapType: _currentMapType,
                        minMaxZoomPreference: const MinMaxZoomPreference(15.0, 21.0),
                        markers: markers,
                        onTap: _addMarker,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}