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

  Future<String> addPohon(DataPohon pohon, File? fotoFile) async {
    try {
      final docId = await _service.addDataPohon(pohon, fotoFile);
      notifyListeners();
      return docId; // Return document ID
    } catch (e) {
      print('Error adding pohon: $e');
      rethrow;
    }
  }
}