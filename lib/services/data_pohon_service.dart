// data_pohon_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/data_pohon.dart';

class DataPohonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  static const String _privateKey = 'private_RsgXuz88cqDhNzGadpKJUbvU/qg=';  // Ganti dengan Private Key asli Anda (sementara untuk test)
  static const String _imageKitId = 'jdshnz8lhf';  // Ganti dengan ImageKit ID asli Anda (sementara untuk test)

  Future<void> addDataPohon(DataPohon pohon, File? fotoFile) async {
    try {
      String fotoUrl = '';
      if (fotoFile != null) {
        if (!fotoFile.existsSync()) {
          print("File foto tidak ditemukan: '${fotoFile.path}'");
        } else {
          var request = http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
          
          String auth = base64Encode(utf8.encode('$_privateKey:'));
          request.headers['Authorization'] = 'Basic $auth';
          
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pohon.idPohon}.jpg';
          request.fields['fileName'] = fileName;
          request.files.add(await http.MultipartFile.fromPath('file', fotoFile.path));

          var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            var jsonResponse = jsonDecode(response.body);
            fotoUrl = jsonResponse['url'];
            print('Upload sukses: $fotoUrl');
          } else {
            throw Exception('Upload gagal: ${response.statusCode} - ${response.body}');
          }
        }
      }

      final docRef = await _db.collection('data_pohon')
          .add(pohon.toMap()..update('foto_pohon', (_) => fotoUrl, ifAbsent: () => fotoUrl))
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error menyimpan data: $e');
      rethrow;
    }
  }

  Stream<List<DataPohon>> getAllDataPohon() {
    return _db.collection('data_pohon').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => DataPohon.fromMap({...doc.data(), 'id': doc.id})).toList(),
    );
  }
}