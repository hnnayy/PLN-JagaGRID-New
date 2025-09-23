import 'package:cloud_firestore/cloud_firestore.dart';

class TreeGrowth {
  final String id; // Firestore document ID
  final String name; // Nama pohon
  final double growthRate; // cm/tahun
  final DateTime createdAt;
  final int status; // 1 = aktif, 0 = terhapus (soft delete)
  final DateTime? deletedAt; // Waktu dihapus (null jika tidak dihapus)

  TreeGrowth({
    required this.id,
    required this.name,
    required this.growthRate,
    required this.createdAt,
    this.status = 1, // Default aktif
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'growth_rate': growthRate,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      'deleted_at': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  factory TreeGrowth.fromMap(Map<String, dynamic> map, String documentId) {
    return TreeGrowth(
      id: documentId,
      name: map['name']?.toString() ?? '',
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (map['status'] as int?) ?? 1,
      deletedAt: (map['deleted_at'] as Timestamp?)?.toDate(),
    );
  }

  TreeGrowth copyWith({
    String? id,
    String? name,
    double? growthRate,
    DateTime? createdAt,
    int? status,
    DateTime? deletedAt,
  }) {
    return TreeGrowth(
      id: id ?? this.id,
      name: name ?? this.name,
      growthRate: growthRate ?? this.growthRate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper methods
  bool get isActive => status == 1;
  bool get isDeleted => status == 0;
}