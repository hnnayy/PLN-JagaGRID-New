import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String id;
  final String name;
  final String username;
  final String telegramUsername;
  final String unit;
  final int level; // Added field for level (1 for Unit Induk, 2 for Unit Layanan)
  final String addedDate; // Added field for added date
  final String chatIdTelegram; // Added field for Telegram chat ID
  final int status; // Added field for status (e.g., 1 for active)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.name,
    required this.username,
    required this.telegramUsername,
    required this.unit,
    required this.level,
    required this.addedDate,
    required this.chatIdTelegram,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore → Model
  factory Profile.fromMap(String id, Map<String, dynamic> data) {
    return Profile(
      id: id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      telegramUsername: data['username_telegram'] ?? '', // Adjusted to match your data structure
      unit: data['unit'] ?? '',
      level: data['level'] ?? 2, // Default to 2 (Unit Layanan) if not present
      addedDate: data['added'] ?? '', // Adjusted to match your data structure
      chatIdTelegram: data['chat_id_telegram'] ?? '', // Adjusted to match your data structure
      status: data['status'] ?? 1, // Default to 1 (active) if not present
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap({bool isUpdate = false}) {
    final map = {
      'name': name,
      'username': username,
      'username_telegram': telegramUsername, // Adjusted to match your data structure
      'unit': unit,
      'level': level,
      'added': addedDate, // Adjusted to match your data structure
      'chat_id_telegram': chatIdTelegram, // Adjusted to match your data structure
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (!isUpdate) {
      map['created_at'] = FieldValue.serverTimestamp();
    }

    return map;
  }
}