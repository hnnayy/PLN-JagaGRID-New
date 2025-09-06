class UserModel {
  final String? id; // Firestore document ID
  final String name;
  final String username;
  final String unit;
  final String added;
  final String password;
  final String usernameTelegram; // Perbaikan nama field
  final String chatIdTelegram; // Perbaikan nama field
  final int status; // Field baru: 1 = aktif, 0 = terhapus

  UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.unit,
    required this.added,
    required this.password,
    required this.usernameTelegram,
    required this.chatIdTelegram,
    this.status = 1, // Default aktif
  });

  /// Buat copy data dengan nilai baru
  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? unit,
    String? added,
    String? password,
    String? usernameTelegram,
    String? chatIdTelegram,
    int? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      unit: unit ?? this.unit,
      added: added ?? this.added,
      password: password ?? this.password,
      usernameTelegram: usernameTelegram ?? this.usernameTelegram,
      chatIdTelegram: chatIdTelegram ?? this.chatIdTelegram,
      status: status ?? this.status,
    );
  }

  /// Convert dari Map (Firestore → App)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      unit: map['unit'] ?? '',
      added: map['added'] ?? '',
      password: map['password'] ?? '',
      // Perbaikan: gunakan field name yang konsisten dengan database
      usernameTelegram: map['username_telegram'] ?? '',
      chatIdTelegram: map['chat_id_telegram'] ?? '',
      status: map['status'] ?? 1, // Default aktif jika tidak ada
    );
  }

  /// Convert ke Map (App → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'unit': unit,
      'added': added,
      'password': password,
      // Perbaikan: simpan dengan field name yang konsisten
      'username_telegram': usernameTelegram,
      'chat_id_telegram': chatIdTelegram,
      'status': status,
    };
  }

  /// Convert dari JSON (misalnya API → App)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      unit: json['unit'] ?? '',
      added: json['added'] ?? '',
      password: json['password'] ?? '',
      usernameTelegram: json['username_telegram'] ?? '',
      chatIdTelegram: json['chat_id_telegram'] ?? '',
      status: json['status'] ?? 1,
    );
  }

  /// Convert ke JSON (App → API / simpan lokal)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'unit': unit,
      'added': added,
      'password': password,
      'username_telegram': usernameTelegram,
      'chat_id_telegram': chatIdTelegram,
      'status': status,
    };
  }

  /// Helper methods untuk status
  bool get isActive => status == 1;
  bool get isDeleted => status == 0;

  /// Method untuk soft delete
  UserModel markAsDeleted() => copyWith(status: 0);
  
  /// Method untuk restore
  UserModel markAsActive() => copyWith(status: 1);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, username: $username, unit: $unit, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.username == username &&
        other.unit == unit &&
        other.added == added &&
        other.password == password &&
        other.usernameTelegram == usernameTelegram &&
        other.chatIdTelegram == chatIdTelegram &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      username,
      unit,
      added,
      password,
      usernameTelegram,
      chatIdTelegram,
      status,
    );
  }
}