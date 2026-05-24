import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/growth_prediction.dart';
import '../../models/data_pohon.dart';
import '../../providers/growth_prediction_provider.dart';
import '../../providers/data_pohon_provider.dart';
import '../../providers/tree_growth_provider.dart';
import '../../constants/colors.dart';
import '../report/riwayat_eksekusi.dart';

class RepetitionAnalyticsPage extends StatefulWidget {
  const RepetitionAnalyticsPage({super.key});

  @override
  State<RepetitionAnalyticsPage> createState() =>
      _RepetitionAnalyticsPageState();
}

class _RepetitionAnalyticsPageState extends State<RepetitionAnalyticsPage> {
  final Map<String, String> _idPohonCache = {};
  final Map<String, DataPohon> _dataPohonCache = {};
  bool _cacheLoaded = false;

  int _sessionLevel = 2;
  String _sessionUnit = '';
  String _sessionName = '';

  Stream<List<GrowthPrediction>>? _predictionsStream;

  final ScrollController _scrollRisiko = ScrollController();
  final ScrollController _scrollKritis = ScrollController();
  final ScrollController _scrollJenis = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStream();
      context.read<TreeGrowthProvider>().load();
    });
  }

  @override
  void dispose() {
    _scrollRisiko.dispose();
    _scrollKritis.dispose();
    _scrollJenis.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionLevel = prefs.getInt('session_level') ?? 2;
      _sessionUnit = prefs.getString('session_unit') ?? '';
      _sessionName = prefs.getString('session_name') ?? '';
    });
  }

  void _initStream() {
    setState(() {
      _predictionsStream =
          context.read<GrowthPredictionProvider>().watchActivePredictions();
    });
  }

  Future<void> _preloadAllIdPohon(List<GrowthPrediction> predictions) async {
    final ids = predictions
        .map((p) => p.dataPohonId)
        .toSet()
        .where((id) => !_idPohonCache.containsKey(id))
        .toList();

    if (ids.isEmpty) {
      if (mounted) setState(() => _cacheLoaded = true);
      return;
    }

    for (var i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, min(i + 10, ids.length));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('data_pohon')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          _idPohonCache[doc.id] =
              (doc.data()['id_pohon'] ?? doc.id).toString();
          try {
            _dataPohonCache[doc.id] =
                DataPohon.fromMap({...doc.data(), 'id': doc.id});
          } catch (_) {}
        }
        for (final id in batch) {
          _idPohonCache.putIfAbsent(id, () => id);
        }
      } catch (_) {
        for (final id in batch) {
          _idPohonCache.putIfAbsent(id, () => id);
        }
      }
    }

    if (mounted) setState(() => _cacheLoaded = true);
  }

  String _resolveIdPohon(String dataPohonId) =>
      _idPohonCache[dataPohonId] ?? dataPohonId;

  void _bukaRiwayatEksekusi(String dataPohonId) {
    final pohon = _dataPohonCache[dataPohonId];
    if (pohon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pohon tidak ditemukan')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RiwayatEksekusiPage(pohon: pohon)),
    );
  }

  Future<void> _refreshAll() async {
    try {
      setState(() {
        _cacheLoaded = false;
        _idPohonCache.clear();
        _dataPohonCache.clear();
      });
      _initStream();
      context.read<TreeGrowthProvider>().load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data. Periksa koneksi internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            'Analisis Pertumbuhan Pohon',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.tealGelap,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.tealGelap, AppColors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _predictionsStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<GrowthPrediction>>(
              stream: _predictionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshAll,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealGelap),
                          child: const Text('Coba Lagi',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final predictions = snapshot.data ?? [];

                if (!_cacheLoaded && predictions.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _preloadAllIdPohon(predictions);
                  });
                }

                if (predictions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: AppColors.tealGelap,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.eco,
                                  size: 64, color: AppColors.tealGelap),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada data pertumbuhan pohon',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data akan tersedia setelah eksekusi pohon dilakukan',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.tealGelap,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRealtimeBadge(),
                        const SizedBox(height: 12),
                        _buildRingkasan(predictions),
                        const SizedBox(height: 20),
                        if (_sessionLevel == 1) ...[
                          _buildBreakdownULP(predictions),
                          const SizedBox(height: 20),
                        ],
                        _buildPenilaianRisiko(predictions),
                        const SizedBox(height: 20),
                        _buildPohonKritis(predictions),
                        const SizedBox(height: 20),
                        _buildPertumbuhanJenisPohon(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRealtimeBadge() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Data diperbarui otomatis secara realtime',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildRingkasan(List<GrowthPrediction> predictions) {
    final total = predictions.length;
    final overdue = predictions.where((p) => p.isDueForExecution()).length;
    final due7Hari = predictions.where((p) {
      final sisa = p.predictedNextExecution.difference(DateTime.now()).inDays;
      return sisa >= 0 && sisa <= 7;
    }).length;
    final belumEksekusi =
        predictions.where((p) => p.id.startsWith('synthetic:')).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tealGelap.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.tealGelap.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business, size: 14, color: AppColors.tealGelap),
              const SizedBox(width: 6),
              Text(
                _sessionLevel == 1
                    ? '$_sessionUnit — semua ULP'
                    : '$_sessionUnit${_sessionName.isNotEmpty ? ' • $_sessionName' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tealGelap,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('Ringkasan Umum', Icons.summarize),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _buildMetricCard(
                'Total Pohon', total.toString(), Icons.park, AppColors.tealGelap),
            _buildMetricCard(
                'Overdue', overdue.toString(), Icons.warning_amber, Colors.red),
            _buildMetricCard('Due 7 Hari', due7Hari.toString(),
                Icons.calendar_today, Colors.orange),
            _buildMetricCard('Belum Eksekusi', belumEksekusi.toString(),
                Icons.hourglass_empty, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownULP(List<GrowthPrediction> predictions) {
    final pohonList = context.read<DataPohonProvider>().pohonList;

    final Map<String, List<String>> ulpToPohonIds = {};
    for (final pohon in pohonList) {
      final ulp = pohon.ulp.isNotEmpty ? pohon.ulp : 'Tidak diketahui';
      ulpToPohonIds.putIfAbsent(ulp, () => []).add(pohon.id);
    }

    final ulpStats = <String, Map<String, int>>{};
    for (final entry in ulpToPohonIds.entries) {
      final ids = entry.value.toSet();
      final ulpPredictions =
          predictions.where((p) => ids.contains(p.dataPohonId)).toList();
      ulpStats[entry.key] = {
        'total': ulpPredictions.length,
        'overdue': ulpPredictions.where((p) => p.isDueForExecution()).length,
      };
    }

    final sortedUlp = ulpStats.entries.toList()
      ..sort((a, b) =>
          (b.value['overdue'] ?? 0).compareTo(a.value['overdue'] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kondisi per ULP', Icons.map),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: sortedUlp.asMap().entries.map((entry) {
              final idx = entry.key;
              final ulpName = entry.value.key;
              final stats = entry.value.value;
              final total = stats['total'] ?? 0;
              final overdue = stats['overdue'] ?? 0;
              final isLast = idx == sortedUlp.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.tealGelap.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on,
                          size: 16, color: AppColors.tealGelap),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(ulpName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text('$total pohon',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: overdue > 0
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        overdue > 0 ? '$overdue overdue' : 'Aman',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: overdue > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPenilaianRisiko(List<GrowthPrediction> predictions) {
    final riskyCount = predictions
        .where((p) =>
            p.isDueForExecution() ||
            p.getPriority() == 3 ||
            p.confidenceLevel < 0.6)
        .length;
    final riskScore =
        predictions.isEmpty ? 0.0 : riskyCount / predictions.length;

    final riskyPredictions = predictions
        .where((p) =>
            p.isDueForExecution() ||
            p.getPriority() == 3 ||
            p.getPriority() == 2)
        .toList()
      ..sort((a, b) => b.getPriority().compareTo(a.getPriority()));

    Color riskColor;
    String riskLabel;
    if (riskScore > 0.5) {
      riskColor = Colors.red;
      riskLabel = 'Risiko Tinggi — Perlu tindakan segera';
    } else if (riskScore > 0.3) {
      riskColor = Colors.orange;
      riskLabel = 'Risiko Sedang — Perlu monitoring intensif';
    } else {
      riskColor = Colors.green;
      riskLabel = 'Risiko Rendah — Kondisi terkendali';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Penilaian Risiko Pohon', Icons.shield),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Risiko dihitung berdasarkan 3 kondisi: pohon yang sudah melewati jadwal eksekusi (overdue), pohon dengan sisa waktu ≤ 20% dari total siklus pertumbuhan, dan pohon dengan tingkat kepercayaan prediksi di bawah 60%.',
            style: TextStyle(fontSize: 11, color: AppColors.tealGelap),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${(riskScore * 100).round()}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: riskScore,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$riskyCount dari ${predictions.length} pohon berisiko',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
              if (riskyPredictions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Detail Pohon Berisiko',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${riskyPredictions.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk pohon untuk melihat riwayat eksekusi',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: Scrollbar(
                    controller: _scrollRisiko,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollRisiko,
                      physics: const BouncingScrollPhysics(),
                      itemCount: riskyPredictions.length,
                      itemBuilder: (context, index) {
                        return _buildRisikoItem(riskyPredictions[index]);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRisikoItem(GrowthPrediction prediction) {
    final priority = prediction.getPriority();
    final isOverdue = prediction.isDueForExecution();
    final totalHari = prediction.predictedNextExecution
        .difference(prediction.lastExecutionDate)
        .inDays;
    final sisaHari = prediction.predictedNextExecution
        .difference(DateTime.now())
        .inDays;
    final persenSisa =
        totalHari > 0 ? (sisaHari / totalHari * 100).round() : 0;

    Color badgeColor;
    String badgeText;
    if (priority == 3) {
      badgeColor = Colors.red;
      badgeText = 'TINGGI';
    } else if (priority == 2) {
      badgeColor = Colors.orange;
      badgeText = 'SEDANG';
    } else {
      badgeColor = AppColors.tealGelap;
      badgeText = 'RENDAH';
    }

    String alasan;
    if (isOverdue) {
      final hariLewat = sisaHari.abs();
      alasan = 'Sudah melewati jadwal eksekusi $hariLewat hari yang lalu';
    } else if (priority == 3) {
      alasan =
          'Sisa waktu hanya $persenSisa% dari total siklus pertumbuhan — mendekati batas kritis';
    } else {
      alasan = 'Sisa waktu $persenSisa% dari total siklus — perlu dipantau';
    }

    if (prediction.confidenceLevel < 0.6) {
      alasan +=
          ' • Tingkat kepercayaan prediksi rendah (${(prediction.confidenceLevel * 100).round()}%)';
    }

    final idPohon = _resolveIdPohon(prediction.dataPohonId);
    final canNavigate = _dataPohonCache.containsKey(prediction.dataPohonId);

    return GestureDetector(
      onTap: () => _bukaRiwayatEksekusi(prediction.dataPohonId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.park, size: 18, color: badgeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pohon $idPohon',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alasan,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (canNavigate) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPohonKritis(List<GrowthPrediction> predictions) {
    const double batasPLN = 780.0;

    final pohonKritis = predictions
        .where((p) => p.growthRate > 0 && p.lastHeight > 0)
        .map((p) {
          final persen = (p.lastHeight / batasPLN).clamp(0.0, 1.0);
          final sisaCm = batasPLN - p.lastHeight;
          // ✅ FIX: hapus sisaTahun, pakai getFormattedTimeUntilExecution()
          return {
            'prediction': p,
            'persen': persen,
            'sisaCm': sisaCm,
          };
        })
        .toList()
      ..sort((a, b) =>
          (b['persen'] as double).compareTo(a['persen'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pohon Paling Kritis', Icons.electric_bolt),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Batas aman PLN = tinggi tiang JTM (10.8m) − jarak aman (3m) = 7.8m = 780cm. Semakin tinggi persentasenya, semakin mendesak pohon perlu dieksekusi.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: pohonKritis.isEmpty
              ? const Center(
                  child: Text('Tidak ada data tinggi pohon',
                      style: TextStyle(color: Colors.grey)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Diurutkan dari yang paling mendekati batas aman',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pohonKritis.length} pohon',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.touch_app,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Ketuk pohon untuk melihat riwayat eksekusi',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: Scrollbar(
                        controller: _scrollKritis,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollKritis,
                          physics: const BouncingScrollPhysics(),
                          itemCount: pohonKritis.length,
                          itemBuilder: (context, index) {
                            final item = pohonKritis[index];
                            final p = item['prediction'] as GrowthPrediction;
                            final persen = item['persen'] as double;
                            final sisaCm = item['sisaCm'] as double;

                            Color barColor;
                            if (persen >= 0.9) {
                              barColor = Colors.red;
                            } else if (persen >= 0.7) {
                              barColor = Colors.orange;
                            } else {
                              barColor = Colors.green;
                            }

                            final idPohon = _resolveIdPohon(p.dataPohonId);
                            final canNavigate =
                                _dataPohonCache.containsKey(p.dataPohonId);

                            return GestureDetector(
                              onTap: () => _bukaRiwayatEksekusi(p.dataPohonId),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: barColor.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: barColor.withOpacity(0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pohon $idPohon',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: barColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${(persen * 100).round()}%',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: barColor),
                                          ),
                                        ),
                                        if (canNavigate) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.chevron_right,
                                              size: 16,
                                              color: Colors.grey.shade400),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // ✅ FIX: pakai getFormattedTimeUntilExecution()
                                    Text(
                                      'Tinggi: ${p.lastHeight.round()} cm • Sisa: ${sisaCm.round()} cm lagi • ${p.getFormattedTimeUntilExecution()}',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: persen,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                barColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPertumbuhanJenisPohon() {
    return Consumer<TreeGrowthProvider>(
      builder: (context, treeGrowthProvider, child) {
        final items = treeGrowthProvider.items;

        if (treeGrowthProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Pertumbuhan per Jenis Pohon', Icons.forest),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text('Belum ada data jenis pohon',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          );
        }

        final sorted = [...items]
          ..sort((a, b) => b.growthRate.compareTo(a.growthRate));
        final maxRate = sorted.first.growthRate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pertumbuhan per Jenis Pohon', Icons.forest),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Data pertumbuhan dari master jenis pohon yang terdaftar di sistem. Digunakan sebagai acuan dalam menghitung prediksi jadwal eksekusi.',
                style: TextStyle(fontSize: 11, color: Colors.green.shade800),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Diurutkan dari laju pertumbuhan tertinggi',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${sorted.length} jenis',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 250,
                    child: Scrollbar(
                      controller: _scrollJenis,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollJenis,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final item = sorted[index];
                          final persen =
                              maxRate > 0 ? item.growthRate / maxRate : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: persen,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.tealGelap),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  // ✅ FIX: cm/thn → cm/tahun
                                  child: Text(
                                    '${item.growthRate.toStringAsFixed(0)} cm/tahun',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.tealGelap),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.tealGelap,
          ),
        ),
      ],
    );
  }
}