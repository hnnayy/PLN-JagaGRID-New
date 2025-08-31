import 'dart:io';
import 'package:flutter/material.dart';
import '../models/eksekusi.dart';
import '../services/eksekusi_service.dart';

class EksekusiProvider with ChangeNotifier {
  final EksekusiService _service = EksekusiService();
  List<Eksekusi> _eksekusiList = [];

  List<Eksekusi> get eksekusiList => _eksekusiList;

  EksekusiProvider() {
    _loadEksekusi();
  }

  Future<void> _loadEksekusi() async {
    _service.getAllEksekusi().listen((list) {
      _eksekusiList = list;
      for (var eksekusi in list) {
        print('Eksekusi ID: ${eksekusi.id}, fotoSetelah: ${eksekusi.fotoSetelah ?? "Null"}, tipe: ${eksekusi.fotoSetelah.runtimeType}');
      }
      notifyListeners();
    });
  }

  Future<void> addEksekusi(Eksekusi eksekusi, File? image) async {
    try {
      print('Memulai proses penyimpanan eksekusi dengan ID pohon: ${eksekusi.dataPohonId}...');
      await _service.addEksekusi(eksekusi, image);
      print('Proses penyimpanan selesai.');
      await _loadEksekusi(); // Muat ulang data setelah penambahan
    } catch (e) {
      print('Error adding eksekusi: $e');
      rethrow;
    }
  }
}