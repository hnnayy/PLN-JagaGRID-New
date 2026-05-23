import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathLib;

import '../models/data_pohon.dart';

class DataPohonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';
  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  Future<String> addDataPohon(DataPohon pohon, File? fotoFile) async {
    try {
      String? fotoUrl;

      if (fotoFile != null) {
        if (!fotoFile.existsSync()) {
          print("File foto tidak ditemukan: '${fotoFile.path}'");
        } else {
          // ── KOMPRES GAMBAR ──
          File compressedImage = fotoFile;
          try {
            if (await fotoFile.length() > 1000000) {
              final dir = await getTemporaryDirectory();
              final targetPath = pathLib.join(
                dir.path,
                '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
              );

              final result =
                  await FlutterImageCompress.compressAndGetFile(
                fotoFile.absolute.path,
                targetPath,
                quality: 60,
                minWidth: 800,
                minHeight: 800,
                format: CompressFormat.jpeg,
              );

              if (result != null) {
                compressedImage = File(result.path);
                print(
                    '📉 Image compressed: ${await compressedImage.length()} bytes');
              }
            }
          } catch (e) {
            print('⚠️ Gagal kompres foto: $e');
          }

          // ── UPLOAD KE IMAGEKIT ──
          var request =
              http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
          String auth = base64Encode(utf8.encode('$_privateKey:'));
          request.headers['Authorization'] = 'Basic $auth';

          String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${pohon.idPohon}.jpg';

          request.fields['fileName'] = fileName;
          request.fields['folder'] = '/foto_pohon';

          request.files.add(await http.MultipartFile.fromPath(
              'file', compressedImage.path));

          var streamedResponse =
              await request.send().timeout(const Duration(seconds: 30));
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            var jsonResponse = jsonDecode(response.body);
            if (jsonResponse is Map<String, dynamic> &&
                jsonResponse.containsKey('url')) {
              fotoUrl = jsonResponse['url'] as String;
              print('✅ Upload sukses: $fotoUrl');
            } else {
              print(
                  '⚠️ Respons ImageKit tidak valid: ${response.body}');
            }
          } else {
            print(
                '❌ Upload gagal: ${response.statusCode} - ${response.body}');
          }
        }
      } else {
        print('ℹ️ Tidak ada gambar diupload');
      }

      // ── HITUNG NOTIF H-3 ──
      final notificationDate =
          pohon.scheduleDate.subtract(const Duration(days: 3));

      final dataToSave = pohon.toMap()
        ..update('foto_pohon', (_) => fotoUrl, ifAbsent: () => fotoUrl)
        ..update('growth_rate', (_) => pohon.growthRate,
            ifAbsent: () => 0.0)
        ..update('initial_height', (_) => pohon.initialHeight,
            ifAbsent: () => 0.0)
        ..update(
          'notification_date',
          (_) => Timestamp.fromDate(
              notificationDate.subtract(const Duration(hours: 8))),
          ifAbsent: () => Timestamp.fromDate(
              notificationDate.subtract(const Duration(hours: 8))),
        )
        // 🔥 tambahan penting (biar bisa query & sort)
        ..update(
          'schedule_date_ts',
          (_) => Timestamp.fromDate(pohon.scheduleDate),
          ifAbsent: () => Timestamp.fromDate(pohon.scheduleDate),
        )
        ..update('status', (_) => 1);

      final docRef = await _db
          .collection('data_pohon')
          .add(dataToSave)
          .timeout(const Duration(seconds: 30));

      await docRef.update({'id': docRef.id});

      print(
          '✅ Data tersimpan: ${docRef.id} | foto: ${fotoUrl ?? "null"}');

      return docRef.id;
    } catch (e) {
      print('❌ Error menyimpan data: $e');
      rethrow;
    }
  }

  Stream<List<DataPohon>> getAllDataPohon() {
    return _db
        .collection('data_pohon')
        .where('status', isEqualTo: 1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return DataPohon.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
          }).toList(),
        );
  }

  Future<void> deleteDataPohon(String id) async {
    if (id.isEmpty) throw ArgumentError('Document ID cannot be empty');

    try {
      final docSnapshot =
          await _db.collection('data_pohon').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Dokumen tidak ditemukan');
      }

      await _db
          .collection('data_pohon')
          .doc(id)
          .update({'status': 0})
          .timeout(const Duration(seconds: 30));

      print('✅ Soft delete berhasil: $id');
    } catch (e) {
      print('❌ Error delete: $e');
      rethrow;
    }
  }

  // ─── POHON MATI ───
  Future<void> markAsDead(String id, {String catatan = ''}) async {
    if (id.isEmpty) throw ArgumentError('Document ID cannot be empty');

    try {
      await _db.collection('data_pohon').doc(id).update({
        'status': 2,
        'dead_at': Timestamp.fromDate(DateTime.now()),
        'dead_notes': catatan,
      }).timeout(const Duration(seconds: 30));

      final predSnap = await _db
          .collection('growth_predictions')
          .where('data_pohon_id', isEqualTo: id)
          .where('status', isEqualTo: 1)
          .get();

      if (predSnap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in predSnap.docs) {
          batch.update(doc.reference, {'status': 2});
        }
        await batch.commit();

        print(
            '✅ ${predSnap.docs.length} prediksi dinonaktifkan');
      }

      print('✅ Pohon berhasil ditandai mati');
    } catch (e) {
      print('❌ Error markAsDead: $e');
      rethrow;
    }
  }
}