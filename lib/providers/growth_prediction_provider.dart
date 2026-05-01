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

  List<GrowthPrediction> _activePredictions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GrowthPrediction> get activePredictions => _activePredictions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadActivePredictions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final predictions = await _growthService.getActivePredictions().first;

      final existingIds = predictions.map((p) => p.dataPohonId).toSet();

      final db = FirebaseFirestore.instance;
      final pohonSnap = await db
          .collection('data_pohon')
          .where('status', isEqualTo: 1)
          .get();

      final activeTrees = <DataPohon>[];
      final treeMap = <String, DataPohon>{};
      for (final doc in pohonSnap.docs) {
        final dp = DataPohon.fromMap({...doc.data(), 'id': doc.id});
        activeTrees.add(dp);
        treeMap[doc.id] = dp;
      }

      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit = prefs.getString('session_unit') ?? '';
      bool allowed(DataPohon p) {
        if (level == 2) {
          return p.up3 == sessionUnit || p.ulp == sessionUnit;
        }
        return true;
      }

      final synthetic = <GrowthPrediction>[];
      for (final data in activeTrees) {
        final id = data.id;
        if (existingIds.contains(id)) continue;
        if (!allowed(data)) continue;
        synthetic.add(
          GrowthPrediction(
            id: 'synthetic:$id',
            dataPohonId: id,
            lastExecutionDate: data.scheduleDate,
            // FIX 4b: konversi meter → cm
            // data.initialHeight dalam meter (diinput teknisi)
            // lastHeight di GrowthPrediction expect cm
            // Tanpa konversi: pohon 1.5m dianggap 1.5cm → prediksi salah besar
            lastHeight: data.initialHeight * 100,
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

      final filteredReal = predictions.where((p) {
        final t = treeMap[p.dataPohonId];
        if (t == null) return false;
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

  Future<GrowthPrediction?> createPredictionAfterExecution({
    required String dataPohonId,
    required String eksekusiId,
    required BuildContext context,
    int executionType = 1,
    String executionNotes = '',
  }) async {
    try {
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

      final execSnapshot = await db
          .collection('eksekusi')
          .where('data_pohon_id', isEqualTo: dataPohonId)
          .get();
      final nextCycle = execSnapshot.docs.length;

      final prediction = await _growthService.createPredictionAfterExecution(
        dataPohonId: dataPohonId,
        lastExecution: lastExecution,
        pohonData: pohonData,
        repetitionCycle: nextCycle,
      );

      if (executionType != 1 || executionNotes.isNotEmpty) {
        await _growthService.updatePredictionExecutionDetails(
          prediction.id,
          executionType,
          executionNotes,
        );
      }

      await _createNotificationForPrediction(prediction, context);
      await loadActivePredictions();

      return prediction;
    } catch (e) {
      _errorMessage = 'Gagal membuat prediksi: $e';
      print('❌ Error creating prediction: $e');
      return null;
    }
  }

  Future<void> executeCompleteTreeFelling({
    required String predictionId,
    required String executionNotes,
    required BuildContext context,
  }) async {
    try {
      final predictionIndex =
          _activePredictions.indexWhere((p) => p.id == predictionId);
      if (predictionIndex == -1) throw Exception('Prediction not found');

      final currentPrediction = _activePredictions[predictionIndex];

      await _growthService.markPredictionExecuted(predictionId);
      await _growthService.updatePredictionStatus(predictionId, 2);
      await _growthService.updatePredictionExecutionDetails(
        predictionId,
        2,
        executionNotes,
      );

      _activePredictions[predictionIndex] = currentPrediction.copyWith(
        status: 2,
        executionType: 2,
        lastExecutionNotes: executionNotes,
      );

      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final message =
          'Pohon ${currentPrediction.dataPohonId} telah dihapus sepenuhnya (tebang habis)';
      final notification = AppNotification(
        title: 'Pohon Dihapus Sepenuhnya',
        message: message,
        date: DateTime.now(),
        idPohon: currentPrediction.dataPohonId,
      );

      await notificationProvider.addNotification(
        notification,
        scheduleDate: null,
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

  Future<void> _createNotificationForPrediction(
    GrowthPrediction prediction,
    BuildContext context,
  ) async {
    try {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final notificationDate = prediction.predictedNextExecution
          .subtract(const Duration(days: 3));
      final message =
          'Pohon ${prediction.dataPohonId} perlu perawatan dalam ${prediction.predictionReason.split('.').last.trim()}';
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

  Future<void> markPredictionExecuted({
    required String predictionId,
    required int executionType,
    required String executionNotes,
    required BuildContext context,
  }) async {
    try {
      final predictionIndex =
          _activePredictions.indexWhere((p) => p.id == predictionId);
      if (predictionIndex == -1) throw Exception('Prediction not found');

      final currentPrediction = _activePredictions[predictionIndex];

      await _growthService.markPredictionExecuted(predictionId);

      if (executionType == 2) {
        await _growthService.updatePredictionStatus(predictionId, 2);
        _activePredictions[predictionIndex] =
            currentPrediction.copyWith(status: 2);
      } else {
        final nextCycle = currentPrediction.repetitionCycle + 1;

        // FIX 4: Fetch data pohon asli dari Firestore
        final pohonData =
            await _getTreeData(currentPrediction.dataPohonId);

        final createdPrediction =
            await _growthService.createPredictionAfterExecution(
          dataPohonId: currentPrediction.dataPohonId,
          lastExecution: Eksekusi(
            id: '',
            dataPohonId: currentPrediction.dataPohonId,
            statusEksekusi: 1,
            tanggalEksekusi: DateTime.now().toString(),
            createdBy: '',
            createdDate: Timestamp.now(),
            status: 1,
            // FIX 5: lastHeight dalam cm → bagi 100 untuk dapat meter
            tinggiPohon: currentPrediction.lastHeight / 100,
            diameterPohon: 0.0,
          ),
          pohonData: pohonData,
          repetitionCycle: nextCycle,
        );

        await _growthService.updatePredictionExecutionDetails(
          createdPrediction.id,
          executionType,
          executionNotes,
        );

        _activePredictions[predictionIndex] =
            currentPrediction.copyWith(status: 2);

        await _createNotificationForPrediction(createdPrediction, context);
      }

      notifyListeners();
      print('✅ Prediction executed and new cycle created: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal mengeksekusi prediksi: $e';
      print('❌ Error executing prediction: $e');
    }
  }

  Future<void> cancelPrediction(String predictionId, String reason) async {
    try {
      await _growthService.cancelPrediction(predictionId, reason);

      final index =
          _activePredictions.indexWhere((p) => p.id == predictionId);
      if (index != -1) {
        _activePredictions[index] =
            _activePredictions[index].copyWith(status: 3);
        notifyListeners();
      }

      print('✅ Prediction cancelled: $predictionId');
    } catch (e) {
      _errorMessage = 'Gagal membatalkan prediksi: $e';
      print('❌ Error cancelling prediction: $e');
    }
  }

  Future<List<GrowthPrediction>> getDuePredictions() async {
    try {
      return await _growthService.getDuePredictions();
    } catch (e) {
      print('❌ Error getting due predictions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getRepetitionStatistics() async {
    try {
      return await _growthService.getRepetitionStatistics();
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return {};
    }
  }

  Future<List<GrowthPrediction>> getPredictionsForTree(
      String dataPohonId) async {
    try {
      return await _growthService.getPredictionsForTree(dataPohonId);
    } catch (e) {
      print('❌ Error getting predictions for tree: $e');
      return [];
    }
  }

  // FIX 4: Fetch data pohon asli dari Firestore
  Future<DataPohon> _getTreeData(String dataPohonId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('data_pohon')
          .doc(dataPohonId)
          .get();

      if (!doc.exists) {
        throw Exception('Data pohon tidak ditemukan: $dataPohonId');
      }

      return DataPohon.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      print('❌ Error getting tree data: $e');
      rethrow;
    }
  }
}