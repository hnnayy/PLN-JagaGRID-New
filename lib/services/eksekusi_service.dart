import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathLib;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/eksekusi.dart';
import '../models/data_pohon.dart';
import 'growth_prediction_service.dart';
import '../providers/notification_provider.dart';

class EksekusiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _imageKitUploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  final String _privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

  String _formatTanggalIndo(DateTime dt) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _toTitleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> addEksekusi(
    Eksekusi eksekusi,
    File image,
    NotificationProvider notificationProvider,
  ) async {
    try {
      if (eksekusi.statusEksekusi != 1 && eksekusi.statusEksekusi != 2) {
        throw ArgumentError(
            'statusEksekusi must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
      }

      final dataPohonSnapshot = await _db
          .collection('data_pohon')
          .doc(eksekusi.dataPohonId)
          .get();

      if (!dataPohonSnapshot.exists) {
        throw Exception('Invalid dataPohonId: No matching DataPohon found');
      }

      if (!await image.exists()) {
        throw Exception('Image file not found');
      }

      // ── Kompres foto ──
      File compressedImage = image;
      try {
        if (await image.length() > 1000000) {
          final dir = await getTemporaryDirectory();
          final targetPath = pathLib.join(
            dir.path,
            '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
          );
          final result = await FlutterImageCompress.compressAndGetFile(
            image.absolute.path,
            targetPath,
            quality: 60,
            minWidth: 800,
            minHeight: 800,
            format: CompressFormat.jpeg,
          );
          if (result != null) {
            compressedImage = File(result.path);
            print('📉 Compressed: ${await compressedImage.length()} bytes');
          }
        }
      } catch (e) {
        print('⚠️ Gagal kompres foto: $e');
      }

      // ── Upload ke ImageKit ──
      var request =
          http.MultipartRequest('POST', Uri.parse(_imageKitUploadUrl));
      String auth = base64Encode(utf8.encode('$_privateKey:'));
      request.headers['Authorization'] = 'Basic $auth';
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${eksekusi.dataPohonId}_eksekusi.jpg';
      request.fields['fileName'] = fileName;
      request.fields['folder'] = '/foto_pohon_setelah_eksekusi';
      request.files.add(
          await http.MultipartFile.fromPath('file', compressedImage.path));

      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      String? fotoUrl;
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('url')) {
          fotoUrl = jsonResponse['url'] as String;
          print('✅ Upload sukses: $fotoUrl');
        } else {
          throw Exception('ImageKit response tidak valid');
        }
      } else {
        throw Exception('Upload gagal: ${response.statusCode}');
      }

      // ── Simpan eksekusi ke Firestore ──
      // ✅ Pakai tanggalEksekusi dari user (sudah include jam WITA dari UI)
      // Import intl sudah tidak diperlukan di sini karena format dibuat di UI
      final formattedTanggalEksekusi = eksekusi.tanggalEksekusi;

      final updatedEksekusi = Eksekusi(
        id: eksekusi.id,
        dataPohonId: eksekusi.dataPohonId,
        statusEksekusi: eksekusi.statusEksekusi,
        tanggalEksekusi: formattedTanggalEksekusi, // ✅ dari user, bukan DateTime.now()
        fotoSetelah: fotoUrl,
        createdBy: eksekusi.createdBy,
        createdDate: eksekusi.createdDate,
        status: eksekusi.status,
        tinggiPohon: eksekusi.tinggiPohon,
        diameterPohon: eksekusi.diameterPohon,
      );

      final docRef = await _db
          .collection('eksekusi')
          .add(updatedEksekusi.toMap())
          .timeout(const Duration(seconds: 30));
      await docRef.update({'id': docRef.id});
      print('✅ Eksekusi tersimpan: ${docRef.id}');

      // ── Ambil nama teknisi dari session ──
      String namaTeknisi = '-';
      try {
        final prefs = await SharedPreferences.getInstance();
        namaTeknisi = prefs.getString('session_name') ?? '-';
      } catch (_) {}

      // ═══════════════════════════════════════
      // TEBANG HABIS
      // ═══════════════════════════════════════
      if (eksekusi.statusEksekusi == 2) {
        try {
          final pohonDoc = await _db
              .collection('data_pohon')
              .doc(eksekusi.dataPohonId)
              .get();

          if (pohonDoc.exists) {
            final pohon = DataPohon.fromMap({
              ...pohonDoc.data()!,
              'id': pohonDoc.id,
            });

            final ulpFormatted = _toTitleCase(pohon.ulp);

            final appTitle = 'Tebang Habis Selesai — ${pohon.namaPohon}';
            final appMessage =
                '${pohon.idPohon} • $ulpFormatted • $formattedTanggalEksekusi';

            final telegramMessage =
'✅ *Eksekusi Tebang Habis Selesai*\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'Pohon      : ${pohon.namaPohon}\n'
'ID         : ${pohon.idPohon}\n'
'ULP        : $ulpFormatted\n'
'Penyulang  : ${pohon.penyulang.isNotEmpty ? pohon.penyulang : "-"}\n'
'Tanggal    : $formattedTanggalEksekusi\n'
'Teknisi    : $namaTeknisi\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'Pohon telah ditebang habis.\n'
'_PLN JagaGRID_';

            await notificationProvider.addNotification(
              AppNotification(
                title: appTitle,
                message: appMessage,
                date: DateTime.now(),
                idPohon: pohon.idPohon,
              ),
              documentIdPohon: pohon.id,
            );

            await notificationProvider.sendTelegramMessageForTree(
              telegramMessage,
              dataPohonId: pohon.id,
              koordinat: pohon.koordinat,
            );
          }
        } catch (e) {
          print('⚠️ Gagal kirim notifikasi tebang habis: $e');
        }
        return;
      }

      // ═══════════════════════════════════════
      // TEBANG PANGKAS
      // ═══════════════════════════════════════
      try {
        final pohonDoc = await _db
            .collection('data_pohon')
            .doc(eksekusi.dataPohonId)
            .get();

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
          final createdPrediction =
              await growthService.createPredictionAfterExecution(
            dataPohonId: eksekusi.dataPohonId,
            lastExecution: updatedEksekusi,
            pohonData: pohon,
            repetitionCycle: repetitionCycle,
          );

          // Set reminder_sent = false → backend cron H-3 akan pickup ini
          try {
            final predSnap = await _db
                .collection('growth_predictions')
                .where('data_pohon_id', isEqualTo: pohon.id)
                .where('status', isEqualTo: 1)
                .get();
            for (final pd in predSnap.docs) {
              await pd.reference.update({'reminder_sent': false});
            }
          } catch (e) {
            print('⚠️ Gagal set reminder_sent: $e');
          }

          final ulpFormatted = _toTitleCase(pohon.ulp);
          final prediksiFormatted =
              _formatTanggalIndo(createdPrediction.predictedNextExecution);

          final appTitle = 'Tebang Pangkas Selesai — ${pohon.namaPohon}';
          final appMessage =
              '${pohon.idPohon} • $ulpFormatted • $formattedTanggalEksekusi';

          final telegramMessage =
'✅ *Eksekusi Tebang Pangkas Selesai*\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'Pohon      : ${pohon.namaPohon}\n'
'ID         : ${pohon.idPohon}\n'
'ULP        : $ulpFormatted\n'
'Penyulang  : ${pohon.penyulang.isNotEmpty ? pohon.penyulang : "-"}\n'
'Tinggi     : ${eksekusi.tinggiPohon} m\n'
'Tanggal    : $formattedTanggalEksekusi\n'
'Teknisi    : $namaTeknisi\n'
'━━━━━━━━━━━━━━━━━━━━\n'
'Prediksi eksekusi berikutnya: $prediksiFormatted\n'
'_PLN JagaGRID_';

          await notificationProvider.addNotification(
            AppNotification(
              title: appTitle,
              message: appMessage,
              date: DateTime.now(),
              idPohon: pohon.idPohon,
            ),
            documentIdPohon: pohon.id,
          );

          await notificationProvider.sendTelegramMessageForTree(
            telegramMessage,
            dataPohonId: pohon.id,
            koordinat: pohon.koordinat,
          );

          print('✅ Notifikasi eksekusi terkirim');
          print('ℹ️ H-3 reminder ditangani backend server');
        }
      } catch (e) {
        print('⚠️ Gagal buat prediksi/notifikasi: $e');
      }
    } catch (e) {
      print('❌ Error addEksekusi: $e');
      rethrow;
    }
  }

  Stream<List<Eksekusi>> getAllEksekusi() {
    return _db.collection('eksekusi').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  Eksekusi.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}