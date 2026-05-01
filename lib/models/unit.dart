import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  final String? id;
  final String namaUnit;
  final String kodeUnit;
  final String createdAt;
  final int status; // 1 = aktif, 0 = terhapus (soft delete)
  final DateTime? deletedAt; // timestamp saat dihapus (null jika aktif)

  UnitModel({
    this.id,
    required this.namaUnit,
    required this.kodeUnit,
    required this.createdAt,
    this.status = 1,
    this.deletedAt,
  });

  UnitModel copyWith({
    String? id,
    String? namaUnit,
    String? kodeUnit,
    String? createdAt,
    int? status,
    DateTime? deletedAt,
  }) {
    return UnitModel(
      id: id ?? this.id,
      namaUnit: namaUnit ?? this.namaUnit,
      kodeUnit: kodeUnit ?? this.kodeUnit,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Convert dari Map (Firestore → App)
  factory UnitModel.fromMap(Map<String, dynamic> map, String id) {
    return UnitModel(
      id: id,
      namaUnit: map['nama_unit'] ?? '',
      kodeUnit: map['kode_unit'] ?? '',
      createdAt: map['created_at'] ?? '',
      status: map['status'] ?? 1,
      // Firestore Timestamp → DateTime
      deletedAt: map['deleted_at'] != null
          ? (map['deleted_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert ke Map (App → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nama_unit': namaUnit,
      'kode_unit': kodeUnit,
      'created_at': createdAt,
      'status': status,
      'deleted_at': deletedAt != null
          ? Timestamp.fromDate(deletedAt!)
          : null,
    };
  }

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      namaUnit: json['nama_unit'] ?? '',
      kodeUnit: json['kode_unit'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 1,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_unit': namaUnit,
      'kode_unit': kodeUnit,
      'created_at': createdAt,
      'status': status,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 1;
  bool get isDeleted => status == 0;

  UnitModel markAsDeleted() => copyWith(status: 0, deletedAt: DateTime.now());
  UnitModel markAsActive() => copyWith(status: 1);

  @override
  String toString() {
    return 'UnitModel(id: $id, namaUnit: $namaUnit, kodeUnit: $kodeUnit, '
        'status: $status, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitModel &&
        other.id == id &&
        other.namaUnit == namaUnit &&
        other.kodeUnit == kodeUnit &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, namaUnit, kodeUnit, createdAt, status);
}