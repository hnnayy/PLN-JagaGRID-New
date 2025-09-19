import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/growth_prediction.dart';
import '../models/data_pohon.dart';
import '../models/eksekusi.dart';
import '../services/growth_prediction_service.dart';
import '../services/data_pohon_service.dart';
import '../providers/notification_provider.dart';

class GrowthPredictionProvider with ChangeNotifier {
  final GrowthPredictionService _growthService = GrowthPredictionService();
  final DataPohonService _dataPohonService = DataPohonService();

  List<GrowthPrediction> _activePredictions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<GrowthPrediction> get activePredictions => _activePredictions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mendapatkan semua prediksi aktif
  Future<void> loadActivePredictions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final predictions = await _growthService.getActivePredictions().first;
      _activePredictions = predictions;
      print('✅ Loaded ${_activePredictions.length} active predictions');
    } catch (e) {
      _errorMessage = 'Gagal memuat prediksi: $e';
      print('❌ Error loading predictions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Membuat prediksi baru setelah eksekusi
  Future<GrowthPrediction?> createPredictionAfterExecution({
    required String dataPohonId,
    required String eksekusiId,
    required BuildContext context,
  }) async {
    try {
      // Untuk sementara, kita akan menggunakan data dummy karena service belum memiliki method getById
      // Dalam implementasi nyata, ini perlu diganti dengan service call yang proper

      // Dummy data untuk demonstrasi
      final dummyPohonData = DataPohon(
        id: dataPohonId,
        idPohon: 'DUMMY_ID',
        up3: 'DUMMY_UP3',
        ulp: 'DUMMY_ULP',
        penyulang: 'DUMMY_PENYULANG',
        zonaProteksi: 'DUMMY_ZONA',
        section: 'DUMMY_SECTION',
        kmsAset: 'DUMMY_KMS',
        vendor: 'DUMMY_VENDOR',
        asetJtmId: 1,
        scheduleDate: DateTime.now(),
        prioritas: 1,
        namaPohon: 'Kesambi', // Menggunakan nama pohon yang ada di growthRates
        fotoPohon: '',
        koordinat: '0,0',
        tujuanPenjadwalan: 1,
        catatan: 'Dummy data untuk testing',
        createdBy: 1,
        createdDate: DateTime.now(),
        growthRate: 40.0, // Growth rate untuk Kesambi
        initialHeight: 150.0, // Tinggi awal 150cm
        notificationDate: DateTime.now(),
      );

      // Dummy eksekusi data
      final dummyEksekusiData = Eksekusi(
        id: eksekusiId,
        dataPohonId: dataPohonId,
        statusEksekusi: 1,
        tanggalEksekusi: DateTime.now().toString(),
        createdBy: 1,
        createdDate: Timestamp.now(),
        status: 1,
        tinggiPohon: 120.0, // Tinggi setelah eksekusi
        diameterPohon: 15.0,
      );

      // Hitung siklus repetisi berikutnya
      final existingPredictions = await _growthService.getPredictionsForTree(dataPohonId);
      final nextCycle = existingPredictions.length + 1;

      // Buat prediksi baru
      final prediction = await _growthService.createPredictionAfterExecution(
        dataPohonId: dataPohonId,
        lastExecution: dummyEksekusiData,
        pohonData: dummyPohonData,
        repetitionCycle: nextCycle,
      );

      // Buat notifikasi otomatis untuk prediksi baru
      await _createNotificationForPrediction(prediction, context);

      // Reload data
      await loadActivePredictions();

      return prediction;
    } catch (e) {
      _errorMessage = 'Gagal membuat prediksi: $e';
      print('❌ Error creating prediction: $e');
      return null;
    }
  }

  // Membuat notifikasi otomatis untuk prediksi
  Future<void> _createNotificationForPrediction(
    GrowthPrediction prediction,
    BuildContext context
  ) async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      // Hitung tanggal notifikasi (3 hari sebelum prediksi)
      final notificationDate = prediction.predictedNextExecution.subtract(const Duration(days: 3));

      // Buat pesan notifikasi
      final message = 'Pohon ${prediction.dataPohonId} perlu perawatan dalam ${prediction.predictionReason.split('.').last.trim()}';

      // Buat notifikasi
      final notification = AppNotification(
        title: 'Reminder Perawatan Pohon',
        message: message,
        date: DateTime.now(),
        idPohon: prediction.dataPohonId,
      );

      await notificationProvider.addNotification(
        notification,
        scheduleDate: notificationDate,
        pohonId: prediction.dataPohonId,
        namaPohon: 'Pohon ${prediction.dataPohonId}',
        documentIdPohon: prediction.dataPohonId,
      );

      print('✅ Notification created for prediction: ${prediction.id}');
    } catch (e) {
      print('⚠️ Failed to create notification for prediction: $e');
    }
  }

  // Menandai prediksi sebagai sudah dieksekusi
  Future<void> markPredictionExecuted(String predictionId) async {
    try {
      await _growthService.markPredictionExecuted(predictionId);

      // Update local data
      final index = _activePredictions.indexWhere((p) => p.id == predictionId);
      if (index != -1) {
        _activePredictions[index] = _activePredictions[index].copyWith(status: 2);
        notifyListeners();
      }

      print('✅ Prediction marked as executed: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal menandai prediksi: $e';
      print('❌ Error marking prediction executed: $e');
    }
  }

  // Membatalkan prediksi
  Future<void> cancelPrediction(String predictionId, String reason) async {
    try {
      await _growthService.cancelPrediction(predictionId, reason);

      // Update local data
      final index = _activePredictions.indexWhere((p) => p.id == predictionId);
      if (index != -1) {
        _activePredictions[index] = _activePredictions[index].copyWith(status: 3);
        notifyListeners();
      }

      print('✅ Prediction cancelled: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal membatalkan prediksi: $e';
      print('❌ Error cancelling prediction: $e');
    }
  }

  // Mendapatkan prediksi yang sudah due
  Future<List<GrowthPrediction>> getDuePredictions() async {
    try {
      return await _growthService.getDuePredictions();
    } catch (e) {
      print('❌ Error getting due predictions: $e');
      return [];
    }
  }

  // Mendapatkan statistik repetisi
  Future<Map<String, dynamic>> getRepetitionStatistics() async {
    try {
      return await _growthService.getRepetitionStatistics();
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }

  // Mendapatkan prediksi berdasarkan pohon tertentu
  Future<List<GrowthPrediction>> getPredictionsForTree(String dataPohonId) async {
    try {
      return await _growthService.getPredictionsForTree(dataPohonId);
    } catch (e) {
      print('❌ Error getting predictions for tree: $e');
      return [];
    }
  }

  // Method untuk auto-scheduling semua pohon yang belum memiliki prediksi
  Future<void> autoScheduleAllTrees(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ambil semua data pohon
      final allTreesData = await _dataPohonService.getAllDataPohon().first;

      for (final tree in allTreesData) {
        // Cek apakah pohon sudah memiliki prediksi aktif
        final existingPredictions = await getPredictionsForTree(tree.id);
        final hasActivePrediction = existingPredictions.any((p) => p.status == 1);

        if (!hasActivePrediction) {
          // Ambil eksekusi terakhir untuk pohon ini
          final lastExecution = await _getLastExecutionForTree(tree.id);

          if (lastExecution != null) {
            // Buat prediksi baru
            await createPredictionAfterExecution(
              dataPohonId: tree.id,
              eksekusiId: lastExecution.id,
              context: context,
            );
          } else {
            // Jika belum pernah dieksekusi, buat prediksi berdasarkan tinggi awal
            await _createInitialPrediction(tree, context);
          }
        }
      }

      await loadActivePredictions();
      print('✅ Auto-scheduling completed for all trees');
    } catch (e) {
      _errorMessage = 'Gagal auto-scheduling: $e';
      print('❌ Error in auto-scheduling: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method untuk mendapatkan eksekusi terakhir
  Future<Eksekusi?> _getLastExecutionForTree(String dataPohonId) async {
    try {
      // Implementasi untuk mendapatkan eksekusi terakhir
      // Ini perlu disesuaikan dengan service eksekusi yang ada
      return null; // Placeholder
    } catch (e) {
      print('❌ Error getting last execution: $e');
      return null;
    }
  }

  // Membuat prediksi awal untuk pohon yang belum pernah dieksekusi
  Future<void> _createInitialPrediction(DataPohon tree, BuildContext context) async {
    try {
      final prediction = GrowthPrediction.calculateNextExecution(
        dataPohonId: tree.id,
        lastExecutionDate: DateTime.now(),
        lastHeight: tree.initialHeight,
        growthRate: tree.growthRate,
        repetitionCycle: 1,
      );

      await _growthService.createPredictionAfterExecution(
        dataPohonId: tree.id,
        lastExecution: Eksekusi(
          id: '',
          dataPohonId: tree.id,
          statusEksekusi: 1,
          tanggalEksekusi: DateTime.now().toString(),
          createdBy: 0,
          createdDate: Timestamp.now(),
          status: 1,
          tinggiPohon: tree.initialHeight,
          diameterPohon: 0.0,
        ),
        pohonData: tree,
        repetitionCycle: 1,
      );

      // Buat notifikasi untuk prediksi awal
      await _createNotificationForPrediction(prediction, context);

      print('✅ Initial prediction created for tree: ${tree.id}');
    } catch (e) {
      print('❌ Error creating initial prediction: $e');
    }
  }
}