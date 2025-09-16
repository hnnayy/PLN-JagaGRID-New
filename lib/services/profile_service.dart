import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/profile.dart';

class ProfileService {
  final CollectionReference profilesRef =
      FirebaseFirestore.instance.collection('profiles');

  // ➕ Tambah profile baru (auto createdAt & updatedAt)
  Future<String> addProfile(Profile profile) async {
    final docRef = await profilesRef.add(profile.toMap(isUpdate: false));
    return docRef.id;
  }

  // 🔍 Ambil profile berdasarkan docId
  Future<Profile?> getProfile(String docId) async {
    final doc = await profilesRef.doc(docId).get();
    if (doc.exists) {
      return Profile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // ✏️ Update profile (auto updatedAt)
  Future<void> updateProfile(Profile profile) async {
    await profilesRef.doc(profile.id).update(profile.toMap(isUpdate: true));
  }

  // ❌ Hapus profile
  Future<void> deleteProfile(String docId) async {
    await profilesRef.doc(docId).delete();
  }

  // 🔄 Stream realtime profile
  Stream<Profile?> streamProfile(String docId) {
    return profilesRef.doc(docId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Profile.fromMap(
          snapshot.id,
          snapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    });
  }
}
