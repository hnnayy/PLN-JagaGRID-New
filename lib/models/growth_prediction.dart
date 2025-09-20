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
    this.executionType = 1, // Default: tebang pangkas
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

  // Method untuk menghitung prediksi pertumbuhan
  static GrowthPrediction calculateNextExecution({
    required String dataPohonId,
    required DateTime lastExecutionDate,
    required double lastHeight,
    required double growthRate,
    required int repetitionCycle,
    double safeDistance = 3.0, // 3 meter untuk PLN
    int executionType = 1, // 1=pangkas, 2=habis
    String lastExecutionNotes = '',
  }) {
    // Logika berbeda berdasarkan tipe eksekusi
    double effectiveHeight = lastHeight;
    double effectiveGrowthRate = growthRate;

    if (executionType == 2) { // Tebang Habis
      // Jika tebang habis, tinggi = 0, tapi pohon akan tumbuh lagi dari akar
      effectiveHeight = 0.0;
      // Growth rate untuk pohon baru lebih tinggi karena regenerasi
      effectiveGrowthRate = growthRate * 1.5; // 50% lebih cepat untuk regenerasi
    } else { // Tebang Pangkas
      // Tinggi cabang yang tersisa setelah pangkas
      effectiveHeight = lastHeight;
      effectiveGrowthRate = growthRate; // Normal growth rate untuk cabang
    }

    // Hitung waktu yang dibutuhkan untuk mencapai batas aman
    // Tinggi maksimal aman = safeDistance (3 meter = 300 cm)
    final maxSafeHeight = safeDistance * 100; // convert to cm
    final remainingGrowth = maxSafeHeight - effectiveHeight;

    // Pastikan remaining growth tidak negatif
    final actualRemainingGrowth = remainingGrowth > 0 ? remainingGrowth : 50.0; // Minimal 50cm

    // Hitung waktu dalam tahun
    final yearsToNextExecution = actualRemainingGrowth / effectiveGrowthRate;

    // Hitung tanggal prediksi
    final predictedDate = lastExecutionDate.add(
      Duration(days: (yearsToNextExecution * 365).round())
    );

    // Hitung confidence level berdasarkan siklus repetisi dan tipe eksekusi
    final confidenceLevel = _calculateConfidenceLevel(repetitionCycle, yearsToNextExecution, executionType);

    // Buat alasan prediksi
    final reason = _generatePredictionReason(
      effectiveHeight,
      effectiveGrowthRate,
      yearsToNextExecution,
      safeDistance,
      executionType
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

  static double _calculateConfidenceLevel(int repetitionCycle, double yearsToExecution, int executionType) {
    // Confidence level berdasarkan siklus, waktu prediksi, dan tipe eksekusi
    double baseConfidence = 0.8; // Base confidence 80%

    // Kurangi confidence untuk siklus 0/1 (kurang data historis)
    if (repetitionCycle <= 1) {
      baseConfidence -= 0.2;
    }

    // Kurangi confidence untuk prediksi yang terlalu jauh (> 5 tahun)
    if (yearsToExecution > 5) {
      baseConfidence -= 0.1;
    }

    // Tingkatkan confidence untuk siklus yang lebih banyak
    if (repetitionCycle > 3) {
      baseConfidence += 0.1;
    }

    // Confidence berbeda untuk tebang habis vs pangkas
    if (executionType == 2) { // Tebang Habis
      // Lebih sulit diprediksi karena regenerasi pohon baru
      baseConfidence -= 0.1;
    } else { // Tebang Pangkas
      // Lebih predictable karena pertumbuhan cabang yang tersisa
      baseConfidence += 0.05;
    }

    return baseConfidence.clamp(0.0, 1.0);
  }

  static String _generatePredictionReason(
    double lastHeight,
    double growthRate,
    double yearsToExecution,
    double safeDistance,
    int executionType
  ) {
    final maxSafeHeight = safeDistance * 100; // convert to cm
    final predictedHeight = lastHeight + (growthRate * yearsToExecution);

    String executionTypeText = executionType == 1 ? 'pangkas' : 'habis';
    String heightDescription = '';

    if (executionType == 2) { // Tebang Habis
      heightDescription = 'Pohon telah ditebang habis (tinggi = 0cm). ';
      heightDescription += 'Prediksi pertumbuhan pohon regenerasi ';
    } else { // Tebang Pangkas
      heightDescription = 'Cabang tersisa setelah pangkas ${lastHeight.round()}cm. ';
    }

    return 'Pohon dengan tinggi ${lastHeight.round()}cm dan growth rate ${growthRate.round()}cm/tahun '
           '${heightDescription}'
           'akan mencapai tinggi ${predictedHeight.round()}cm dalam ${yearsToExecution.toStringAsFixed(1)} tahun. '
           'Batas aman PLN adalah ${maxSafeHeight.round()}cm (${safeDistance}m). '
           'Prediksi penebangan $executionTypeText berikutnya: ${yearsToExecution < 1 ? "kurang dari 1 tahun" : "${yearsToExecution.round()} tahun"} lagi.';
  }

  // Method untuk mengecek apakah sudah waktunya eksekusi
  bool isDueForExecution() {
    return DateTime.now().isAfter(predictedNextExecution) && status == 1;
  }

  // Method untuk mendapatkan status dalam bentuk string
  String getStatusString() {
    switch (status) {
      case 1: return 'Aktif - Menunggu Eksekusi';
      case 2: return 'Selesai - Pohon Sudah Ditebang Habis';
      case 3: return 'Dibatalkan';
      default: return 'Unknown';
    }
  }

  // Method untuk mendapatkan tipe eksekusi dalam bentuk string
  String getExecutionTypeString() {
    switch (executionType) {
      case 1: return 'Tebang Pangkas';
      case 2: return 'Tebang Habis';
      default: return 'Unknown';
    }
  }

  // Method untuk mendapatkan prioritas berdasarkan confidence dan waktu tersisa
  int getPriority() {
    final daysUntilDue = predictedNextExecution.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) return 3; // Sudah lewat deadline - prioritas tinggi
    if (daysUntilDue <= 30) return 2; // Kurang dari 1 bulan - prioritas sedang
    return 1; // Masih lama - prioritas rendah
  }

  // Method untuk membuat copy dengan field tertentu yang diubah
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