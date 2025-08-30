import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/eksekusi.dart';

class EksekusiService {
  static const String _baseUrl = 'https://your-api-endpoint'; // Ganti dengan URL API Anda

  Future<String> uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path, filename: path.basename(image.path)),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return responseData; // Asumsi API mengembalikan URL gambar
      } else {
        throw Exception('Gagal mengunggah gambar: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> addEksekusi(Eksekusi eksekusi) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/eksekusi'),
        headers: {'Content-Type': 'application/json'},
        body: eksekusi.toMap(),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal menyimpan data eksekusi: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving eksekusi: $e');
    }
  }
}