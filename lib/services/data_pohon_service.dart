import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/data_pohon.dart';

class DataPohonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  static const String _privateKey = 'private_RsgXuz88cqDhNzGadpKJUbvU/qg=';  // Ganti dengan Private Key asli
  static const String _imageKitId = 'jdshnz8lhf';  // Ganti dengan ImageKit ID asli

  Future<void> addDataPohon(DataPohon pohon, File? fotoFile) async {
    try {
      String? fotoUrl; // Ubah ke nullable
      if (fotoFile != null) {
        if (!fotoFile.existsSync()) {
          print("File foto tidak ditemukan: '${fotoFile.path}'");
        } else {
          var request = http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
          String auth = base64Encode(utf8.encode('$_privateKey:'));
          request.headers['Authorization'] = 'Basic $auth';
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pohon.idPohon}.jpg';
          request.fields['fileName'] = fileName;
          request.fields['folder'] = '/foto_pohon';
          request.files.add(await http.MultipartFile.fromPath('file', fotoFile.path));

          var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            var jsonResponse = jsonDecode(response.body);
            if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('url')) {
              fotoUrl = jsonResponse['url'] as String;
              print('Upload sukses: $fotoUrl');
            } else {
              print('Respons ImageKit tidak mengandung URL yang valid: ${response.body}');
            }
          } else {
            print('Upload gagal ke ImageKit: ${response.statusCode} - ${response.body}');
          }
        }
      } else {
        print('Tidak ada gambar yang diunggah, fotoUrl akan null.');
      }

      final dataToSave = pohon.toMap()..update('foto_pohon', (_) => fotoUrl, ifAbsent: () => fotoUrl);
      final docRef = await _db.collection('data_pohon').add(dataToSave).timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('Data berhasil disimpan dengan ID: ${docRef.id} dan fotoUrl: ${fotoUrl ?? "null"}');
    } catch (e) {
      print('Error menyimpan data: $e');
      rethrow;
    }
  }

  Stream<List<DataPohon>> getAllDataPohon() {
    return _db.collection('data_pohon').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        // Pastikan semua nilai dikonversi dengan aman sebelum masuk ke DataPohon.fromMap
        return DataPohon.fromMap({
          'id': doc.id,
          'id_pohon': data['id_pohon'] as String? ?? '',
          'up3': data['up3'] as String? ?? '',
          'ulp': data['ulp'] as String? ?? '',
          'penyulang': data['penyulang'] as String? ?? '',
          'zona_proteksi': data['zona_proteksi'] as String? ?? '',
          'section': data['section'] as String? ?? '',
          'kms_aset': data['kms_aset'] as String? ?? '',
          'vendor': data['vendor'] as String? ?? '',
          'parent_id': (data['parent_id'] as int?) ?? 0,
          'unit_id': (data['unit_id'] as int?) ?? 0,
          'aset_jtm_id': (data['aset_jtm_id'] as int?) ?? 0,
          'schedule_date': (data['schedule_date'] as String?) ?? DateTime.now().toIso8601String(),
          'prioritas': (data['prioritas'] as int?) ?? 1,
          'nama_pohon': data['nama_pohon'] as String? ?? '',
          'foto_pohon': data['foto_pohon'] as String? ?? '',
          'koordinat': data['koordinat'] as String? ?? '',
          'tujuan_penjadwalan': (data['tujuan_penjadwalan'] as int?) ?? 1,
          'catatan': data['catatan'] as String? ?? '',
          'createdby': (data['createdby'] as int?) ?? 0,
          'createddate': (data['createddate'] as String?) ?? DateTime.now().toIso8601String(),
        });
      }).toList(),
    );
  }
}