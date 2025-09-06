import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String id;
  final String name;
  final String username;
  final String telegramUsername;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.name,
    required this.username,
    required this.telegramUsername,
    required this.unit,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore → Model
  factory Profile.fromMap(String id, Map<String, dynamic> data) {
    return Profile(
      id: id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      telegramUsername: data['telegram_username'] ?? '',
      unit: data['unit'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap({bool isUpdate = false}) {
    final map = {
      'name': name,
      'username': username,
      'telegram_username': telegramUsername,
      'unit': unit,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (!isUpdate) {
      map['created_at'] = FieldValue.serverTimestamp();
    }

    return map;
  }
}
