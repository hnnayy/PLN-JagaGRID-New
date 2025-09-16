import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  // Update hanya field tertentu
  Future<void> updateUserPartial(String docId, Map<String, dynamic> data) async {
    await usersCollection.doc(docId).update(data);
  }
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Tambah user
  Future<void> addUser(UserModel user) async {
    await usersCollection.add(user.toMap());
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    if (user.id == null) return;
    await usersCollection.doc(user.id).update(user.toMap());
  }

  // Hapus user
  Future<void> deleteUser(String id) async {
    await usersCollection.doc(id).delete();
  }

  // Ambil semua user (Realtime Stream)
  Stream<List<UserModel>> getUsers() {
    return usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Ambil satu user by ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await usersCollection.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
