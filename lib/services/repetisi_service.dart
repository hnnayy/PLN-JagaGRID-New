import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/repetisi.dart';

class RepetisiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'repetisi';

  // Tambah data repetisi baru
  Future<void> addRepetisi(Repetisi repetisi) async {
    try {
      final docRef = await _db.collection(_collectionName).add(
        repetisi.toMap()
          ..['createdDate'] = FieldValue.serverTimestamp(), // Default timestamp server
      );
      // Update id dokumen ke field 'id' jika diperlukan (opsional)
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error menambah repetisi: $e');
      rethrow;
    }
  }

  // Dapatkan semua data repetisi (stream untuk real-time update)
  Stream<List<Repetisi>> getAllRepetisi() {
    return _db.collection(_collectionName).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Repetisi.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  // Dapatkan repetisi berdasarkan ID
  Future<Repetisi?> getRepetisiById(String id) async {
    try {
      final doc = await _db.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return Repetisi.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error mendapatkan repetisi: $e');
      return null;
    }
  }

  // Update data repetisi (misalnya update status atau tujuan)
  Future<void> updateRepetisi(String id, Map<String, dynamic> updates) async {
    try {
      await _db.collection(_collectionName).doc(id).update(updates);
    } catch (e) {
      print('Error update repetisi: $e');
      rethrow;
    }
  }

  // Hapus repetisi
  Future<void> deleteRepetisi(String id) async {
    try {
      await _db.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print('Error hapus repetisi: $e');
      rethrow;
    }
  }

  // Query: Dapatkan repetisi berdasarkan data_pohon_id
  Stream<List<Repetisi>> getRepetisiByDataPohonId(String dataPohonId) {
    return _db.collection(_collectionName)
        .where('dataPohonId', isEqualTo: dataPohonId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Repetisi.fromMap(doc.data(), doc.id)).toList());
  }

  // Query: Dapatkan repetisi berdasarkan eksekusi_id
  Stream<List<Repetisi>> getRepetisiByEksekusiId(String eksekusiId) {
    return _db.collection(_collectionName)
        .where('eksekusiId', isEqualTo: eksekusiId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Repetisi.fromMap(doc.data(), doc.id)).toList());
  }
}