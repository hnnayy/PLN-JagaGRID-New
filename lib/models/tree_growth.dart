import 'package:cloud_firestore/cloud_firestore.dart';

class TreeGrowth {
  final String id; // Firestore document ID
  final String name; // Nama pohon
  final double growthRate; // cm/tahun
  final DateTime createdAt;

  TreeGrowth({
    required this.id,
    required this.name,
    required this.growthRate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'growth_rate': growthRate,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory TreeGrowth.fromMap(Map<String, dynamic> map, String documentId) {
    return TreeGrowth(
      id: documentId,
      name: map['name']?.toString() ?? '',
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  TreeGrowth copyWith({
    String? id,
    String? name,
    double? growthRate,
    DateTime? createdAt,
  }) {
    return TreeGrowth(
      id: id ?? this.id,
      name: name ?? this.name,
      growthRate: growthRate ?? this.growthRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
