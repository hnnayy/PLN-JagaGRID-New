import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DataPohon {
  final String id;
  final String idPohon; // UNIQUE constraint
  final String up3; // Tambah dari form
  final String ulp; // Tambah dari form
  final String penyulang; // Tambah dari form
  final String zonaProteksi; // Tambah dari form
  final String section; // Tambah dari form
  final String kmsAset; // Tambah dari form
  final String vendor; // Tambah dari form
  final int asetJtmId; // Refer aset_jtm.id
  final DateTime scheduleDate;
  final int prioritas; // 1=Rendah, 2=Sedang, 3=Tinggi
  final String namaPohon;
  final String fotoPohon; // Filepath/URL
  final String koordinat;
  final int tujuanPenjadwalan; // 1=Tebang Pangkas, 2=Tebang Habis
  final String catatan;
  final String createdBy;
  final DateTime createdDate;
  final double growthRate; // cm/tahun, dari lookup table
  final double initialHeight; // meter, dari input manual
  final DateTime notificationDate; // 3 hari sebelum scheduleDate
  final int status; // 1 = aktif, 0 = delete

  // Growth rates sekarang dikelola dari Master Pertumbuhan pohon (Firestore: tree_growth)

  DataPohon({
    required this.id,
    required this.idPohon,
    required this.up3,
    required this.ulp,
    required this.penyulang,
    required this.zonaProteksi,
    required this.section,
    required this.kmsAset,
    required this.vendor,
    required this.asetJtmId,
    required this.scheduleDate,
    required this.prioritas,
    required this.namaPohon,
    required this.fotoPohon,
    required this.koordinat,
    required this.tujuanPenjadwalan,
    required this.catatan,
    required this.createdBy,
    required this.createdDate,
    required this.growthRate,
    required this.initialHeight,
    required this.notificationDate,
    this.status = 1, // Default status adalah aktif (1)
  });

  Map<String, dynamic> toMap() {
    // Format scheduleDate as a date-only string (M-d-y)
    final dateFormatter = DateFormat('d-M-y');
    final scheduleDateString = dateFormatter.format(scheduleDate);

    // Convert WITA DateTime to UTC for Firestore for other date fields
    final notificationDateUtc = notificationDate.subtract(const Duration(hours: 8));
    final createdDateUtc = createdDate.subtract(const Duration(hours: 8));

    return {
      'id': id,
      'id_pohon': idPohon,
      'up3': up3,
      'ulp': ulp,
      'penyulang': penyulang,
      'zona_proteksi': zonaProteksi,
      'section': section,
      'kms_aset': kmsAset,
      'vendor': vendor,
      'aset_jtm_id': asetJtmId,
      'schedule_date': scheduleDateString, // Store as string in M-d-y format
      'prioritas': prioritas,
      'nama_pohon': namaPohon,
      'foto_pohon': fotoPohon,
      'koordinat': koordinat,
      'tujuan_penjadwalan': tujuanPenjadwalan,
      'catatan': catatan,
  'createdby': createdBy,
      'createddate': Timestamp.fromDate(createdDateUtc),
      'growth_rate': growthRate,
      'initial_height': initialHeight,
      'notification_date': Timestamp.fromDate(notificationDateUtc),
      'status': status,
    };
  }

  factory DataPohon.fromMap(Map<String, dynamic> map) {
    // Handle schedule_date as a string in M-d-y, yyyy-MM-dd, or Timestamp
    DateTime parseDate(dynamic value, {bool isScheduleDate = false}) {
      if (isScheduleDate) {
        if (value is String) {
          try {
            final dateFormatter = DateFormat('d-M-y');
            // Try parsing as M-d-y first
            try {
              return dateFormatter.parse(value).add(const Duration(hours: 8)); // Parse to WITA
            } catch (e) {
              // Fallback to yyyy-MM-dd for backward compatibility
              final fallbackFormatter = DateFormat('yyyy-MM-dd');
              return fallbackFormatter.parse(value).add(const Duration(hours: 8)); // Parse to WITA
            }
          } catch (e) {
            print('Error parsing schedule_date string: $value, error: $e');
            return DateTime.now(); // Fallback to current date
          }
        }
        // Fallback for existing Timestamp data (for backward compatibility)
        if (value is Timestamp) {
          final date = value.toDate();
          return DateTime(date.year, date.month, date.day).add(const Duration(hours: 8)); // Date-only in WITA
        }
      } else {
        if (value is Timestamp) {
          return value.toDate().add(const Duration(hours: 8)); // Full datetime in WITA
        } else if (value is String) {
          try {
            return DateTime.parse(value).add(const Duration(hours: 8)); // Parse string and convert to WITA
          } catch (e) {
            print('Error parsing date string: $value, error: $e');
            return DateTime.now(); // Fallback to current time
          }
        }
      }
      return DateTime.now(); // Fallback if value is null or invalid
    }

    final scheduleDate = parseDate(map['schedule_date'], isScheduleDate: true);
    final createdDate = parseDate(map['createddate']);
    final notificationDate = parseDate(map['notification_date']);

    return DataPohon(
      id: map['id'] ?? '',
      idPohon: map['id_pohon'] ?? '',
      up3: map['up3'] ?? '',
      ulp: map['ulp'] ?? '',
      penyulang: map['penyulang'] ?? '',
      zonaProteksi: map['zona_proteksi'] ?? '',
      section: map['section'] ?? '',
      kmsAset: map['kms_aset'] ?? '',
      vendor: map['vendor'] ?? '',
      asetJtmId: map['aset_jtm_id'] ?? 0,
      scheduleDate: scheduleDate,
      prioritas: map['prioritas'] ?? 0,
      namaPohon: map['nama_pohon'] ?? '',
      fotoPohon: map['foto_pohon'] ?? '',
      koordinat: map['koordinat'] ?? '',
      tujuanPenjadwalan: map['tujuan_penjadwalan'] ?? 1,
      catatan: map['catatan'] ?? '',
  createdBy: (map['createdby']?.toString() ?? ''),
      createdDate: createdDate,
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      initialHeight: (map['initial_height'] as num?)?.toDouble() ?? 0.0,
      notificationDate: notificationDate,
      status: map['status'] ?? 1,
    );
  }
}