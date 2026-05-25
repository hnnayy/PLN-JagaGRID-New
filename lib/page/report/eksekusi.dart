import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/data_pohon.dart';
import '../../models/eksekusi.dart';
import '../../providers/eksekusi_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/growth_prediction.dart';

class EksekusiPage extends StatefulWidget {
  final DataPohon pohon;

  const EksekusiPage({super.key, required this.pohon});

  @override
  _EksekusiPageState createState() => _EksekusiPageState();
}

class _EksekusiPageState extends State<EksekusiPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAction = 'Tebang Pangkas';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _diameterController =
      TextEditingController(text: '200');
  final TextEditingController _dateController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  DateTime? _latestPlannedDate;
  DateTime? _selectedDate;
  DateTime? _nextPrediction;
  bool _accessChecked = false;
  bool _isAllowed = true;
  bool _isLoadingDate = true;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.pohon.tujuanPenjadwalan == 1
        ? 'Tebang Pangkas'
        : widget.pohon.tujuanPenjadwalan == 2
            ? 'Tebang Habis'
            : 'Tebang Pangkas';
    _prefillExecutionDate();
    _checkAccess();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _diameterController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 2;
      final sessionUnit =
          (prefs.getString('session_unit') ?? '').trim().toUpperCase();
      bool allowed = true;
      if (level == 2) {
        allowed = (widget.pohon.up3.trim().toUpperCase() == sessionUnit ||
            widget.pohon.ulp.trim().toUpperCase() == sessionUnit);
      }
      setState(() {
        _isAllowed = allowed;
        _accessChecked = true;
      });
      if (!allowed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorAlert(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.orange,
            title: 'Akses Ditolak',
            message: 'Pohon ini tidak termasuk dalam unit kerja Anda.',
            onClose: () => Navigator.of(context).maybePop(),
          );
        });
      }
    } catch (_) {
      setState(() {
        _isAllowed = true;
        _accessChecked = true;
      });
    }
  }

  Future<void> _prefillExecutionDate() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('growth_predictions')
          .where('data_pohon_id', isEqualTo: widget.pohon.id)
          .where('status', isEqualTo: 1)
          .get();

      DateTime planned;
      if (snap.docs.isEmpty) {
        planned = widget.pohon.scheduleDate;
      } else {
        final preds = snap.docs
            .map((d) => GrowthPrediction.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
        planned = preds.first.predictedNextExecution;
      }

      setState(() {
        _latestPlannedDate = planned;
        _selectedDate = planned;
        _nextPrediction = planned;
        _dateController.text = _formatDisplay(planned);
        _isLoadingDate = false;
      });
    } catch (_) {
      setState(() {
        _latestPlannedDate = widget.pohon.scheduleDate;
        _selectedDate = widget.pohon.scheduleDate;
        _nextPrediction = widget.pohon.scheduleDate;
        _dateController.text = _formatDisplay(widget.pohon.scheduleDate);
        _isLoadingDate = false;
      });
    }
  }

  /// Format tampilan di field: DD/MM/YYYY
  String _formatDisplay(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format untuk disimpan: DD/MM/YYYY HH:mm WITA
  /// Tanggal dari user, jam dari waktu aktual saat simpan
  String _formatForSave(DateTime date) {
    final nowWita = DateTime.now().toUtc().add(const Duration(hours: 8));
    final timeStr = DateFormat('HH:mm').format(nowWita);
    return '${DateFormat('dd/MM/yyyy').format(date)} $timeStr WITA';
  }

  // ── Date Picker ──
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF125E72),
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF125E72),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDisplay(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Sumber Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: Color(0xFF125E72)),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF125E72)),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════
  // ALERT HELPERS
  // ════════════════════════════════════════════════

  void _showErrorAlert({
    IconData icon = Icons.cancel_rounded,
    Color iconColor = Colors.red,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onClose?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tutup',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAlert() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF125E72).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF125E72), size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Eksekusi Berhasil!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data eksekusi berhasil disimpan.\nNotifikasi telah dikirim.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF125E72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Klasifikasi error → pesan human-friendly
  String _humanError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('unauthenticated') ||
        msg.contains('permission-denied') ||
        msg.contains('session')) {
      return 'Sesi login Anda telah habis.\nSilakan login ulang untuk melanjutkan.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('host lookup')) {
      return 'Koneksi internet bermasalah.\nPastikan Anda terhubung ke internet lalu coba lagi.';
    }
    if (msg.contains('imagekit') ||
        msg.contains('upload') ||
        msg.contains('statuscode')) {
      return 'Gagal mengunggah foto.\nPeriksa koneksi internet atau coba ganti foto.';
    }
    if (msg.contains('image file not found') ||
        msg.contains('foto')) {
      return 'File foto tidak ditemukan.\nCoba ambil foto ulang.';
    }
    if (msg.contains('invalid datapohonid') ||
        msg.contains('no matching')) {
      return 'Data pohon tidak ditemukan.\nCoba muat ulang halaman ini.';
    }
    if (msg.contains('firestore') ||
        msg.contains('cloud') ||
        msg.contains('unavailable')) {
      return 'Server sedang tidak dapat dijangkau.\nCoba beberapa saat lagi.';
    }

    return 'Data gagal tersimpan.\nCoba lagi atau hubungi administrator jika masalah berlanjut.';
  }

  Future<void> _saveEksekusi() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Validasi foto ──
    if (_selectedImage == null) {
      _showErrorAlert(
        icon: Icons.photo_camera_outlined,
        iconColor: Colors.orange,
        title: 'Foto Belum Dipilih',
        message:
            'Foto setelah eksekusi wajib dilampirkan.\nSilakan ambil atau pilih foto terlebih dahulu.',
      );
      return;
    }

    // ── Validasi tanggal ──
    if (_selectedDate == null) {
      _showErrorAlert(
        icon: Icons.calendar_today_outlined,
        iconColor: Colors.orange,
        title: 'Tanggal Belum Dipilih',
        message: 'Tanggal eksekusi wajib diisi.\nSilakan pilih tanggal eksekusi.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tanggal dari user pilih, jam dari waktu aktual WITA saat simpan
      final formattedTanggalEksekusi = _formatForSave(_selectedDate!);

      final prefs = await SharedPreferences.getInstance();
      final creatorId = prefs.getString('session_id') ?? '';

      // Cek sesi login
      if (creatorId.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorAlert(
          icon: Icons.login_rounded,
          iconColor: Colors.orange,
          title: 'Sesi Login Habis',
          message:
              'Sesi login Anda telah habis.\nSilakan login ulang untuk melanjutkan.',
        );
        return;
      }

      final eksekusi = Eksekusi(
        id: '',
        dataPohonId: widget.pohon.id,
        statusEksekusi: _selectedAction == 'Tebang Pangkas' ? 1 : 2,
        tanggalEksekusi: formattedTanggalEksekusi,
        fotoSetelah: null,
        createdBy: creatorId,
        createdDate: Timestamp.now(),
        status: 1,
        tinggiPohon: double.tryParse(_heightController.text) ?? 0.0,
        diameterPohon: double.tryParse(_diameterController.text) ?? 0.0,
      );

      await Provider.of<EksekusiProvider>(context, listen: false).addEksekusi(
        eksekusi,
        _selectedImage!,
        Provider.of<NotificationProvider>(context, listen: false),
      );

      if (!mounted) return;
      _showSuccessAlert();
    } catch (e) {
      if (!mounted) return;
      _showErrorAlert(
        title: 'Gagal Menyimpan',
        message: _humanError(e),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAllowed) {
      return const Scaffold(
          body: Center(child: Text('Akses ditolak untuk pohon ini')));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF125E72),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Eksekusi Pohon #${widget.pohon.idPohon}',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info Pohon ──
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Pohon',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF125E72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.pohon.prioritas == 1
                                    ? Colors.green
                                    : widget.pohon.prioritas == 2
                                        ? const Color(0xFFFFD700)
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Prioritas: ${widget.pohon.prioritas == 1 ? "Rendah" : widget.pohon.prioritas == 2 ? "Sedang" : "Tinggi"}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoRow('ID Pohon', widget.pohon.idPohon.isNotEmpty ? widget.pohon.idPohon : '-', screenWidth),
                          _infoRow('UP3', widget.pohon.up3.isNotEmpty ? widget.pohon.up3 : '-', screenWidth),
                          _infoRow('ULP', widget.pohon.ulp.isNotEmpty ? widget.pohon.ulp : '-', screenWidth),
                          _infoRow('Penyulang', widget.pohon.penyulang.isNotEmpty ? widget.pohon.penyulang : '-', screenWidth),
                          _infoRow('Zona Proteksi', widget.pohon.zonaProteksi.isNotEmpty ? widget.pohon.zonaProteksi : '-', screenWidth),
                          _infoRow('Section', widget.pohon.section.isNotEmpty ? widget.pohon.section : '-', screenWidth),
                          _infoRow('KMS Aset', widget.pohon.kmsAset.isNotEmpty ? widget.pohon.kmsAset : '-', screenWidth),
                          _infoRow('Vendor', widget.pohon.vendor.isNotEmpty ? widget.pohon.vendor : '-', screenWidth),
                          _infoRow('Koordinat', widget.pohon.koordinat.isNotEmpty ? widget.pohon.koordinat : '-', screenWidth),
                          _infoRow(
                            'Tanggal Penjadwalan',
                            _latestPlannedDate != null
                                ? _formatDisplay(_latestPlannedDate!)
                                : _formatDisplay(widget.pohon.scheduleDate),
                            screenWidth,
                          ),
                          _infoRow(
                            'Tujuan Penjadwalan',
                            widget.pohon.tujuanPenjadwalan == 1
                                ? 'Tebang Pangkas'
                                : widget.pohon.tujuanPenjadwalan == 2
                                    ? 'Tebang Habis'
                                    : 'Tidak diketahui',
                            screenWidth,
                          ),
                          _infoRow('Laju Pertumbuhan', '${widget.pohon.growthRate} cm/tahun', screenWidth),
                          _infoRow('Tinggi Awal', '${widget.pohon.initialHeight} m', screenWidth),
                          _infoRow('Catatan', widget.pohon.catatan.isNotEmpty ? widget.pohon.catatan : '-', screenWidth),
                          _infoRow('Nama Pohon', widget.pohon.namaPohon.isNotEmpty ? widget.pohon.namaPohon : '-', screenWidth),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Form Eksekusi ──
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Penanganan Pohon',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF125E72),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tinggi Pohon
                          _inputField(
                            label: 'Tinggi Pohon Setelah Dipangkas',
                            icon: Icons.height,
                            suffix: 'm',
                            controller: _heightController,
                            hintText: 'Contoh: 4.5',
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Wajib diisi';
                              final h = double.tryParse(value);
                              if (h == null) return 'Angka tidak valid';
                              if (h <= 0) return 'Harus > 0';
                              if (h > 10) return 'Maks 10 m';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Diameter
                          _inputField(
                            label: 'Diameter Pohon',
                            icon: Icons.aspect_ratio,
                            suffix: 'cm',
                            controller: _diameterController,
                            hintText: 'Masukkan diameter',
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Diameter wajib diisi';
                              if (double.tryParse(value) == null) return 'Masukkan angka valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Tanggal Eksekusi ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Color(0xFF125E72)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Tanggal Eksekusi',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFF0F9FF),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _isLoadingDate
                                            ? Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF125E72),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Memuat jadwal...',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                _dateController.text.isEmpty
                                                    ? 'Pilih tanggal eksekusi'
                                                    : _dateController.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: _dateController.text.isEmpty
                                                      ? Colors.grey.shade500
                                                      : Colors.black87,
                                                ),
                                              ),
                                      ),
                                      const Icon(Icons.calendar_month,
                                          color: Color(0xFF125E72), size: 20),
                                    ],
                                  ),
                                ),
                              ),

                              // ── Info prediksi berikutnya ──
                              // Hanya tampil untuk Tebang Pangkas
                              if (_nextPrediction != null &&
                                  _selectedAction == 'Tebang Pangkas') ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F4F8),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFF125E72)
                                            .withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 14, color: Color(0xFF125E72)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Prediksi eksekusi berikutnya: ${_formatDisplay(_nextPrediction!)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF125E72),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Foto ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.camera_alt,
                                      size: 18, color: Color(0xFF125E72)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Foto Setelah Eksekusi',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: Icon(
                                    _selectedImage == null
                                        ? Icons.add_a_photo
                                        : Icons.edit,
                                    size: 18,
                                  ),
                                  label: Text(_selectedImage == null
                                      ? 'Pilih Foto'
                                      : 'Ganti Foto'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF125E72),
                                    side: const BorderSide(
                                        color: Color(0xFF125E72)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              if (_selectedImage != null) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: screenHeight * 0.22,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Aksi dropdown ──
                          _ActionDropdown(
                            value: _selectedAction,
                            onChanged: (val) => setState(
                                () => _selectedAction = val ?? _selectedAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF125E72)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(color: Color(0xFF125E72))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEksekusi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF125E72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Simpan Eksekusi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Loading overlay ──
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF125E72)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF125E72)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: hintText,
            suffixText: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          validator: validator,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.035),
              softWrap: true,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// ACTION DROPDOWN
// ════════════════════════════════════════════════
class _ActionDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ActionDropdown({required this.value, required this.onChanged});

  @override
  State<_ActionDropdown> createState() => _ActionDropdownState();
}

class _ActionDropdownState extends State<_ActionDropdown>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  final List<String> _items = const ['Tebang Pangkas', 'Tebang Habis'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() =>
      isExpanded ? _closeDropdown() : _openDropdown();

  void _openDropdown() {
    setState(() => isExpanded = true);
    _controller.forward();
    final renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.scale(
                scaleY: _controller.value,
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _items.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () {
                        widget.onChanged(_items[index]);
                        _closeDropdown();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.value == _items[index]
                              ? const Color(0xFFF0F9FF)
                              : null,
                        ),
                        child: Text(
                          _items[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.value == _items[index]
                                ? const Color(0xFF2E5D6F)
                                : Colors.black87,
                            fontWeight: widget.value == _items[index]
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() => isExpanded = false);
    _controller.reverse().then((_) => _overlayEntry?.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _dropdownKey,
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? 'Pilih aksi',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}