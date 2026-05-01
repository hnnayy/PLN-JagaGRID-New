import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../models/eksekusi.dart';
import '../models/data_pohon.dart';
import 'growth_prediction_service.dart';
import '../providers/notification_provider.dart';

class EksekusiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  Future<void> addEksekusi(Eksekusi eksekusi, File image) async {
    try {
      if (eksekusi.statusEksekusi != 1 && eksekusi.statusEksekusi != 2) {
        print('Error: Invalid statusEksekusi value: ${eksekusi.statusEksekusi}');
        throw ArgumentError('statusEksekusi must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
      }

      final dataPohonSnapshot = await _db.collection('data_pohon').doc(eksekusi.dataPohonId).get();
      if (!dataPohonSnapshot.exists) {
        throw Exception('Invalid dataPohonId: No matching DataPohon document found');
      }

      if (!await image.exists()) {
        throw Exception('Image file not found');
      }

      var request = http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
      String auth = base64Encode(utf8.encode('$_privateKey:'));
      request.headers['Authorization'] = 'Basic $auth';

      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${eksekusi.dataPohonId}_eksekusi.jpg';
      request.fields['fileName'] = fileName;
      request.fields['folder'] = '/foto_pohon_setelah_eksekusi';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      print('Uploading image to ImageKit: $fileName');
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      String? fotoUrl;
      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('url')) {
            fotoUrl = jsonResponse['url'] as String;
            print('Image upload successful: $fotoUrl');
          } else {
            throw Exception('ImageKit response does not contain a valid URL');
          }
        } catch (jsonError) {
          throw Exception('Failed to decode ImageKit response');
        }
      } else {
        throw Exception('Image upload failed: ${response.statusCode}');
      }

      final nowWita = DateTime.now().toUtc().add(const Duration(hours: 8));
      final formattedTanggalEksekusi = DateFormat('dd/MM/yyyy HH:mm').format(nowWita) + ' WITA';

      final updatedEksekusi = Eksekusi(
        id: eksekusi.id,
        dataPohonId: eksekusi.dataPohonId,
        statusEksekusi: eksekusi.statusEksekusi,
        tanggalEksekusi: formattedTanggalEksekusi,
        fotoSetelah: fotoUrl,
        createdBy: eksekusi.createdBy,
        createdDate: eksekusi.createdDate,
        status: eksekusi.status,
        tinggiPohon: eksekusi.tinggiPohon,
        diameterPohon: eksekusi.diameterPohon,
      );

      final docRef = await _db.collection('eksekusi')
          .add(updatedEksekusi.toMap())
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('Eksekusi saved successfully with ID: ${docRef.id}');

      // FIX 6: Tebang habis (statusEksekusi == 2) tidak perlu prediksi baru
      // Pohon sudah tidak ada, tidak akan tumbuh lagi
      if (eksekusi.statusEksekusi == 2) {
        print('✅ Tebang Habis: skip pembuatan prediksi baru');
        return;
      }

      // Lanjut buat prediksi hanya untuk Tebang Pangkas (statusEksekusi == 1)
      try {
        final pohonDoc = await _db.collection('data_pohon').doc(eksekusi.dataPohonId).get();
        if (pohonDoc.exists) {
          final pohon = DataPohon.fromMap({
            ...pohonDoc.data()!,
            'id': pohonDoc.id,
          });

          final execSnapshot = await _db
              .collection('eksekusi')
              .where('data_pohon_id', isEqualTo: eksekusi.dataPohonId)
              .get();
          final repetitionCycle = execSnapshot.docs.length;

          final growthService = GrowthPredictionService();
          final createdPrediction = await growthService.createPredictionAfterExecution(
            dataPohonId: eksekusi.dataPohonId,
            lastExecution: updatedEksekusi,
            pohonData: pohon,
            repetitionCycle: repetitionCycle,
          );

          try {
            final ulpSuffix = (pohon.ulp.isNotEmpty) ? ' oleh ULP ${pohon.ulp}' : '';
            final message = 'Pohon dengan ID ${pohon.idPohon} telah dieksekusi$ulpSuffix '
                'pada tanggal ${updatedEksekusi.tanggalEksekusi} '
                'dengan prediksi penjadwalan selanjutnya pada '
                '${DateFormat('dd/MM/yyyy').format(createdPrediction.predictedNextExecution)}';

            final notificationProvider = NotificationProvider();
            await notificationProvider.addNotification(
              AppNotification(
                title: 'Eksekusi Pohon Berhasil',
                message: message,
                date: DateTime.now(),
                idPohon: pohon.idPohon,
              ),
              documentIdPohon: pohon.id,
            );

            final reminderDate = createdPrediction.predictedNextExecution
                .subtract(const Duration(days: 3));
            final tujuanText = pohon.tujuanPenjadwalan == 1 ? 'Tebang Pangkas' : 'Tebang Habis';
            final reminderMessage = 'Pohon dengan ID ${pohon.idPohon} harus dieksekusi'
                '${ulpSuffix.isNotEmpty ? ulpSuffix : ""} pada tanggal '
                '${DateFormat('dd/MM/yyyy').format(createdPrediction.predictedNextExecution)} '
                'dengan tujuan penjadwalan adalah $tujuanText';

            await notificationProvider.addNotification(
              AppNotification(
                title: 'Pengingat Eksekusi (H-3)',
                message: reminderMessage,
                date: DateTime.now(),
                idPohon: pohon.idPohon,
              ),
              scheduleDate: reminderDate,
              pohonId: pohon.idPohon,
              namaPohon: pohon.namaPohon,
              documentIdPohon: pohon.id,
              scheduledTitleOverride: 'Pengingat Eksekusi (H-3)',
              scheduledMessageOverride: reminderMessage,
            );
          } catch (e) {
            print('⚠️ Gagal mengirim notifikasi setelah eksekusi: $e');
          }
        } else {
          print('⚠️ DataPohon not found for id ${eksekusi.dataPohonId}, skipping prediction');
        }
      } catch (e) {
        print('⚠️ Failed to auto-create growth prediction after execution: $e');
      }
    } catch (e) {
      print('Error saving Eksekusi to Firestore: $e');
      rethrow;
    }
  }

  Stream<List<Eksekusi>> getAllEksekusi() {
    return _db.collection('eksekusi').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Eksekusi.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }
}