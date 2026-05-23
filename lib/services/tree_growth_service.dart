import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tree_growth.dart';

class TreeGrowthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'tree_growth';

  // ─────────────────────────────────────────
  // Stream data aktif:
  // - Kalau unit kosong/null → tampil semua (Admin UP3)
  // - Kalau ada unit → tampil global (unit='all') + milik unit sendiri
  // ─────────────────────────────────────────
  Stream<List<TreeGrowth>> watchAll({String? sessionUnit}) {
    try {
      return _db
          .collection(_collection)
          .where('status', isEqualTo: 1)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => TreeGrowth.fromMap(d.data(), d.id))
            .where((item) {
          // Admin UP3 (sessionUnit null/kosong) → lihat semua
          if (sessionUnit == null || sessionUnit.isEmpty) return true;
          // ULP → lihat global + milik sendiri
          return item.unit == 'all' ||
              item.unit.toLowerCase() == sessionUnit.toLowerCase();
        }).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
    } catch (e) {
      print('Error watching all: $e');
      return Stream.value([]);
    }
  }

  // Ambil data aktif
  Future<List<TreeGrowth>> fetchAll({String? sessionUnit}) async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('status', isEqualTo: 1)
          .get();

      final list = snap.docs
          .map((d) => TreeGrowth.fromMap(d.data(), d.id))
          .where((item) {
        if (sessionUnit == null || sessionUnit.isEmpty) return true;
        return item.unit == 'all' ||
            item.unit.toLowerCase() == sessionUnit.toLowerCase();
      }).toList();

      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    } catch (e) {
      print('Error fetching all: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // Buat data baru
  // - Admin UP3 → unit = 'all' (global)
  // - ULP → unit = nama ULP mereka
  // ─────────────────────────────────────────
  Future<TreeGrowth> create(String name, double growthRate,
      {String unit = 'all'}) async {
    try {
      final now = DateTime.now();
      final docRef = await _db.collection(_collection).add({
        'name': name,
        'growth_rate': growthRate,
        'created_at': Timestamp.fromDate(now),
        'status': 1,
        'deleted_at': null,
        'unit': unit,
      });
      await docRef.update({'id': docRef.id});
      return TreeGrowth(
        id: docRef.id,
        name: name,
        growthRate: growthRate,
        createdAt: now,
        status: 1,
        unit: unit,
      );
    } catch (e) {
      print('Error creating: $e');
      rethrow;
    }
  }

  // Perbarui data
  Future<void> update(TreeGrowth item) async {
    try {
      if (item.id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _db.collection(_collection).doc(item.id).update(item.toMap());
    } catch (e) {
      print('Error updating: $e');
      rethrow;
    }
  }

  // Soft delete
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

  // Hard delete
  Future<void> hardDelete(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error hard deleting: $e');
      rethrow;
    }
  }

  // Migrasi data lama → set unit = 'all'
  Future<void> migrateStatusToExistingDocuments() async {
    try {
      final snap = await _db.collection(_collection).get();
      WriteBatch batch = _db.batch();
      int operationCount = 0;

      for (var doc in snap.docs) {
        final data = doc.data();
        final needsUpdate =
            data['status'] == null || data['unit'] == null;
        if (needsUpdate) {
          batch.update(doc.reference, {
            if (data['status'] == null) 'status': 1,
            if (data['deleted_at'] == null) 'deleted_at': null,
            if (data['unit'] == null) 'unit': 'all', // Data lama → global
          });
          operationCount++;
          if (operationCount >= 500) {
            await batch.commit();
            batch = _db.batch();
            operationCount = 0;
          }
        }
      }

      if (operationCount > 0) await batch.commit();
      print('Migrasi selesai: ${snap.docs.length} dokumen diperbarui.');
    } catch (e) {
      print('Error migrasi: $e');
      rethrow;
    }
  }
}