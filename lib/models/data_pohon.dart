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
  final int parentId; // Refer unit_parent.id
  final int unitId; // Refer unit.id
  final int asetJtmId; // Refer aset_jtm.id
  final DateTime scheduleDate;
  final int prioritas; // 1=Rendah, 2=Sedang, 3=Tinggi
  final String namaPohon;
  final String fotoPohon; // Filepath/URL
  final String koordinat;
  final int tujuanPenjadwalan; // 1=Tebang Pangkas, 2=Tebang Habis
  final String catatan;
  final int createdBy;
  final DateTime createdDate;
  final double growthRate; // cm/tahun, dari lookup table
  final double initialHeight; // meter, dari input manual
  final DateTime notificationDate; // 3 hari sebelum scheduleDate
  final int status; // 1 = aktif, 0 = delete

  static const Map<String, double> growthRates = {
    'Mangrove': 75.0,
    'Jabon Merah': 150.0,
    'Kesambi': 40.0,
    'Akasia': 150.0,
    'Bambu': 100.0,
    'Kelapa Sawit': 75.0,
    'Jati': 40.0,
    'Lontar': 60.0,
    'Pule': 90.0,
    'Mahoni': 75.0,
  };

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
    required this.parentId,
    required this.unitId,
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
      'parent_id': parentId,
      'unit_id': unitId,
      'aset_jtm_id': asetJtmId,
      'schedule_date': scheduleDate.toIso8601String(),
      'prioritas': prioritas,
      'nama_pohon': namaPohon,
      'foto_pohon': fotoPohon,
      'koordinat': koordinat,
      'tujuan_penjadwalan': tujuanPenjadwalan,
      'catatan': catatan,
      'createdby': createdBy,
      'createddate': createdDate.toIso8601String(),
      'growth_rate': growthRate,
      'initial_height': initialHeight,
      'notification_date': notificationDate.toIso8601String(),
      'status': status,
    };
  }

  factory DataPohon.fromMap(Map<String, dynamic> map) {
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
      parentId: map['parent_id'] ?? 0,
      unitId: map['unit_id'] ?? 0,
      asetJtmId: map['aset_jtm_id'] ?? 0,
      scheduleDate: DateTime.parse(map['schedule_date'] ?? DateTime.now().toIso8601String()),
      prioritas: map['prioritas'] ?? 1,
      namaPohon: map['nama_pohon'] ?? '',
      fotoPohon: map['foto_pohon'] ?? '',
      koordinat: map['koordinat'] ?? '',
      tujuanPenjadwalan: map['tujuan_penjadwalan'] ?? 1,
      catatan: map['catatan'] ?? '',
      createdBy: map['createdby'] ?? 0,
      createdDate: DateTime.parse(map['createddate'] ?? DateTime.now().toIso8601String()),
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      initialHeight: (map['initial_height'] as num?)?.toDouble() ?? 0.0,
      notificationDate: DateTime.parse(map['notification_date'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 1,
    );
  }
}