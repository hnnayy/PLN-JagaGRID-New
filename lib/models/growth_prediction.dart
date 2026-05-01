import 'package:cloud_firestore/cloud_firestore.dart';

class GrowthPrediction {
  final String id;
  final String dataPohonId;
  final DateTime lastExecutionDate;
  final double lastHeight; // Tinggi setelah eksekusi terakhir
  final double growthRate; // cm per tahun
  final double safeDistance; // 3 meter untuk jaringan PLN
  final DateTime predictedNextExecution;
  final String predictionReason;
  final double confidenceLevel; // 0.0 - 1.0
  final int repetitionCycle;
  final DateTime createdDate;
  final int status; // 1=active, 2=completed (pohon sudah tidak ada), 3=cancelled
  final int executionType; // 1=tebang pangkas, 2=tebang habis
  final String lastExecutionNotes; // Catatan eksekusi terakhir

  GrowthPrediction({
    required this.id,
    required this.dataPohonId,
    required this.lastExecutionDate,
    required this.lastHeight,
    required this.growthRate,
    required this.safeDistance,
    required this.predictedNextExecution,
    required this.predictionReason,
    required this.confidenceLevel,
    required this.repetitionCycle,
    required this.createdDate,
    this.status = 1,
    this.executionType = 1,
    this.lastExecutionNotes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_pohon_id': dataPohonId,
      'last_execution_date': Timestamp.fromDate(lastExecutionDate),
      'last_height': lastHeight,
      'growth_rate': growthRate,
      'safe_distance': safeDistance,
      'predicted_next_execution': Timestamp.fromDate(predictedNextExecution),
      'prediction_reason': predictionReason,
      'confidence_level': confidenceLevel,
      'repetition_cycle': repetitionCycle,
      'created_date': Timestamp.fromDate(createdDate),
      'status': status,
      'execution_type': executionType,
      'last_execution_notes': lastExecutionNotes,
    };
  }

