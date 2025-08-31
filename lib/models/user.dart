class UserModel {
  final String? id; // Firestore document ID
  final String name;
  final String username;
  final String unit;
  final String added;
  final String password;

  UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.unit,
    required this.added,
    required this.password,
  });

  /// Buat copy data dengan nilai baru
  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? unit,
    String? added,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      unit: unit ?? this.unit,
      added: added ?? this.added,
      password: password ?? this.password,
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
    };
  }

  /// Convert dari JSON (misalnya API → App)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      unit: json['unit'],
      added: json['added'],
      password: json['password'],
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
    };
  }
}
