import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/growth_prediction.dart';
import '../../providers/growth_prediction_provider.dart';
import '../../constants/colors.dart';

class RepetitionAnalyticsPage extends StatefulWidget {
  const RepetitionAnalyticsPage({super.key});

  @override
  State<RepetitionAnalyticsPage> createState() => _RepetitionAnalyticsPageState();
}

class _RepetitionAnalyticsPageState extends State<RepetitionAnalyticsPage> {
  // Cache untuk mapping dataPohonId (doc id) -> idPohon (human-friendly)
  final Map<String, String> _idPohonCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrowthPredictionProvider>().loadActivePredictions();
    });
  }

  // Ambil idPohon dari koleksi data_pohon dan cache hasilnya
  Future<String> _getIdPohon(String dataPohonId) async {
    final cached = _idPohonCache[dataPohonId];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final doc = await FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonId).get();
      String idPohon = '';
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          idPohon = (data['id_pohon'] ?? data['idPohon'] ?? '').toString();
        }
      }
      if (idPohon.isEmpty) idPohon = dataPohonId; // fallback
      _idPohonCache[dataPohonId] = idPohon;
      return idPohon;
    } catch (e) {
      // Jika gagal, gunakan fallback
      return dataPohonId;
    }
  }

  // Widget label untuk menampilkan #id pohon dengan FutureBuilder dan cache
  Widget _idPohonLabel(String dataPohonId, {TextStyle? style, double width = 60}) {
    return SizedBox(
      width: width,
      child: FutureBuilder<String>(
        future: _getIdPohon(dataPohonId),
        builder: (context, snapshot) {
          final label = snapshot.hasData ? '#${snapshot.data}' : '...';
          return Text(
            label,
            style: style ?? const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.putihKebiruan,
      appBar: AppBar(
        title: const Text('Analisis Repetisi'),
        backgroundColor: AppColors.tealGelap,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.tealGelap, AppColors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GrowthPredictionProvider>().loadActivePredictions();
            },
          ),
        ],
      ),
      body: Consumer<GrowthPredictionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text('Error: ${provider.errorMessage}'),
            );
          }

          final predictions = provider.activePredictions;

          if (predictions.isEmpty) {
            return const Center(
              child: Text('Tidak ada data untuk dianalisis'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Growth Rate Analysis
                _buildGrowthRateSection(predictions),

                const SizedBox(height: 24),

                // Confidence Analysis
                _buildConfidenceSection(predictions),

                const SizedBox(height: 24),

                // Cycle Analysis
                _buildCycleAnalysisSection(predictions),

                const SizedBox(height: 24),

                // Risk Assessment
                _buildRiskAssessmentSection(predictions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrowthRateSection(List<GrowthPrediction> predictions) {
    final growthRates = predictions.map((p) => p.growthRate).toList();
    final avgGrowthRate = growthRates.reduce((a, b) => a + b) / growthRates.length;
    final maxGrowthRate = growthRates.reduce((a, b) => a > b ? a : b);
    final minGrowthRate = growthRates.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analisis Growth Rate',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGrowthMetric('Rata-rata', avgGrowthRate, Colors.blue),
                    _buildGrowthMetric('Maksimal', maxGrowthRate, Colors.red),
                    _buildGrowthMetric('Minimal', minGrowthRate, Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGrowthRateChart(predictions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthMetric(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.round()} cm/tahun',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthRateChart(List<GrowthPrediction> predictions) {
    // Simple bar chart representation
    final sortedPredictions = predictions.toList()
      ..sort((a, b) => b.growthRate.compareTo(a.growthRate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 Growth Rate Tertinggi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedPredictions.take(5).map((prediction) {
          final percentage = (prediction.growthRate / sortedPredictions.first.growthRate) * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _idPohonLabel(
                  prediction.dataPohonId,
                  style: const TextStyle(fontSize: 12),
                  width: 80,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${prediction.growthRate.round()} cm',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfidenceSection(List<GrowthPrediction> predictions) {
    final confidenceLevels = predictions.map((p) => p.confidenceLevel).toList();
    final avgConfidence = confidenceLevels.reduce((a, b) => a + b) / confidenceLevels.length;

    final highConfidence = predictions.where((p) => p.confidenceLevel >= 0.8).length;
    final mediumConfidence = predictions.where((p) => p.confidenceLevel >= 0.6 && p.confidenceLevel < 0.8).length;
    final lowConfidence = predictions.where((p) => p.confidenceLevel < 0.6).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analisis Confidence Level',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Rata-rata Confidence: ${(avgConfidence * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildConfidenceMetric('Tinggi (≥80%)', highConfidence, Colors.green),
                    _buildConfidenceMetric('Sedang (60-79%)', mediumConfidence, Colors.orange),
                    _buildConfidenceMetric('Rendah (<60%)', lowConfidence, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                _buildConfidenceDistribution(predictions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceMetric(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfidenceDistribution(List<GrowthPrediction> predictions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribusi Confidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...predictions.take(10).map((prediction) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                _idPohonLabel(
                  prediction.dataPohonId,
                  style: const TextStyle(fontSize: 12),
                  width: 80,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: prediction.confidenceLevel,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      prediction.confidenceLevel >= 0.8 ? Colors.green :
                      prediction.confidenceLevel >= 0.6 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(prediction.confidenceLevel * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCycleAnalysisSection(List<GrowthPrediction> predictions) {
    final cycleCounts = <int, int>{};
    for (final prediction in predictions) {
      cycleCounts[prediction.repetitionCycle] = (cycleCounts[prediction.repetitionCycle] ?? 0) + 1;
    }

    final maxCycle = cycleCounts.keys.reduce((a, b) => a > b ? a : b);
    final avgCycle = predictions.map((p) => p.repetitionCycle).reduce((a, b) => a + b) / predictions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analisis Siklus Repetisi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCycleMetric('Rata-rata Siklus', avgCycle.round(), Colors.blue),
                    _buildCycleMetric('Siklus Maksimal', maxCycle, Colors.purple),
                    _buildCycleMetric('Total Siklus', cycleCounts.length, Colors.teal),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCycleDistribution(cycleCounts),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCycleDistribution(Map<int, int> cycleCounts) {
    final sortedCycles = cycleCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribusi Siklus',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedCycles.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Siklus ${entry.key}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value / sortedCycles.map((e) => e.value).reduce((a, b) => a > b ? a : b),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value} pohon',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRiskAssessmentSection(List<GrowthPrediction> predictions) {
    final overduePredictions = predictions.where((p) => p.isDueForExecution()).length;
    final highRiskPredictions = predictions.where((p) => p.getPriority() == 3).length;
    final lowConfidencePredictions = predictions.where((p) => p.confidenceLevel < 0.6).length;

    final riskScore = (overduePredictions + highRiskPredictions + lowConfidencePredictions) / predictions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penilaian Risiko',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Risk Score: ${(riskScore * 100).round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: riskScore > 0.5 ? Colors.red : riskScore > 0.3 ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRiskMetric('Overdue', overduePredictions, Colors.red),
                    _buildRiskMetric('High Risk', highRiskPredictions, Colors.orange),
                    _buildRiskMetric('Low Confidence', lowConfidencePredictions, Colors.yellow),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRiskRecommendations(riskScore),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskMetric(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRiskRecommendations(double riskScore) {
    String recommendation;
    Color color;

    if (riskScore > 0.5) {
      recommendation = 'Risiko tinggi! Perlu tindakan segera untuk pohon-pohon yang overdue dan prioritas tinggi.';
      color = Colors.red;
    } else if (riskScore > 0.3) {
      recommendation = 'Risiko sedang. Perlu monitoring lebih intensif untuk pohon-pohon dengan confidence rendah.';
      color = Colors.orange;
    } else {
      recommendation = 'Risiko rendah. Sistem berjalan dengan baik, tetap lakukan monitoring rutin.';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        recommendation,
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