  factory GrowthPrediction.fromMap(Map<String, dynamic> map, String documentId) {
    return GrowthPrediction(
      id: documentId,
      dataPohonId: map['data_pohon_id'] ?? '',
      lastExecutionDate: (map['last_execution_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastHeight: (map['last_height'] as num?)?.toDouble() ?? 0.0,
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      safeDistance: (map['safe_distance'] as num?)?.toDouble() ?? 3.0,
      predictedNextExecution: (map['predicted_next_execution'] as Timestamp?)?.toDate() ?? DateTime.now(),
      predictionReason: map['prediction_reason'] ?? '',
      confidenceLevel: (map['confidence_level'] as num?)?.toDouble() ?? 0.0,
      repetitionCycle: map['repetition_cycle'] ?? 0,
      createdDate: (map['created_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 1,
      executionType: map['execution_type'] ?? 1,
      lastExecutionNotes: map['last_execution_notes'] ?? '',
    );
  }

  static GrowthPrediction calculateNextExecution({
    required String dataPohonId,
    required DateTime lastExecutionDate,
    required double lastHeight,
    required double growthRate,
    required int repetitionCycle,
    double safeDistance = 3.0,
    int executionType = 1,
    String lastExecutionNotes = '',
  }) {
    double effectiveHeight = lastHeight;
    double effectiveGrowthRate = growthRate;

    // Tebang pangkas: pakai tinggi setelah pangkas dan growth rate normal
    // Tebang habis: ditangani di service, tidak sampai sini
    effectiveHeight = lastHeight;
    effectiveGrowthRate = growthRate;

    // FIX 1: Batas aman = tinggi tiang JTM minimum (10.8m) - jarak aman (3m)
    // = 7.8 meter = 780 cm dari tanah
    // Bukan safeDistance * 100 (yang menghasilkan 300 cm = 3 meter, salah!)
    const double tiangJTM = 10.8; // meter, nilai minimum tiang JTM PLN
    final maxSafeHeight = (tiangJTM - safeDistance) * 100; // = 780 cm

    final remainingGrowth = maxSafeHeight - effectiveHeight;

    // FIX 2: Jika pohon sudah melewati batas aman (remainingGrowth <= 0)
    // jadwalkan eksekusi HARI INI, bukan paksa 50 cm lagi
    if (remainingGrowth <= 0) {
      return GrowthPrediction(
        id: '',
        dataPohonId: dataPohonId,
        lastExecutionDate: lastExecutionDate,
        lastHeight: effectiveHeight,
        growthRate: effectiveGrowthRate,
        safeDistance: safeDistance,
        predictedNextExecution: DateTime.now(), // jadwal hari ini
        predictionReason: 'Pohon dengan tinggi ${effectiveHeight.round()}cm telah melewati '
            'batas aman PLN ${maxSafeHeight.round()}cm (${tiangJTM}m - ${safeDistance}m). '
            'Eksekusi harus dilakukan SEGERA.',
        confidenceLevel: 1.0, // confidence tinggi karena sudah pasti berbahaya
        repetitionCycle: repetitionCycle,
        createdDate: DateTime.now(),
        executionType: executionType,
        lastExecutionNotes: lastExecutionNotes,
      );
    }

    // Hitung waktu yang dibutuhkan untuk mencapai batas aman
    final yearsToNextExecution = remainingGrowth / effectiveGrowthRate;

    // Hitung tanggal prediksi
    final predictedDate = lastExecutionDate.add(
      Duration(days: (yearsToNextExecution * 365).round()),
    );

    final confidenceLevel = _calculateConfidenceLevel(
      repetitionCycle,
      yearsToNextExecution,
      executionType,
    );

    final reason = _generatePredictionReason(
      effectiveHeight,
      effectiveGrowthRate,
      yearsToNextExecution,
      safeDistance,
      executionType,
      maxSafeHeight,
    );

    return GrowthPrediction(
      id: '',
      dataPohonId: dataPohonId,
      lastExecutionDate: lastExecutionDate,
      lastHeight: effectiveHeight,
      growthRate: effectiveGrowthRate,
      safeDistance: safeDistance,
      predictedNextExecution: predictedDate,
      predictionReason: reason,
      confidenceLevel: confidenceLevel,
      repetitionCycle: repetitionCycle,
      createdDate: DateTime.now(),
      executionType: executionType,
      lastExecutionNotes: lastExecutionNotes,
    );
  }

  static double _calculateConfidenceLevel(
    int repetitionCycle,
    double yearsToExecution,
    int executionType,
  ) {
    double baseConfidence = 0.8;

    if (repetitionCycle <= 1) {
      baseConfidence -= 0.2;
    }

    if (yearsToExecution > 5) {
      baseConfidence -= 0.1;
    }

    if (repetitionCycle > 3) {
      baseConfidence += 0.1;
    }

    if (executionType == 2) {
      baseConfidence -= 0.1;
    } else {
      baseConfidence += 0.05;
    }

    return baseConfidence.clamp(0.0, 1.0);
  }

  static String _generatePredictionReason(
    double lastHeight,
    double growthRate,
    double yearsToExecution,
    double safeDistance,
    int executionType,
    double maxSafeHeight,
  ) {
    final predictedHeight = lastHeight + (growthRate * yearsToExecution);
    String executionTypeText = executionType == 1 ? 'pangkas' : 'habis';

    return 'Pohon dengan tinggi ${lastHeight.round()}cm dan growth rate ${growthRate.round()}cm/tahun '
        'akan mencapai batas aman PLN ${maxSafeHeight.round()}cm '
        '(tinggi tiang 10.8m - jarak aman ${safeDistance}m) '
        'dalam ${yearsToExecution.toStringAsFixed(1)} tahun. '
        'Prediksi penebangan $executionTypeText berikutnya: '
        '${yearsToExecution < 1 ? "kurang dari 1 tahun" : "${yearsToExecution.round()} tahun"} lagi.';
  }

  bool isDueForExecution() {
    return DateTime.now().isAfter(predictedNextExecution) && status == 1;
  }

  String getStatusString() {
    switch (status) {
      case 1: return 'Aktif - Menunggu Eksekusi';
      case 2: return 'Selesai - Pohon Sudah Ditebang Habis';
      case 3: return 'Dibatalkan';
      default: return 'Unknown';
    }
  }

  String getExecutionTypeString() {
    switch (executionType) {
      case 1: return 'Tebang Pangkas';
      case 2: return 'Tebang Habis';
      default: return 'Unknown';
    }
  }

  // FIX 3: Sudah benar — prioritas pakai persentase siklus, bukan hardcode 30 hari
  // Otomatis menyesuaikan per jenis pohon (bambu vs jati vs kelapa dll)
  int getPriority() {
    final total = predictedNextExecution.difference(lastExecutionDate).inDays;
    final remaining = predictedNextExecution.difference(DateTime.now()).inDays;

    // Sudah lewat jadwal → TINGGI
    if (remaining < 0) return 3;

    // Hindari division by zero
    if (total <= 0) return 1;

    // ≤ 20% sisa waktu → TINGGI
    if (remaining <= total * 0.2) return 3;

    // ≤ 50% sisa waktu → SEDANG
    if (remaining <= total * 0.5) return 2;

    // > 50% sisa waktu → RENDAH
    return 1;
  }

  GrowthPrediction copyWith({
    String? id,
    String? dataPohonId,
    DateTime? lastExecutionDate,
    double? lastHeight,
    double? growthRate,
    double? safeDistance,
    DateTime? predictedNextExecution,
    String? predictionReason,
    double? confidenceLevel,
    int? repetitionCycle,
    DateTime? createdDate,
    int? status,
    int? executionType,
    String? lastExecutionNotes,
  }) {
    return GrowthPrediction(
      id: id ?? this.id,
      dataPohonId: dataPohonId ?? this.dataPohonId,
      lastExecutionDate: lastExecutionDate ?? this.lastExecutionDate,
      lastHeight: lastHeight ?? this.lastHeight,
      growthRate: growthRate ?? this.growthRate,
      safeDistance: safeDistance ?? this.safeDistance,
      predictedNextExecution: predictedNextExecution ?? this.predictedNextExecution,
      predictionReason: predictionReason ?? this.predictionReason,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      repetitionCycle: repetitionCycle ?? this.repetitionCycle,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      executionType: executionType ?? this.executionType,
      lastExecutionNotes: lastExecutionNotes ?? this.lastExecutionNotes,
    );
  }
}