import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/data_pohon.dart';

class DataPohonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  Future<String> addDataPohon(DataPohon pohon, File? fotoFile) async {
    try {
      String? fotoUrl;
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

      // Use the provided scheduleDate and calculate notificationDate
      final notificationDate = pohon.scheduleDate.subtract(const Duration(days: 3));

      final dataToSave = pohon.toMap()
        ..update('foto_pohon', (_) => fotoUrl, ifAbsent: () => fotoUrl)
        ..update('growth_rate', (_) => pohon.growthRate, ifAbsent: () => 0.0)
        ..update('initial_height', (_) => pohon.initialHeight, ifAbsent: () => 0.0)
        ..update('notification_date', (_) => Timestamp.fromDate(notificationDate.subtract(const Duration(hours: 8))), ifAbsent: () => Timestamp.fromDate(notificationDate.subtract(const Duration(hours: 8))))
        ..update('status', (_) => 1); // Set status aktif saat menambah data

      final docRef = await _db.collection('data_pohon').add(dataToSave).timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('Data berhasil disimpan dengan ID: ${docRef.id} dan fotoUrl: ${fotoUrl ?? "null"}');
      return docRef.id; // Return document ID
    } catch (e) {
      print('Error menyimpan data: $e');
      rethrow;
    }
  }

  Stream<List<DataPohon>> getAllDataPohon() {
    return _db.collection('data_pohon')
        .where('status', isEqualTo: 1) // Hanya ambil data dengan status aktif
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            // Pass the entire document data to fromMap, including the document ID
            return DataPohon.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
          }).toList(),
        );
  }

  Future<void> deleteDataPohon(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Document ID cannot be empty');
    }
    try {
      final docSnapshot = await _db.collection('data_pohon').doc(id).get();
      if (!docSnapshot.exists) {
        throw Exception('Dokumen dengan ID $id tidak ditemukan');
      }
      await _db.collection('data_pohon').doc(id).update({
        'status': 0, // Soft delete: set status ke 0
      }).timeout(const Duration(seconds: 30));
      print('Data pohon dengan ID: $id berhasil di-soft delete');
    } catch (e) {
      print('Error menghapus data pohon: $e');
      rethrow;
    }
  }
}