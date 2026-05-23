import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/growth_prediction.dart';
import '../models/data_pohon.dart';
import '../models/eksekusi.dart';

/*
 * CATATAN PENTING:
 * Query di service ini telah disederhanakan untuk menghindari kebutuhan index Firestore.
 * Sorting dan filtering dilakukan di aplikasi (client-side) untuk performa yang lebih baik.
 *
 * Jika ingin performa yang lebih baik, buat index berikut di Firebase Console:
 * 1. Collection: growth_predictions
 *    Fields: status (Ascending), predicted_next_execution (Ascending)
 *
 * 2. Collection: growth_predictions
 *    Fields: data_pohon_id (Ascending), created_date (Descending)
 *
 * 3. Collection: growth_predictions
 *    Fields: status (Ascending), predicted_next_execution (Ascending)
 */

class GrowthPredictionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'growth_predictions';

  // Membuat prediksi pertumbuhan baru setelah eksekusi
  Future<GrowthPrediction> createPredictionAfterExecution({
    required String dataPohonId,
    required Eksekusi lastExecution,
    required DataPohon pohonData,
    required int repetitionCycle,
  }) async {
    try {
      // ✅ Nonaktifkan semua prediksi lama pohon ini sebelum buat baru
      // Cegah pohon muncul duplikat di Manajemen Repetisi
      await _deactivateOldPredictions(dataPohonId, lastExecution.statusEksekusi);

      // Jika Tebang Habis (statusEksekusi == 2) → tidak perlu buat prediksi baru
      // Pohon sudah tidak ada, tidak akan tumbuh lagi
      if (lastExecution.statusEksekusi == 2) {
        print('✅ Tebang Habis: prediksi lama dinonaktifkan, data_pohon dinonaktifkan, tidak membuat prediksi baru');
        return GrowthPrediction(
          id: '',
          dataPohonId: dataPohonId,
          lastExecutionDate: DateTime.now(),
          lastHeight: 0,
          growthRate: 0,
          safeDistance: 3.0,
          predictedNextExecution: DateTime.now(),
          predictionReason: 'Pohon telah ditebang habis',
          confidenceLevel: 1.0,
          repetitionCycle: repetitionCycle,
          createdDate: DateTime.now(),
          status: 2,
          executionType: 2,
        );
      }

      // ✅ DIPERBAIKI: konversi tinggiPohon dari meter → cm
      // tinggiPohon di Eksekusi satuannya meter, tapi calculateNextExecution butuh cm
      final tinggiPohonCm = lastExecution.tinggiPohon * 100;

      // Hitung prediksi berikutnya (hanya untuk Tebang Pangkas)
      final prediction = GrowthPrediction.calculateNextExecution(
        dataPohonId: dataPohonId,
        lastExecutionDate: _parseExecutionDate(lastExecution.tanggalEksekusi),
        lastHeight: tinggiPohonCm, // ✅ sudah dalam cm
        growthRate: pohonData.growthRate, // sudah dalam cm/tahun
        repetitionCycle: repetitionCycle,
        safeDistance: 3.0, // 3 meter untuk PLN
        executionType: lastExecution.statusEksekusi,
      );

      // Simpan ke Firestore
      final docRef = await _db.collection(_collectionName).add(prediction.toMap());
      final savedPrediction = prediction.copyWith(id: docRef.id);

      // Update document dengan ID
      await docRef.update({'id': docRef.id});

      print('✅ Growth prediction created: ${savedPrediction.predictionReason}');
      return savedPrediction;
    } catch (e) {
      print('❌ Error creating growth prediction: $e');
      rethrow;
    }
  }

  // ✅ Nonaktifkan semua prediksi aktif lama untuk pohon tertentu.
  // Kalau executionType == 2 (Tebang Habis), nonaktifkan juga data_pohon
  // supaya pohon tidak muncul lagi di analitik (query pakai status == 1).
  Future<void> _deactivateOldPredictions(String dataPohonId, int executionType) async {
    try {
      final snapshot = await _db
          .collection(_collectionName)
          .where('data_pohon_id', isEqualTo: dataPohonId)
          .where('status', isEqualTo: 1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Batch update growth_predictions → status 2 (completed)
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'status': 2});
        }
        await batch.commit();
        print('✅ Nonaktifkan ${snapshot.docs.length} prediksi lama untuk pohon $dataPohonId');
      }

      // ✅ FIX UTAMA: Kalau Tebang Habis, nonaktifkan juga data_pohon
      // Ini yang menyebabkan pohon masih muncul di analitik sebelumnya
      if (executionType == 2) {
        await _db
            .collection('data_pohon')
            .doc(dataPohonId)
            .update({'status': 0}); // 0 = nonaktif / tebang habis
        print('✅ data_pohon dinonaktifkan: $dataPohonId');
      }
    } catch (e) {
      print('⚠️ Gagal menonaktifkan prediksi lama: $e');
      // Tidak rethrow — jangan sampai gagal ini menghentikan proses eksekusi
    }
  }

  // Mendapatkan semua prediksi aktif (versi sederhana tanpa index)
  Stream<List<GrowthPrediction>> getActivePredictions() {
    return _db
        .collection(_collectionName)
        .where('status', isEqualTo: 1)
        .snapshots()
        .map((snapshot) {
          final predictions = snapshot.docs
              .map((doc) => GrowthPrediction.fromMap(doc.data(), doc.id))
              .toList();

          // Sort di aplikasi (lebih lambat tapi tidak butuh index)
          predictions.sort((a, b) => a.predictedNextExecution.compareTo(b.predictedNextExecution));

          return predictions;
        });
  }

  // Mendapatkan prediksi untuk pohon tertentu (versi sederhana)
  Future<List<GrowthPrediction>> getPredictionsForTree(String dataPohonId) async {
    try {
      final snapshot = await _db
          .collection(_collectionName)
          .where('data_pohon_id', isEqualTo: dataPohonId)
          .get();

      final predictions = snapshot.docs
          .map((doc) => GrowthPrediction.fromMap(doc.data(), doc.id))
          .toList();

      // Sort di aplikasi
      predictions.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      return predictions;
    } catch (e) {
      print('❌ Error getting predictions for tree: $e');
      return [];
    }
  }

  // Mendapatkan prediksi yang sudah due untuk eksekusi (versi sederhana)
  Future<List<GrowthPrediction>> getDuePredictions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _db
          .collection(_collectionName)
          .where('status', isEqualTo: 1)
          .get();

      final predictions = snapshot.docs
          .map((doc) => GrowthPrediction.fromMap(doc.data(), doc.id))
          .toList();

      // Filter di aplikasi berdasarkan tanggal
      final duePredictions = predictions
          .where((p) => p.predictedNextExecution.isBefore(now) ||
              p.predictedNextExecution.isAtSameMomentAs(now))
          .toList();

      return duePredictions;
    } catch (e) {
      print('❌ Error getting due predictions: $e');
      return [];
    }
  }

  // Update status prediksi setelah eksekusi
  Future<void> markPredictionExecuted(String predictionId) async {
    try {
      await _db.collection(_collectionName).doc(predictionId).update({
        'status': 2, // executed
      });
      print('✅ Prediction marked as executed: $predictionId');
    } catch (e) {
      print('❌ Error marking prediction executed: $e');
      rethrow;
    }
  }

  // Membatalkan prediksi
  Future<void> cancelPrediction(String predictionId, String reason) async {
    try {
      await _db.collection(_collectionName).doc(predictionId).update({
        'status': 3, // cancelled
        'prediction_reason': reason,
      });
      print('✅ Prediction cancelled: $predictionId');
    } catch (e) {
      print('❌ Error cancelling prediction: $e');
      rethrow;
    }
  }

  // Helper method untuk parse tanggal eksekusi
  DateTime _parseExecutionDate(String tanggalEksekusi) {
    try {
      // Format: DD/MM/YYYY HH:MM WITA
      final parts = tanggalEksekusi.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // DD/MM/YYYY
        final timePart = parts[1]; // HH:MM

        final dateParts = datePart.split('/');
        final timeParts = timePart.split(':');

        return DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
          int.parse(timeParts[0]), // hour
          int.parse(timeParts[1]), // minute
        );
      }
      // Fallback jika format tidak sesuai
      return DateTime.parse(tanggalEksekusi.replaceAll('/', '-'));
    } catch (e) {
      print('⚠️ Error parsing execution date: $tanggalEksekusi, using current date');
      return DateTime.now();
    }
  }

  // Update status prediksi
  Future<void> updatePredictionStatus(String predictionId, int status) async {
    try {
      await _db.collection(_collectionName).doc(predictionId).update({
        'status': status,
      });
      print('✅ Prediction status updated: $predictionId -> $status');
    } catch (e) {
      print('❌ Error updating prediction status: $e');
      throw e;
    }
  }

  // Update execution type dan notes untuk prediksi yang sudah ada
  Future<void> updatePredictionExecutionDetails(
    String predictionId,
    int executionType,
    String executionNotes,
  ) async {
    try {
      await _db.collection(_collectionName).doc(predictionId).update({
        'execution_type': executionType,
        'last_execution_notes': executionNotes,
      });
      print('✅ Prediction execution details updated: $predictionId');
    } catch (e) {
      print('❌ Error updating prediction execution details: $e');
      throw e;
    }
  }

  // ✅ FIX UTAMA: Nonaktifkan data_pohon saat tebang habis dari provider
  // Dipanggil dari executeCompleteTreeFelling di provider
  Future<void> deactivateTreeAfterFelling(String dataPohonId) async {
    try {
      await _db
          .collection('data_pohon')
          .doc(dataPohonId)
          .update({'status': 0}); // 0 = nonaktif / tebang habis
      print('✅ data_pohon dinonaktifkan setelah tebang habis: $dataPohonId');
    } catch (e) {
      print('❌ Error deactivating data_pohon: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRepetitionStatistics() async {
    try {
      final snapshot = await _db.collection(_collectionName).get();

      final predictions = snapshot.docs
          .map((doc) => GrowthPrediction.fromMap(doc.data(), doc.id))
          .toList();

      final activePredictions = predictions.where((p) => p.status == 1).toList();
      final executedPredictions = predictions.where((p) => p.status == 2).toList();
      final duePredictions = activePredictions.where((p) => p.isDueForExecution()).toList();

      // Hitung rata-rata confidence level
      final avgConfidence = activePredictions.isEmpty
          ? 0.0
          : activePredictions
                  .map((p) => p.confidenceLevel)
                  .reduce((a, b) => a + b) /
              activePredictions.length;

      return {
        'total_predictions': predictions.length,
        'active_predictions': activePredictions.length,
        'executed_predictions': executedPredictions.length,
        'due_predictions': duePredictions.length,
        'average_confidence': avgConfidence,
        'predictions_by_priority': {
          'high': activePredictions.where((p) => p.getPriority() == 3).length,
          'medium': activePredictions.where((p) => p.getPriority() == 2).length,
          'low': activePredictions.where((p) => p.getPriority() == 1).length,
        },
      };
    } catch (e) {
      print('❌ Error getting repetition statistics: $e');
      return {};
    }
  }
}