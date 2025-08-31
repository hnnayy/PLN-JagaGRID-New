import 'package:cloud_firestore/cloud_firestore.dart';

class Repetisi {
  final String id; // ID dokumen Firestore
  final String dataPohonId; // Refer ke id data_pohon
  final String eksekusiId; // Refer ke id eksekusi
  final int repetisiKe; // Urutan siklus repetisi
  final int tujuan; // 1=Penebangan, 2=Pemangkasan
  final String createdBy; // ID user
  final Timestamp createdDate; // Default serverTimestamp
  final int status; // 1=sedang repetisi, 2=kembali di eksekusi, 3=pohon mati

  Repetisi({
    required this.id,
    required this.dataPohonId,
    required this.eksekusiId,
    required this.repetisiKe,
    required this.tujuan,
    required this.createdBy,
    required this.createdDate,
    required this.status,
  });

  // Konversi ke Map untuk simpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'dataPohonId': dataPohonId,
      'eksekusiId': eksekusiId,
      'repetisiKe': repetisiKe,
      'tujuan': tujuan,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'status': status,
    };
  }

  // Konversi dari Map (dari Firestore)
  factory Repetisi.fromMap(Map<String, dynamic> map, String documentId) {
    return Repetisi(
      id: documentId,
      dataPohonId: map['dataPohonId'] ?? '',
      eksekusiId: map['eksekusiId'] ?? '',
      repetisiKe: map['repetisiKe'] ?? 0,
      tujuan: map['tujuan'] ?? 1,
      createdBy: map['createdBy'] ?? '',
      createdDate: map['createdDate'] ?? Timestamp.now(),
      status: map['status'] ?? 1,
    );
  }
}