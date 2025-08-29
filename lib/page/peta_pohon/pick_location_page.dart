import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/colors.dart';
import 'package:provider/provider.dart';
import '../../providers/data_pohon_provider.dart';

class PickLocationPage extends StatefulWidget {
  @override
  _PickLocationPageState createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  MapType _currentMapType = MapType.satellite;
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    // Ambil pohon terakhir dari provider
    LatLng defaultPosition = const LatLng(-4.0167, 120.1833); // Pare default
    final pohonList = Provider.of<DataPohonProvider>(context, listen: false).pohonList;
    if (pohonList.isNotEmpty) {
      final last = pohonList.last;
      final coords = last.koordinat.split(',');
      if (coords.length == 2) {
        double? lat = double.tryParse(coords[0]);
        double? lng = double.tryParse(coords[1]);
        if (lat != null && lng != null) {
          defaultPosition = LatLng(lat, lng);
        }
      }
    }
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
                child: Center(
                  child: Text(
                    'Pilih Lokasi Pohon',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.yellow,
                    ),
                  ),
                ),
              ),
              // Dropdown pilihan tipe peta
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    const Text('Tipe Peta:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.white,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      child: DropdownButton<MapType>(
                        value: _currentMapType,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(child: Text('Normal', style: TextStyle(color: Colors.black)), value: MapType.normal),
                          DropdownMenuItem(child: Text('Satelit', style: TextStyle(color: Colors.black)), value: MapType.satellite),
                          DropdownMenuItem(child: Text('Terrain', style: TextStyle(color: Colors.black)), value: MapType.terrain),
                          DropdownMenuItem(child: Text('Hybrid', style: TextStyle(color: Colors.black)), value: MapType.hybrid),
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
              // Map Fullscreen
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: defaultPosition,
                        zoom: 20.0, // zoom maksimal
                      ),
                      mapType: _currentMapType,
                      minMaxZoomPreference: const MinMaxZoomPreference(15.0, 21.0),
                      onTap: (pos) {
                        setState(() {
                          _selectedPosition = pos;
                        });
                      },
                      markers: _selectedPosition == null
                          ? {}
                          : {
                              Marker(
                                markerId: MarkerId('selected'),
                                position: _selectedPosition!,
                              ),
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.yellow,
          onPressed: () {
            if (_selectedPosition != null) {
              Navigator.pop(context, '${_selectedPosition!.latitude},${_selectedPosition!.longitude}');
            }
          },
          child: const Icon(Icons.check, color: Colors.black),
        ),
      );
  }
}