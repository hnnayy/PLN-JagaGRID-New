import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/growth_prediction.dart';
import '../providers/growth_prediction_provider.dart';
import 'repetition_analytics_page.dart';

class RepetitionManagementPage extends StatefulWidget {
  const RepetitionManagementPage({super.key});

  @override
  State<RepetitionManagementPage> createState() => _RepetitionManagementPageState();
}

class _RepetitionManagementPageState extends State<RepetitionManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load data saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrowthPredictionProvider>().loadActivePredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Repetisi Pohon'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RepetitionAnalyticsPage(),
                ),
              );
            },
            tooltip: 'Lihat Analisis',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GrowthPredictionProvider>().loadActivePredictions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _showAutoScheduleDialog(context),
          ),
        ],
      ),
      body: Consumer<GrowthPredictionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadActivePredictions();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final predictions = provider.activePredictions;

          if (predictions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada prediksi pertumbuhan aktif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prediksi akan dibuat otomatis setelah eksekusi pohon',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAutoScheduleDialog(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Auto Schedule Semua Pohon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header dengan statistik
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total Aktif', predictions.length.toString(), Icons.eco),
                    _buildStatCard('Due Date', _getDueCount(predictions).toString(), Icons.warning),
                    _buildStatCard('Tinggi Prioritas', _getHighPriorityCount(predictions).toString(), Icons.priority_high),
                  ],
                ),
              ),

              // List prediksi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = predictions[index];
                    return _buildPredictionCard(prediction);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(GrowthPrediction prediction) {
    final daysUntilDue = prediction.predictedNextExecution.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final priority = prediction.getPriority();

    Color cardColor;
    if (isOverdue) {
      cardColor = Colors.red.shade50;
    } else if (priority == 3) {
      cardColor = Colors.orange.shade50;
    } else if (priority == 2) {
      cardColor = Colors.yellow.shade50;
    } else {
      cardColor = Colors.white;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Pohon ${prediction.dataPohonId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPriorityBadge(priority),
              ],
            ),

            const SizedBox(height: 8),

            // Status dan siklus
            Row(
              children: [
                Text(
                  'Siklus ${prediction.repetitionCycle}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  prediction.getStatusString(),
                  style: TextStyle(
                    color: prediction.status == 1 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Detail pertumbuhan
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Tinggi Saat Ini',
                    '${prediction.lastHeight.round()} cm',
                    Icons.height,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Growth Rate',
                    '${prediction.growthRate.round()} cm/tahun',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Prediksi dan confidence
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Prediksi Eksekusi',
                    _formatDate(prediction.predictedNextExecution),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Confidence',
                    '${(prediction.confidenceLevel * 100).round()}%',
                    Icons.verified,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Alasan prediksi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prediction.predictionReason,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showPredictionDetails(prediction),
                  icon: const Icon(Icons.info),
                  label: const Text('Detail'),
                ),
                if (prediction.status == 1) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _markAsExecuted(prediction),
                    icon: const Icon(Icons.check),
                    label: const Text('Sudah Eksekusi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(int priority) {
    String text;
    Color color;

    switch (priority) {
      case 3:
        text = 'TINGGI';
        color = Colors.red;
        break;
      case 2:
        text = 'SEDANG';
        color = Colors.orange;
        break;
      default:
        text = 'RENDAH';
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAutoScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Schedule Semua Pohon'),
        content: const Text(
          'Fitur ini akan membuat prediksi pertumbuhan untuk semua pohon yang belum memiliki jadwal repetisi. '
          'Apakah Anda yakin ingin melanjutkan?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performAutoSchedule();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _performAutoSchedule() async {
    try {
      await context.read<GrowthPredictionProvider>().autoScheduleAllTrees(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto scheduling selesai!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPredictionDetails(GrowthPrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Prediksi - Pohon ${prediction.dataPohonId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID Pohon', prediction.dataPohonId),
              _buildDetailRow('Siklus Ke', prediction.repetitionCycle.toString()),
              _buildDetailRow('Tinggi Saat Ini', '${prediction.lastHeight.round()} cm'),
              _buildDetailRow('Growth Rate', '${prediction.growthRate.round()} cm/tahun'),
              _buildDetailRow('Batas Aman', '${prediction.safeDistance.round()} m (${(prediction.safeDistance * 100).round()} cm)'),
              _buildDetailRow('Prediksi Eksekusi', _formatDate(prediction.predictedNextExecution)),
              _buildDetailRow('Confidence Level', '${(prediction.confidenceLevel * 100).round()}%'),
              _buildDetailRow('Status', prediction.getStatusString()),
              const SizedBox(height: 16),
              const Text(
                'Alasan Prediksi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(prediction.predictionReason),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _markAsExecuted(GrowthPrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Eksekusi'),
        content: Text(
          'Apakah pohon ${prediction.dataPohonId} sudah dieksekusi? '
          'Tindakan ini akan membuat prediksi pertumbuhan baru untuk siklus berikutnya.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<GrowthPredictionProvider>().markPredictionExecuted(prediction.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prediksi berhasil ditandai sebagai sudah dieksekusi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ya, Sudah Eksekusi'),
          ),
        ],
      ),
    );
  }

  int _getDueCount(List<GrowthPrediction> predictions) {
    return predictions.where((p) => p.isDueForExecution()).length;
  }

  int _getHighPriorityCount(List<GrowthPrediction> predictions) {
    return predictions.where((p) => p.getPriority() >= 2).length;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}