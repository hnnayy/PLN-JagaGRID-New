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
      return docId;
    } catch (e) {
      print('Error adding pohon: $e');
      rethrow;
    }
  }

  /// Tandai pohon mati sendiri (bukan eksekusi) — dipanggil dari TreeMappingDetailPage
  /// Pohon tidak muncul lagi di list, prediksi aktif dinonaktifkan
  Future<void> markAsDead(String id, {String catatan = ''}) async {
    try {
      await _service.markAsDead(id, catatan: catatan);
      // Hapus dari list lokal langsung tanpa tunggu stream
      _pohonList.removeWhere((p) => p.id == id);
      notifyListeners();
      print('✅ Pohon $id ditandai mati di provider');
    } catch (e) {
      print('Error marking pohon as dead: $e');
      rethrow;
    }
  }
}