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
      // Hitung prediksi berikutnya
      final prediction = GrowthPrediction.calculateNextExecution(
        dataPohonId: dataPohonId,
        lastExecutionDate: _parseExecutionDate(lastExecution.tanggalEksekusi),
        lastHeight: lastExecution.tinggiPohon,
        growthRate: pohonData.growthRate,
        repetitionCycle: repetitionCycle,
        safeDistance: 3.0, // 3 meter untuk PLN
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
          .where((p) => p.predictedNextExecution.isBefore(now) || p.predictedNextExecution.isAtSameMomentAs(now))
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

  // Method untuk menghitung statistik repetisi
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
          : activePredictions.map((p) => p.confidenceLevel).reduce((a, b) => a + b) / activePredictions.length;

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