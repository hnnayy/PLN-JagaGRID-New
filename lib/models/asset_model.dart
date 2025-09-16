import 'package:cloud_firestore/cloud_firestore.dart';

class AssetModel {
  final String id;
  final String wilayah;
  final String subWilayah;
  final String section;
  final String up3;
  final String ulp;
  final String penyulang;
  final String zonaProteksi;
  final double panjangKms;
  final String status; // Health Index
  final String role;
  final String vendorVb;
  final DateTime createdAt;

  AssetModel({
    required this.id,
    required this.wilayah,
    required this.subWilayah,
    required this.section,
    required this.up3,
    required this.ulp,
    required this.penyulang,
    required this.zonaProteksi,
    required this.panjangKms,
    required this.status,
    required this.role,
    required this.vendorVb,
    required this.createdAt,
  });

  /// 🔹 Convert Model → Map (buat simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'wilayah': wilayah,
      'subWilayah': subWilayah,
      'section': section,
      'up3': up3,
      'ulp': ulp,
      'penyulang': penyulang,
      'zonaProteksi': zonaProteksi,
      'panjangKms': panjangKms,
      'status': status,
      'role': role,
      'vendorVb': vendorVb,
      'createdAt': createdAt,
    };
  }

  /// 🔹 Convert Model → Map untuk update (tanpa createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'wilayah': wilayah,
      'subWilayah': subWilayah,
      'section': section,
      'up3': up3,
      'ulp': ulp,
      'penyulang': penyulang,
      'zonaProteksi': zonaProteksi,
      'panjangKms': panjangKms,
      'status': status,
      'role': role,
      'vendorVb': vendorVb,
      // Tidak include createdAt karena tidak boleh diubah
    };
  }

  /// 🔹 Convert Firestore → Model
  factory AssetModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AssetModel(
      id: id,
      wilayah: data['wilayah'] ?? '',
      subWilayah: data['subWilayah'] ?? '',
      section: data['section'] ?? '',
      up3: data['up3'] ?? '',
      ulp: data['ulp'] ?? '',
      penyulang: data['penyulang'] ?? '',
      zonaProteksi: data['zonaProteksi'] ?? '',
      panjangKms: (data['panjangKms'] ?? 0).toDouble(),
      status: data['status'] ?? '',
      role: data['role'] ?? '',
      vendorVb: data['vendorVb'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Copy with method untuk membuat instance baru dengan beberapa field yang diubah
  AssetModel copyWith({
    String? id,
    String? wilayah,
    String? subWilayah,
    String? section,
    String? up3,
    String? ulp,
    String? penyulang,
    String? zonaProteksi,
    double? panjangKms,
    String? status,
    String? role,
    String? vendorVb,
    DateTime? createdAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      wilayah: wilayah ?? this.wilayah,
      subWilayah: subWilayah ?? this.subWilayah,
      section: section ?? this.section,
      up3: up3 ?? this.up3,
      ulp: ulp ?? this.ulp,
      penyulang: penyulang ?? this.penyulang,
      zonaProteksi: zonaProteksi ?? this.zonaProteksi,
      panjangKms: panjangKms ?? this.panjangKms,
      status: status ?? this.status,
      role: role ?? this.role,
      vendorVb: vendorVb ?? this.vendorVb,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}