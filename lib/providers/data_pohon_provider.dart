import 'package:flutter/foundation.dart';
import '../models/data_pohon.dart';
import '../services/data_pohon_service.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      File? compressedFile = fotoFile;

      if (fotoFile != null) {
        final dir = await getTemporaryDirectory();
        final targetPath = path.join(
          dir.path,
          '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
        );

        final result = await FlutterImageCompress.compressAndGetFile(
          fotoFile.absolute.path,
          targetPath,
          quality: 60,
          minWidth: 800,
          minHeight: 800,
        );

        if (result != null) {
          compressedFile = File(result.path);
        }
      }

      final docId = await _service.addDataPohon(pohon, compressedFile);
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
      _pohonList.removeWhere((p) => p.id == id);
      notifyListeners();
      print('✅ Pohon $id ditandai mati di provider');
    } catch (e) {
      print('Error marking pohon as dead: $e');
      rethrow;
    }
  }
}