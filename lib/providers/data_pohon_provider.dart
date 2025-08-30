// data_pohon_provider.dart
import 'package:flutter/foundation.dart';
import '../models/data_pohon.dart';
import '../services/data_pohon_service.dart';
import 'dart:io';

class DataPohonProvider with ChangeNotifier {
  final DataPohonService _service = DataPohonService();
  List<DataPohon> _pohonList = [];

  List<DataPohon> get pohonList => _pohonList;

  DataPohonProvider() {
    _service.getAllDataPohon().listen((list) {
      _pohonList = list;
      notifyListeners();
    });
  }

  Future<void> addPohon(DataPohon pohon, File? fotoFile) async {
    try {
      await _service.addDataPohon(pohon, fotoFile);
      notifyListeners();
    } catch (e) {
      print('Error adding pohon: $e');
      rethrow;
    }
  }
}