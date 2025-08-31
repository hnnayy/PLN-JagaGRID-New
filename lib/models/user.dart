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

  // Convert dari Map (Firestore → App)
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

  // Convert ke Map (App → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'unit': unit,
      'added': added,
      'password': password,
    };
  }
}
