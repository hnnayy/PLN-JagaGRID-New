import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/data_pohon.dart';

class DataPohonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addDataPohon(DataPohon pohon, File? fotoFile) async {
    try {
      String fotoUrl = '';
      if (fotoFile != null) {
        if (!fotoFile.existsSync()) {
          print('File foto tidak ditemukan: \'${fotoFile.path}\'');
          throw Exception('File foto tidak ditemukan di device. Pastikan memilih foto dari kamera/gallery device, bukan path PC.');
        }
        // Buat nama file unik dengan timestamp
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pohon.idPohon}.jpg';
        final ref = _storage.ref().child('foto_pohon/$fileName');
        UploadTask uploadTask = ref.putFile(fotoFile);
        TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 30));
        if (snapshot.state == TaskState.success) {
          fotoUrl = await ref.getDownloadURL();
        } else {
          throw Exception('Upload gagal: State ${snapshot.state}');
        }
      }
      final docRef = await _db.collection('data_pohon')
          .add(pohon.toMap()..update('foto_pohon', (_) => fotoUrl, ifAbsent: () => fotoUrl))
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error menyimpan data: $e');
      if (e.toString().contains('object-not-found')) {
        print('Coba periksa path Storage atau rules di Firebase Console.');
      }
      rethrow;
    }
  }

  Stream<List<DataPohon>> getAllDataPohon() {
    return _db.collection('data_pohon').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => DataPohon.fromMap({...doc.data(), 'id': doc.id})).toList(),
    );
  }
}