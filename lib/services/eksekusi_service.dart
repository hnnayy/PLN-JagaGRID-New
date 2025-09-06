import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../models/eksekusi.dart';

class EksekusiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  Future<void> addEksekusi(Eksekusi eksekusi, File image) async {
    try {
      // Validate statusEksekusi before proceeding
      if (eksekusi.statusEksekusi != 1 && eksekusi.statusEksekusi != 2) {
        print('Error: Invalid statusEksekusi value: ${eksekusi.statusEksekusi}. Must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
        throw ArgumentError('statusEksekusi must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
      }

      // Validate that dataPohonId corresponds to an existing DataPohon document ID
      final dataPohonSnapshot = await _db.collection('data_pohon').doc(eksekusi.dataPohonId).get();
      if (!dataPohonSnapshot.exists) {
        print('Error: dataPohonId ${eksekusi.dataPohonId} does not exist in data_pohon collection');
        throw Exception('Invalid dataPohonId: No matching DataPohon document found');
      }

      // Require image for both Tebang Pangkas and Tebang Habis
      if (!await image.exists()) {
        print("Error: Image file does not exist or is inaccessible: '${image.path}'");
        throw Exception('Image file not found');
      }

      var request = http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));

      // Authenticate with ImageKit using private key
      String auth = base64Encode(utf8.encode('$_privateKey:'));
      request.headers['Authorization'] = 'Basic $auth';

      // Generate a unique filename using dataPohonId and timestamp
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${eksekusi.dataPohonId}_eksekusi.jpg';
      request.fields['fileName'] = fileName;
      request.fields['folder'] = '/foto_pohon_setelah_eksekusi';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      print('Uploading image to ImageKit: $fileName to folder /foto_pohon_setelah_eksekusi');
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      print('ImageKit Response - Status Code: ${response.statusCode}, Body: ${response.body}');

      String? fotoUrl;
      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('url')) {
            fotoUrl = jsonResponse['url'] as String;
            print('Image upload successful: $fotoUrl');
          } else {
            print('Error: ImageKit response does not contain a valid URL: ${response.body}');
            throw Exception('ImageKit response does not contain a valid URL');
          }
        } catch (jsonError) {
          print('Error decoding ImageKit JSON response: $jsonError, Response: ${response.body}');
          throw Exception('Failed to decode ImageKit response');
        }
      } else {
        print('Image upload failed: ${response.statusCode} - ${response.body}');
        throw Exception('Image upload failed: ${response.statusCode}');
      }

      // Create updated Eksekusi object with the uploaded image URL and formatted tanggalEksekusi
      final nowWita = DateTime.now().toUtc().add(const Duration(hours: 8)); // Convert to WITA (UTC+8)
      final formattedTanggalEksekusi = DateFormat('dd/MM/yyyy HH:mm').format(nowWita) + ' WITA';

      final updatedEksekusi = Eksekusi(
        id: eksekusi.id,
        dataPohonId: eksekusi.dataPohonId,
        statusEksekusi: eksekusi.statusEksekusi,
        tanggalEksekusi: formattedTanggalEksekusi, // Store as string
        fotoSetelah: fotoUrl,
        createdBy: eksekusi.createdBy,
        createdDate: eksekusi.createdDate,
        status: eksekusi.status,
        tinggiPohon: eksekusi.tinggiPohon,
        diameterPohon: eksekusi.diameterPohon,
      );

      print('Saving Eksekusi to Firestore with dataPohonId: ${eksekusi.dataPohonId}, statusEksekusi: ${eksekusi.statusEksekusi}, tanggalEksekusi: ${updatedEksekusi.tanggalEksekusi}, fotoUrl: $fotoUrl');
      final docRef = await _db.collection('eksekusi')
          .add(updatedEksekusi.toMap())
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('Eksekusi saved successfully with ID: ${docRef.id}, dataPohonId: ${eksekusi.dataPohonId}, statusEksekusi: ${eksekusi.statusEksekusi}, tanggalEksekusi: ${updatedEksekusi.tanggalEksekusi}, fotoUrl: $fotoUrl');
    } catch (e) {
      print('Error saving Eksekusi to Firestore: $e');
      rethrow;
    }
  }

  Stream<List<Eksekusi>> getAllEksekusi() {
    return _db.collection('eksekusi').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Eksekusi.fromMap({...doc.data(), 'id': doc.id})).toList(),
    );
  }
}