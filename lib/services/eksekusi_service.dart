import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/eksekusi.dart';

class EksekusiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
  // final String _imageKitId = dotenv.env['IMAGEKIT_ID'] ?? '';

  Future<void> addEksekusi(Eksekusi eksekusi, File? image) async {
    try {
      // Validasi apakah dataPohonId merujuk ke id yang ada di data_pohon
      final dataPohonSnapshot = await _db.collection('data_pohon').doc(eksekusi.dataPohonId).get();
      if (!dataPohonSnapshot.exists) {
        print('Error: dataPohonId ${eksekusi.dataPohonId} tidak ditemukan di koleksi data_pohon');
        throw Exception('Referensi dataPohonId tidak valid');
      }

      String? fotoUrl; // Tetap nullable
      if (image != null) {
        if (!await image.exists()) {
          print("File foto tidak ditemukan atau tidak dapat diakses: '${image.path}'");
        } else {
          var request = http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
          
          String auth = base64Encode(utf8.encode('$_privateKey:'));
          request.headers['Authorization'] = 'Basic $auth';
          
          String fileName = '${DateTime.now().millisecondsSinceEpoch}_${eksekusi.dataPohonId}_eksekusi.jpg';
          request.fields['fileName'] = fileName;
          request.fields['folder'] = '/foto_pohon_setelah_eksekusi';
          request.files.add(await http.MultipartFile.fromPath('file', image.path));

          print('Mengunggah gambar ke ImageKit: $fileName ke folder /foto_pohon_setelah_eksekusi');
          var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
          var response = await http.Response.fromStream(streamedResponse);

          print('Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');

          if (response.statusCode == 200) {
            try {
              var jsonResponse = jsonDecode(response.body);
              if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('url')) {
                fotoUrl = jsonResponse['url'] as String;
                print('Upload sukses: $fotoUrl');
              } else {
                print('Respons ImageKit tidak mengandung URL yang valid: ${response.body}');
                fotoUrl = null; // Tetap null jika gagal
              }
            } catch (jsonError) {
              print('Gagal mendekode JSON dari ImageKit: $jsonError, Response: ${response.body}');
              fotoUrl = null; // Tetap null jika gagal
            }
          } else {
            print('Upload gagal ke ImageKit: ${response.statusCode} - ${response.body}');
            fotoUrl = null; // Tetap null jika gagal
          }
        }
      } else {
        print('Tidak ada gambar yang diunggah, fotoSetelah akan null.');
        fotoUrl = null; // Jika tidak ada gambar, biarkan null
      }

      final updatedEksekusi = Eksekusi(
        id: eksekusi.id,
        dataPohonId: eksekusi.dataPohonId,
        statusEksekusi: eksekusi.statusEksekusi,
        tanggalEksekusi: eksekusi.tanggalEksekusi,
        fotoSetelah: fotoUrl, // Gunakan null jika unggah gagal atau tidak ada gambar
        createdBy: eksekusi.createdBy,
        createdDate: eksekusi.createdDate,
        status: eksekusi.status,
        tinggiPohon: eksekusi.tinggiPohon,
        diameterPohon: eksekusi.diameterPohon,
      );

      print('Menyimpan data ke Firestore dengan fotoUrl: ${fotoUrl ?? "null"}');
      final docRef = await _db.collection('eksekusi')
          .add(updatedEksekusi.toMap())
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('Data berhasil disimpan dengan ID: ${docRef.id} dan fotoUrl: ${fotoUrl ?? "null"}');
    } catch (e) {
      print('Error menyimpan data ke Firestore: $e');
      rethrow;
    }
  }

  Stream<List<Eksekusi>> getAllEksekusi() {
    return _db.collection('eksekusi').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Eksekusi.fromMap({...doc.data(), 'id': doc.id})).toList(),
    );
  }
}