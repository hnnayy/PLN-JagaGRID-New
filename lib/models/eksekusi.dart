import 'package:cloud_firestore/cloud_firestore.dart';

class Eksekusi {
  final String id;
  final int dataPohonId;
  final int statusEksekusi;
  final Timestamp tanggalEksekusi;
  final String? fotoSetelah; // Diubah menjadi nullable untuk menangani null
  final int createdBy;
  final Timestamp createdDate;
  final int status;
  final double tinggiPohon;
  final double diameterPohon;

  Eksekusi({
    required this.id,
    required this.dataPohonId,
    required this.statusEksekusi,
    required this.tanggalEksekusi,
    this.fotoSetelah, // Nullable
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
      'tanggal_eksekusi': tanggalEksekusi,
      'foto_setelah': fotoSetelah, // Bisa null
      'createdby': createdBy,
      'createddate': createdDate,
      'status': status,
      'tinggi_pohon': tinggiPohon,
      'diameter_pohon': diameterPohon,
    };
  }

  factory Eksekusi.fromMap(Map<String, dynamic> map) {
    return Eksekusi(
      id: map['id'] as String? ?? '', // Penanganan null
      dataPohonId: map['data_pohon_id'] as int? ?? 0,
      statusEksekusi: map['status_eksekusi'] as int? ?? 1,
      tanggalEksekusi: map['tanggal_eksekusi'] as Timestamp? ?? Timestamp.now(),
      fotoSetelah: map['foto_setelah'] as String?, // Terima null
      createdBy: map['createdby'] as int? ?? 0,
      createdDate: map['createddate'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] as int? ?? 1,
      tinggiPohon: (map['tinggi_pohon'] as num? ?? 0.0).toDouble(),
      diameterPohon: (map['diameter_pohon'] as num? ?? 0.0).toDouble(),
    );
  }
}