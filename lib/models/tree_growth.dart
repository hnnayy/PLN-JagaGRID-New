import 'package:cloud_firestore/cloud_firestore.dart';

class TreeGrowth {
  final String id;
  final String name;
  final double growthRate;
  final DateTime createdAt;
  final int status;
  final DateTime? deletedAt;
  final String unit; // 'all' = global (Admin), 'ULP BARRU' = milik ULP tertentu

  TreeGrowth({
    required this.id,
    required this.name,
    required this.growthRate,
    required this.createdAt,
    this.status = 1,
    this.deletedAt,
    this.unit = 'all',
  });

  bool get isActive => status == 1;
  bool get isDeleted => status == 0;
  bool get isGlobal => unit == 'all'; // Data dari Admin UP3

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'growth_rate': growthRate,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      'deleted_at': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'unit': unit,
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
      unit: map['unit']?.toString() ?? 'all',
    );
  }

  TreeGrowth copyWith({
    String? id,
    String? name,
    double? growthRate,
    DateTime? createdAt,
    int? status,
    DateTime? deletedAt,
    String? unit,
  }) {
    return TreeGrowth(
      id: id ?? this.id,
      name: name ?? this.name,
      growthRate: growthRate ?? this.growthRate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      unit: unit ?? this.unit,
    );
  }
}