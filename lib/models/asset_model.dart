import 'package:cloud_firestore/cloud_firestore.dart';

enum HealthIndex { SEMPURNA, SEHAT, SAKIT }

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
  final HealthIndex healthIndex;
  final int status; // 0 = deleted, 1 = aktif
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
    required this.healthIndex,
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
      'health_index': healthIndex.toString().split('.').last,
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
      'health_index': healthIndex.toString().split('.').last,
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
      healthIndex: HealthIndex.values.firstWhere(
        (e) => e.toString().split('.').last == (data['health_index'] ?? 'SEHAT'),
        orElse: () => HealthIndex.SEHAT,
      ),
      status: data['status'] ?? 1, // Default ke aktif jika tidak ada
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
    HealthIndex? healthIndex,
    int? status,
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
      healthIndex: healthIndex ?? this.healthIndex,
      status: status ?? this.status,
      role: role ?? this.role,
      vendorVb: vendorVb ?? this.vendorVb,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}