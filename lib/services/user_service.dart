import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ─── READ ─────────────────────────────────────────────────────────────────

  /// Stream semua user aktif (status = 1)
  Stream<List<UserModel>> getUsers() {
    return usersCollection
        .where('status', isEqualTo: 1)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort by added descending (karena tidak bisa orderBy + where tanpa composite index)
      list.sort((a, b) => b.added.compareTo(a.added));
      return list;
    });
  }

  /// Ambil satu user by ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await usersCollection.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    if ((data['status'] ?? 1) == 0) return null;
    return UserModel.fromMap(data, doc.id);
  }

  // ─── WRITE ────────────────────────────────────────────────────────────────

  /// Tambah user baru dengan auto-generate ID
  Future<void> addUser(UserModel user) async {
    final docRef = await usersCollection.add({
      ...user.toMap(),
      'status': 1,
      'deleted_at': null,
    });
    await docRef.update({'id': docRef.id});
  }

  /// Update seluruh data user
  Future<void> updateUser(UserModel user) async {
    if (user.id == null) return;
    await usersCollection.doc(user.id).update(user.toMap());
  }

  /// Update hanya field tertentu
  Future<void> updateUserPartial(String docId, Map<String, dynamic> data) async {
    await usersCollection.doc(docId).update(data);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// Soft delete → status = 0
  Future<void> softDeleteUser(String id) async {
    await usersCollection.doc(id).update({
      'status': 0,
      'deleted_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Restore user yang di-soft delete
  Future<void> restoreUser(String id) async {
    await usersCollection.doc(id).update({
      'status': 1,
      'deleted_at': null,
    });
  }

  /// Hard delete → hapus permanen
  Future<void> deleteUser(String id) async {
    await usersCollection.doc(id).delete();
  }

  // ─── VALIDATION ───────────────────────────────────────────────────────────

  /// Cek username sudah terdaftar (user aktif)
  Future<bool> isUsernameExist(String username) async {
    final normalized = username.startsWith('@') ? username : '@$username';
    final result = await usersCollection
        .where('username', isEqualTo: normalized)
        .where('status', isEqualTo: 1)
        .get();
    return result.docs.isNotEmpty;
  }

  /// Cek username sudah terdaftar, exclude ID tertentu (untuk edit)
  Future<bool> isUsernameExistExclude(String username, String excludeId) async {
    final normalized = username.startsWith('@') ? username : '@$username';
    final result = await usersCollection
        .where('username', isEqualTo: normalized)
        .where('status', isEqualTo: 1)
        .get();
    return result.docs.any((doc) => doc.id != excludeId);
  }

  /// Cek chat ID Telegram sudah terdaftar (user aktif)
  Future<bool> isChatIdExist(String chatId) async {
    final result = await usersCollection
        .where('chat_id_telegram', isEqualTo: chatId)
        .where('status', isEqualTo: 1)
        .get();
    return result.docs.isNotEmpty;
  }

  /// Cek chat ID Telegram sudah terdaftar, exclude ID tertentu (untuk edit)
  Future<bool> isChatIdExistExclude(String chatId, String excludeId) async {
    final result = await usersCollection
        .where('chat_id_telegram', isEqualTo: chatId)
        .where('status', isEqualTo: 1)
        .get();
    return result.docs.any((doc) => doc.id != excludeId);
  }
}