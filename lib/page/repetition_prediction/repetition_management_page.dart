import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/growth_prediction.dart';
import '../../providers/growth_prediction_provider.dart';
import 'repetition_analytics_page.dart';
import '../../constants/colors.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../report/eksekusi.dart';
import '../report/riwayat_eksekusi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepetitionManagementPage extends StatefulWidget {
  const RepetitionManagementPage({super.key});

  @override
  State<RepetitionManagementPage> createState() => _RepetitionManagementPageState();
}

class _RepetitionManagementPageState extends State<RepetitionManagementPage> {
  final Map<String, String> _idPohonCache = {};
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
      backgroundColor: AppColors.putihKebiruan,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Manajemen Repetisi Pohon',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.tealGelap,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Mengatur warna ikon back arrow menjadi putih
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
            icon: const Icon(Icons.analytics, color: Colors.white), // Mengatur warna ikon analytics menjadi putih
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
            icon: const Icon(Icons.search, color: Colors.white), // Mengatur warna ikon search menjadi putih
            tooltip: 'Cari prediksi',
            onPressed: () {
              final list = context.read<GrowthPredictionProvider>().activePredictions;
              showSearch(
                context: context,
                delegate: _PredictionSearchDelegate(
                  predictions: list,
                  onGoToEksekusi: _goToEksekusiPage,
                ),
              );
            },
          ),
          // Auto schedule removed as per requirements
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealGelap,
                    ),
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
                  Icon(Icons.eco, size: 64, color: AppColors.tealGelap),
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
                  // Auto Schedule button removed
                ],
              ),
            );
          }

          return Column(
            children: [
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

  Widget _buildPredictionCard(GrowthPrediction prediction) {
    final daysUntilDue = prediction.predictedNextExecution.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final priority = prediction.getPriority();

    Color cardColor;
    if (isOverdue) {
      cardColor = Colors.red.shade50;
    } else if (priority == 3) {
      cardColor = Colors.yellow.shade100;
    } else if (priority == 2) {
      cardColor = Colors.orange.shade50;
    } else {
      cardColor = AppColors.white;
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
                Expanded(child: _buildPohonTitle(prediction.dataPohonId)),
                _buildPriorityBadgeFromDb(prediction.dataPohonId),
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
                    color: prediction.status == 1 ? AppColors.tealGelap : Colors.grey,
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

            const SizedBox(height: 8),

            // Ringkasan riwayat eksekusi (sinkron dengan data)
            _buildExecutionSummary(prediction.dataPohonId),

            const SizedBox(height: 12),

            // Alasan prediksi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prediction.predictionReason,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tealGelap,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => _goToRiwayatEksekusi(prediction.dataPohonId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tealGelap,
                    side: BorderSide(color: AppColors.tealGelap),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Riwayat Eksekusi'),
                ),
                if (prediction.status == 1)
                  ElevatedButton(
                    onPressed: () => _goToEksekusiPage(prediction.dataPohonId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealGelap,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Eksekusi'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bangun judul kartu dengan idPohon (bukan document id), dengan cache untuk mengurangi query
  Widget _buildPohonTitle(String dataPohonDocId) {
    final cached = _idPohonCache[dataPohonDocId];
    if (cached != null) {
      return Text(
        'Pohon $cached',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonDocId).get(),
      builder: (context, snapshot) {
        String idPohon = '';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
          idPohon = (snapshot.data!.data()?['id_pohon'] ?? '').toString();
          if (idPohon.isNotEmpty) {
            _idPohonCache[dataPohonDocId] = idPohon;
          }
        }
        return Text(
          'Pohon ${idPohon.isNotEmpty ? idPohon : dataPohonDocId}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  // Ambil jumlah eksekusi dan tanggal terakhir (sinkron dengan halaman Riwayat - live stream & sort createdDate desc)
  Widget _buildExecutionSummary(String dataPohonId) {
    return StreamBuilder<List<Eksekusi>>(
      stream: FirebaseFirestore.instance
          .collection('eksekusi')
          .where('data_pohon_id', isEqualTo: dataPohonId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Eksekusi.fromMap({
                    ...doc.data(),
                    'id': doc.id,
                  }))
              .toList()
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate))),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 4);
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final eksekusiList = snapshot.data ?? [];
        final count = eksekusiList.length;

        String lastDateStr = '-';
        if (eksekusiList.isNotEmpty) {
          // Tanggal eksekusi ditampilkan sama seperti Riwayat (ambil bagian tanggal saja dari string)
          final parts = eksekusiList.first.tanggalEksekusi.split(' ');
          lastDateStr = parts.isNotEmpty ? parts[0] : '-';
        }

        return Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Jumlah Eksekusi',
                count.toString(),
                Icons.history,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                'Eksekusi Terakhir',
                lastDateStr,
                Icons.event_available,
              ),
            ),
          ],
        );
      },
    );
  }

  // Parser helper removed (now using Eksekusi formatted date directly in summary)

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

  Widget _buildPriorityBadgeFromDb(String dataPohonId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 60,
            child: Center(child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _priorityChip('RENDAH', AppColors.tealGelap);
        }
        final prioritas = (snapshot.data!.data()?['prioritas'] ?? 1) as int;
        switch (prioritas) {
          case 3:
            return _priorityChip('TINGGI', Colors.red);
          case 2:
            return _priorityChip('SEDANG', Colors.orange);
          default:
            return _priorityChip('RENDAH', AppColors.tealGelap);
        }
      },
    );
  }

  Widget _priorityChip(String text, Color color) {
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

  // Auto schedule feature removed

  Future<void> _goToEksekusiPage(String dataPohonId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pohon tidak ditemukan')),
        );
        return;
      }
      final pohon = DataPohon.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EksekusiPage(pohon: pohon)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka halaman eksekusi: $e')),
      );
    }
  }

  Future<void> _goToRiwayatEksekusi(String dataPohonId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pohon tidak ditemukan')),
        );
        return;
      }

      final pohon = DataPohon.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RiwayatEksekusiPage(pohon: pohon)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka riwayat: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _PredictionSearchDelegate extends SearchDelegate<void> {
  _PredictionSearchDelegate({
    required this.predictions,
    required this.onGoToEksekusi,
  });

  final List<GrowthPrediction> predictions;
  final Future<void> Function(String dataPohonId) onGoToEksekusi;

  List<GrowthPrediction> _filter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return predictions;
    return predictions.where((p) {
      final id = p.dataPohonId.toLowerCase();
      final reason = p.predictionReason.toLowerCase();
      final status = p.getStatusString().toLowerCase();
      return id.contains(query) || reason.contains(query) || status.contains(query);
    }).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) {
      return const Center(child: Text('Tidak ada hasil'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = results[index];
        return ListTile(
          leading: const Icon(Icons.eco_outlined),
          title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('data_pohon').doc(p.dataPohonId).get(),
            builder: (context, snap) {
              String idp = p.dataPohonId;
              if (snap.connectionState == ConnectionState.done && snap.hasData && snap.data!.exists) {
                idp = (snap.data!.data()?['id_pohon'] ?? idp).toString();
              }
              return Text('Pohon $idp');
            },
          ),
          subtitle: Text('Siklus ${p.repetitionCycle} • Prediksi ${DateFormat('dd/MM/yyyy').format(p.predictedNextExecution)}'),
          trailing: IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: 'Eksekusi',
            onPressed: () {
              close(context, null);
              onGoToEksekusi(p.dataPohonId);
            },
          ),
          onTap: () {
            close(context, null);
            onGoToEksekusi(p.dataPohonId);
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Use the same UI as suggestions for simplicity
    return buildSuggestions(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
          tooltip: 'Hapus',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}