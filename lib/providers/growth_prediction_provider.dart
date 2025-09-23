import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/growth_prediction.dart';
import '../models/data_pohon.dart';
import '../models/eksekusi.dart';
import '../services/growth_prediction_service.dart';
import '../providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GrowthPredictionProvider with ChangeNotifier {
  final GrowthPredictionService _growthService = GrowthPredictionService();
  // DataPohonService no longer used after removing auto-schedule

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

      // Build a map of existing active predictions by data_pohon_id
      final existingIds = predictions.map((p) => p.dataPohonId).toSet();

      // Fetch all active trees and add synthetic defaults for those without predictions
      final db = FirebaseFirestore.instance;
      final pohonSnap = await db
          .collection('data_pohon')
          .where('status', isEqualTo: 1)
          .get();

      // Build DataPohon list and map for access filtering
      final activeTrees = <DataPohon>[];
      final treeMap = <String, DataPohon>{};
      for (final doc in pohonSnap.docs) {
        final dp = DataPohon.fromMap({...doc.data(), 'id': doc.id});
        activeTrees.add(dp);
        treeMap[doc.id] = dp;
      }

      // Load access from session (same rule as treemapping report)
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';
      bool allowed(DataPohon p) {
        if (level == 2) {
          return p.up3 == sessionUnit || p.ulp == sessionUnit;
        }
        return true; // level 1 (admin) or others: show all
      }

      final synthetic = <GrowthPrediction>[];
      for (final data in activeTrees) {
        final id = data.id;
        if (existingIds.contains(id)) continue;
        if (!allowed(data)) continue; // respect access
        // Create a lightweight synthetic prediction using the initial scheduleDate
        synthetic.add(
          GrowthPrediction(
            id: 'synthetic:$id',
            dataPohonId: id,
            lastExecutionDate: data.scheduleDate, // baseline
            lastHeight: data.initialHeight,
            growthRate: data.growthRate,
            safeDistance: 3.0,
            predictedNextExecution: data.scheduleDate,
            predictionReason: 'Belum ada eksekusi. Menggunakan tanggal penjadwalan awal.',
            confidenceLevel: 0.5,
            repetitionCycle: 0,
            createdDate: DateTime.now(),
            status: 1,
            executionType: data.tujuanPenjadwalan,
            lastExecutionNotes: '',
          ),
        );
      }

      // Apply access filter to real predictions as well
      final filteredReal = predictions.where((p) {
        final t = treeMap[p.dataPohonId];
        if (t == null) return false; // only consider active trees
        return allowed(t);
      }).toList();

      final merged = [...filteredReal, ...synthetic]
        ..sort((a, b) => a.predictedNextExecution.compareTo(b.predictedNextExecution));

      _activePredictions = merged;
      print('✅ Loaded ${predictions.length} active predictions (+${synthetic.length} default)');
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
    int executionType = 1, // Default: tebang pangkas
    String executionNotes = '',
  }) async {
    try {
      // Ambil data pohon dan eksekusi sebenarnya dari Firestore
      final db = FirebaseFirestore.instance;

      final pohonDoc = await db.collection('data_pohon').doc(dataPohonId).get();
      if (!pohonDoc.exists) {
        throw Exception('Data pohon tidak ditemukan untuk ID: $dataPohonId');
      }
      final pohonData = DataPohon.fromMap({
        ...pohonDoc.data()!,
        'id': pohonDoc.id,
      });

      final eksekusiDoc = await db.collection('eksekusi').doc(eksekusiId).get();
      if (!eksekusiDoc.exists) {
        throw Exception('Data eksekusi tidak ditemukan untuk ID: $eksekusiId');
      }
      final lastExecution = Eksekusi.fromMap({
        ...eksekusiDoc.data()!,
        'id': eksekusiDoc.id,
      });

      // Hitung siklus berdasarkan jumlah eksekusi di Firestore (cycle = jumlah eksekusi)
      final execSnapshot = await db
          .collection('eksekusi')
          .where('data_pohon_id', isEqualTo: dataPohonId)
          .get();
      final nextCycle = execSnapshot.docs.length; // 0 jika belum pernah eksekusi

      // Buat prediksi baru
      final prediction = await _growthService.createPredictionAfterExecution(
        dataPohonId: dataPohonId,
        lastExecution: lastExecution,
        pohonData: pohonData,
        repetitionCycle: nextCycle,
      );

      // Update execution details jika disediakan
      if (executionType != 1 || executionNotes.isNotEmpty) {
        await _growthService.updatePredictionExecutionDetails(
          prediction.id,
          executionType,
          executionNotes,
        );
      }

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

  // Menangani eksekusi tebang habis (complete tree felling)
  Future<void> executeCompleteTreeFelling({
    required String predictionId,
    required String executionNotes,
    required BuildContext context,
  }) async {
    try {
      // Dapatkan data prediksi
      final predictionIndex = _activePredictions.indexWhere((p) => p.id == predictionId);
      if (predictionIndex == -1) {
        throw Exception('Prediction not found');
      }

      final currentPrediction = _activePredictions[predictionIndex];

      // Tandai prediksi sebagai sudah dieksekusi dengan status completed
      await _growthService.markPredictionExecuted(predictionId);

      // Update status menjadi completed (2) untuk tebang habis
      await _growthService.updatePredictionStatus(predictionId, 2);

      // Update execution details
      await _growthService.updatePredictionExecutionDetails(
        predictionId,
        2, // executionType = 2 (tebang habis)
        executionNotes,
      );

      // Update local data
      _activePredictions[predictionIndex] = currentPrediction.copyWith(
        status: 2,
        executionType: 2,
        lastExecutionNotes: executionNotes,
      );

      // Buat notifikasi bahwa pohon telah dihapus sepenuhnya
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final message = 'Pohon ${currentPrediction.dataPohonId} telah dihapus sepenuhnya (tebang habis)';

      final notification = AppNotification(
        title: 'Pohon Dihapus Sepenuhnya',
        message: message,
        date: DateTime.now(),
        idPohon: currentPrediction.dataPohonId,
      );

      await notificationProvider.addNotification(
        notification,
        scheduleDate: null, // Tidak perlu schedule karena pohon sudah tidak ada
        pohonId: currentPrediction.dataPohonId,
        namaPohon: 'Pohon ${currentPrediction.dataPohonId}',
        documentIdPohon: currentPrediction.dataPohonId,
      );

      notifyListeners();
      print('✅ Complete tree felling executed for prediction: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal mengeksekusi tebang habis: $e';
      print('❌ Error executing complete felling: $e');
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

  // Menandai prediksi sebagai sudah dieksekusi dan membuat prediksi baru untuk siklus berikutnya
  Future<void> markPredictionExecuted({
    required String predictionId,
    required int executionType,
    required String executionNotes,
    required BuildContext context,
  }) async {
    try {
      // Dapatkan data prediksi yang akan dieksekusi
      final predictionIndex = _activePredictions.indexWhere((p) => p.id == predictionId);
      if (predictionIndex == -1) {
        throw Exception('Prediction not found');
      }

      final currentPrediction = _activePredictions[predictionIndex];

      // Tandai prediksi saat ini sebagai sudah dieksekusi
      await _growthService.markPredictionExecuted(predictionId);

      // Jika ini adalah tebang habis (executionType = 2), tandai pohon sebagai selesai
      if (executionType == 2) {
        // Update status menjadi completed (2) untuk tebang habis
        await _growthService.updatePredictionStatus(predictionId, 2);
        _activePredictions[predictionIndex] = currentPrediction.copyWith(status: 2);
      } else {
        // Untuk tebang pangkas (executionType = 1), buat prediksi baru untuk siklus berikutnya
  final nextCycle = currentPrediction.repetitionCycle + 1;

        // Simpan prediksi baru
        final createdPrediction = await _growthService.createPredictionAfterExecution(
          dataPohonId: currentPrediction.dataPohonId,
          lastExecution: Eksekusi(
            id: '',
            dataPohonId: currentPrediction.dataPohonId,
            statusEksekusi: 1,
            tanggalEksekusi: DateTime.now().toString(),
            createdBy: '',
            createdDate: Timestamp.now(),
            status: 1,
            tinggiPohon: currentPrediction.lastHeight,
            diameterPohon: 0.0,
          ),
          pohonData: await _getTreeData(currentPrediction.dataPohonId),
          repetitionCycle: nextCycle,
        );

        // Update execution details untuk prediksi baru
        await _growthService.updatePredictionExecutionDetails(
          createdPrediction.id,
          executionType,
          executionNotes,
        );

        // Update status prediksi saat ini menjadi completed
        _activePredictions[predictionIndex] = currentPrediction.copyWith(status: 2);

        // Buat notifikasi untuk prediksi baru
        await _createNotificationForPrediction(createdPrediction, context);
      }

      notifyListeners();
      print('✅ Prediction executed and new cycle created: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal mengeksekusi prediksi: $e';
      print('❌ Error executing prediction: $e');
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

  // Auto schedule feature removed as per product requirements

  // Helper method untuk mendapatkan data pohon
  Future<DataPohon> _getTreeData(String dataPohonId) async {
    try {
      // Untuk sementara, kita akan menggunakan data dummy karena service belum memiliki method getById
      // Dalam implementasi nyata, ini perlu diganti dengan service call yang proper
      return DataPohon(
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
  createdBy: 'DUMMY_USER_ID',
        createdDate: DateTime.now(),
        growthRate: 40.0, // Growth rate untuk Kesambi
        initialHeight: 150.0, // Tinggi awal 150cm
        notificationDate: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error getting tree data: $e');
      throw e;
    }
  }

  // Helper method untuk mendapatkan eksekusi terakhir
  // Note: last execution helper removed with auto-schedule

  // Catatan: Prediksi awal untuk pohon tanpa eksekusi telah dihapus.
}