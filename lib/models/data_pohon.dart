import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DataPohon {
  final String id;
  final String idPohon;
  final String up3;
  final String ulp;
  final String penyulang;
  final String zonaProteksi;
  final String section;
  final String kmsAset;
  final String vendor;
  final int asetJtmId;
  final DateTime scheduleDate;
  final int prioritas; // 1=Rendah, 2=Sedang, 3=Tinggi
  final String namaPohon;
  final String fotoPohon;
  final String koordinat;
  final int tujuanPenjadwalan; // 1=Tebang Pangkas, 2=Tebang Habis
  final String catatan;
  final String createdBy;
  final DateTime createdDate;
  final double growthRate; // cm/tahun, dari master pertumbuhan pohon
  final double initialHeight; // meter, dari input manual
  final DateTime notificationDate; // 3 hari sebelum scheduleDate
  final int status; // 1 = aktif, 0 = deleted, 2 = mati sendiri
  final DateTime? deadAt; // waktu pohon ditemukan mati (null jika tidak mati)
  final String deadNotes; // penyebab kematian pohon (opsional)

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
    this.status = 1,
    this.deadAt,
    this.deadNotes = '',
  });

  // Helper
  bool get isAktif => status == 1;
  bool get isDeleted => status == 0;
  bool get isMati => status == 2;

  Map<String, dynamic> toMap() {
    final dateFormatter = DateFormat('d-M-y');
    final scheduleDateString = dateFormatter.format(scheduleDate);
    final notificationDateUtc =
        notificationDate.subtract(const Duration(hours: 8));
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
      'schedule_date': scheduleDateString,
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
      'dead_at': deadAt != null ? Timestamp.fromDate(deadAt!) : null,
      'dead_notes': deadNotes,
    };
  }

  factory DataPohon.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, {bool isScheduleDate = false}) {
      if (isScheduleDate) {
        if (value is String) {
          try {
            final dateFormatter = DateFormat('d-M-y');
            try {
              return dateFormatter.parse(value).add(const Duration(hours: 8));
            } catch (e) {
              final fallbackFormatter = DateFormat('yyyy-MM-dd');
              return fallbackFormatter
                  .parse(value)
                  .add(const Duration(hours: 8));
            }
          } catch (e) {
            print('Error parsing schedule_date string: $value, error: $e');
            return DateTime.now();
          }
        }
        if (value is Timestamp) {
          final date = value.toDate();
          return DateTime(date.year, date.month, date.day)
              .add(const Duration(hours: 8));
        }
      } else {
        if (value is Timestamp) {
          return value.toDate().add(const Duration(hours: 8));
        } else if (value is String) {
          try {
            return DateTime.parse(value).add(const Duration(hours: 8));
          } catch (e) {
            print('Error parsing date string: $value, error: $e');
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    final scheduleDate = parseDate(map['schedule_date'], isScheduleDate: true);
    final createdDate = parseDate(map['createddate']);
    final notificationDate = parseDate(map['notification_date']);

    // Parse deadAt jika ada
    DateTime? deadAt;
    if (map['dead_at'] != null && map['dead_at'] is Timestamp) {
      deadAt = (map['dead_at'] as Timestamp).toDate();
    }

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
      deadAt: deadAt,
      deadNotes: map['dead_notes'] ?? '',
    );
  }
}