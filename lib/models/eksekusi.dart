import 'dart:convert';
class Eksekusi {
  final int id;
  final int dataPohonId;
  final int statusEksekusi;
  final DateTime tanggalEksekusi;
  final String fotoSetelah;
  final int createdBy;
  final DateTime createdDate;
  final int status;
  final double tinggiPohon;
  final double diameterPohon;

  Eksekusi({
    required this.id,
    required this.dataPohonId,
    required this.statusEksekusi,
    required this.tanggalEksekusi,
    required this.fotoSetelah,
    required this.createdBy,
    required this.createdDate,
    required this.status,
    required this.tinggiPohon,
    required this.diameterPohon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_pohon_id': dataPohonId,
      'status_eksekusi': statusEksekusi,
      'tanggal_eksekusi': tanggalEksekusi.toIso8601String(),
      'foto_setelah': fotoSetelah,
      'createdby': createdBy,
      'createddate': createdDate.toIso8601String(),
      'status': status,
      'tinggi_pohon': tinggiPohon,
      'diameter_pohon': diameterPohon,
    };
  }

  factory Eksekusi.fromMap(Map<String, dynamic> map) {
    return Eksekusi(
      id: map['id'] ?? 0,
      dataPohonId: map['data_pohon_id'] ?? 0,
      statusEksekusi: map['status_eksekusi'] ?? 1,
      tanggalEksekusi: DateTime.parse(map['tanggal_eksekusi']),
      fotoSetelah: map['foto_setelah'] ?? '',
      createdBy: map['createdby'] ?? 0,
      createdDate: DateTime.parse(map['createddate']),
      status: map['status'] ?? 1,
      tinggiPohon: (map['tinggi_pohon'] ?? 0.0).toDouble(),
      diameterPohon: (map['diameter_pohon'] ?? 0.0).toDouble(),
    );
  }
}