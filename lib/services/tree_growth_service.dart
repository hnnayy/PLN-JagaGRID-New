import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tree_growth.dart';

class TreeGrowthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'tree_growth';

  // Stream hanya data aktif (status = 1) dengan penanganan error
  Stream<List<TreeGrowth>> watchAll() {
    try {
      return _db
          .collection(_collection)
          .where('status', isEqualTo: 1)
          .orderBy('name')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => TreeGrowth.fromMap(d.data(), d.id))
              .toList());
    } catch (e) {
      print('Error watching all: $e');
      return Stream.value([]); // Return empty list on error
    }
  }

  // Ambil hanya data aktif (status = 1) dengan penanganan error
  Future<List<TreeGrowth>> fetchAll() async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('status', isEqualTo: 1)
          .orderBy('name')
          .get();
      return snap.docs.map((d) => TreeGrowth.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      print('Error fetching all: $e');
      return [];
    }
  }

  // Buat data baru dengan status aktif
  Future<TreeGrowth> create(String name, double growthRate) async {
    try {
      final now = DateTime.now();
      final docRef = await _db.collection(_collection).add({
        'name': name,
        'growth_rate': growthRate,
        'created_at': Timestamp.fromDate(now),
        'status': 1,
        'deleted_at': null,
      });
      await docRef.update({'id': docRef.id});
      return TreeGrowth(
        id: docRef.id,
        name: name,
        growthRate: growthRate,
        createdAt: now,
        status: 1,
      );
    } catch (e) {
      print('Error creating: $e');
      rethrow; // Throw error untuk ditangani di layer atas
    }
  }

  // Perbarui data dengan validasi
  Future<void> update(TreeGrowth item) async {
    try {
      if (item.id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _db.collection(_collection).doc(item.id).update(item.toMap());
    } catch (e) {
      print('Error updating: $e');
      rethrow;
    }
  }

  // Soft delete (ubah status ke 0 dan set deletedAt)
  Future<void> softDelete(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _db.collection(_collection).doc(id).update({
        'status': 0,
        'deleted_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error soft deleting: $e');
      rethrow;
    }
  }

  // Hard delete (hapus permanen, jika diperlukan)
  Future<void> hardDelete(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error hard deleting: $e');
      rethrow;
    }
  }

  // Metode migrasi: Tambahkan status=1 ke semua dokumen lama yang tidak punya field status
  Future<void> migrateStatusToExistingDocuments() async {
    try {
      final snap = await _db.collection(_collection).get();
      WriteBatch batch = _db.batch();
      int operationCount = 0;

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['status'] == null) {
          batch.update(doc.reference, {
            'status': 1,
            'deleted_at': null,
          });
          operationCount++;

          if (operationCount >= 500) {
            await batch.commit();
            batch = _db.batch();
            operationCount = 0;
          }
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }
      print('Migrasi selesai: ${snap.docs.length} dokumen diperbarui.');
    } catch (e) {
      print('Error migrasi: $e');
      rethrow;
    }
  }
}