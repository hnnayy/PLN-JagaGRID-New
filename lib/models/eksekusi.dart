import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Eksekusi {
  final String id;
  final String dataPohonId;
  final int statusEksekusi;
  final String tanggalEksekusi; // Stored as DD/MM/YYYY HH:MM WITA
  final String? fotoSetelah;
  final String createdBy;
  final Timestamp createdDate;
  final int status;
  final double tinggiPohon;
  final double diameterPohon;

  Eksekusi({
    required this.id,
    required this.dataPohonId,
    required this.statusEksekusi,
    required this.tanggalEksekusi,
    this.fotoSetelah,
  required this.createdBy,
    required this.createdDate,
    required this.status,
    required this.tinggiPohon,
    required this.diameterPohon,
  }) {
    // Validate statusEksekusi to ensure it is either 1 or 2
    if (statusEksekusi != 1 && statusEksekusi != 2) {
      throw ArgumentError('statusEksekusi must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_pohon_id': dataPohonId,
      'status_eksekusi': statusEksekusi,
      'tanggal_eksekusi': tanggalEksekusi, // Store as string
      'foto_setelah': fotoSetelah,
      'createdby': createdBy,
      'createddate': createdDate,
      'status': status,
      'tinggi_pohon': tinggiPohon,
      'diameter_pohon': diameterPohon,
    };
  }

  factory Eksekusi.fromMap(Map<String, dynamic> map) {
    final statusEksekusi = map['status_eksekusi'] as int? ?? (throw ArgumentError('status_eksekusi is required and must be an integer'));
    if (statusEksekusi != 1 && statusEksekusi != 2) {
      throw ArgumentError('Invalid status_eksekusi value: $statusEksekusi. Must be 1 (Tebang Pangkas) or 2 (Tebang Habis)');
    }

    // Handle tanggal_eksekusi as either String or Timestamp
    String tanggalEksekusi;
    if (map['tanggal_eksekusi'] is Timestamp) {
      final dateTime = (map['tanggal_eksekusi'] as Timestamp).toDate().toUtc().add(const Duration(hours: 8)); // Convert to WITA
      tanggalEksekusi = DateFormat('dd/MM/yyyy HH:mm').format(dateTime) + ' WITA';
    } else {
      tanggalEksekusi = map['tanggal_eksekusi'] as String? ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now().toUtc().add(const Duration(hours: 8))) + ' WITA';
    }

    return Eksekusi(
      id: map['id'] as String? ?? '',
      dataPohonId: map['data_pohon_id'] as String? ?? '',
      statusEksekusi: statusEksekusi,
      tanggalEksekusi: tanggalEksekusi,
      fotoSetelah: map['foto_setelah'] as String?,
  createdBy: (map['createdby']?.toString() ?? ''),
      createdDate: map['createddate'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] as int? ?? 1,
      tinggiPohon: (map['tinggi_pohon'] as num? ?? 0.0).toDouble(),
      diameterPohon: (map['diameter_pohon'] as num? ?? 0.0).toDouble(),
    );
  }

  // Helper method to return tanggalEksekusi as is (already in DD/MM/YYYY HH:MM WITA format)
  String formatTanggalEksekusi() {
    return tanggalEksekusi;
  }
}