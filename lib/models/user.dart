class UserModel {
  final String? id;
  final String name;
  final String username;
  final String unit;
  final String kodeUnit; // ← field baru: kode unit otomatis dari UnitModel
  final int level; // 1 = unit induk, 2 = unit layanan
  final String added;
  final String password;
  final String usernameTelegram;
  final String chatIdTelegram;
  final int status; // 1 = aktif, 0 = terhapus (soft delete)

  UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.unit,
    this.kodeUnit = '',
    required this.level,
    required this.added,
    required this.password,
    required this.usernameTelegram,
    required this.chatIdTelegram,
    this.status = 1,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? unit,
    String? kodeUnit,
    int? level,
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
      kodeUnit: kodeUnit ?? this.kodeUnit,
      level: level ?? this.level,
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
      kodeUnit: map['kode_unit'] ?? '',
      level: map['level'] ?? 2,
      added: map['added'] ?? '',
      password: map['password'] ?? '',
      usernameTelegram: map['username_telegram'] ?? '',
      chatIdTelegram: map['chat_id_telegram'] ?? '',
      status: map['status'] ?? 1,
    );
  }

  /// Convert ke Map (App → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'unit': unit,
      'kode_unit': kodeUnit,
      'level': level,
      'added': added,
      'password': password,
      'username_telegram': usernameTelegram,
      'chat_id_telegram': chatIdTelegram,
      'status': status,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      unit: json['unit'] ?? '',
      kodeUnit: json['kode_unit'] ?? '',
      level: json['level'] ?? 2,
      added: json['added'] ?? '',
      password: json['password'] ?? '',
      usernameTelegram: json['username_telegram'] ?? '',
      chatIdTelegram: json['chat_id_telegram'] ?? '',
      status: json['status'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'unit': unit,
      'kode_unit': kodeUnit,
      'level': level,
      'added': added,
      'password': password,
      'username_telegram': usernameTelegram,
      'chat_id_telegram': chatIdTelegram,
      'status': status,
    };
  }

  bool get isActive => status == 1;
  bool get isDeleted => status == 0;
  bool get isInduk => level == 1;
  bool get isLayanan => level == 2;

  UserModel markAsDeleted() => copyWith(status: 0);
  UserModel markAsActive() => copyWith(status: 1);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, username: $username, unit: $unit, kodeUnit: $kodeUnit, level: $level, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.username == username &&
        other.unit == unit &&
        other.kodeUnit == kodeUnit &&
        other.level == level &&
        other.added == added &&
        other.password == password &&
        other.usernameTelegram == usernameTelegram &&
        other.chatIdTelegram == chatIdTelegram &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id, name, username, unit, kodeUnit,
      level, added, password, usernameTelegram,
      chatIdTelegram, status,
    );
  }
}