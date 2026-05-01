import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unit.dart';

class UnitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'units';

  CollectionReference get _ref => _db.collection(_collection);

  // ─── READ ─────────────────────────────────────────────────────────────────

  /// Stream hanya unit aktif (status = 1), sorted by nama_unit di Dart
  Stream<List<UnitModel>> watchAll() {
    try {
      return _ref
          .where('status', isEqualTo: 1)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => UnitModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        list.sort((a, b) => a.namaUnit.compareTo(b.namaUnit));
        return list;
      });
    } catch (e) {
      print('Error watching all units: $e');
      return Stream.value([]);
    }
  }

  /// Ambil semua unit aktif (status = 1) sekali fetch
  /// Sort dilakukan di Dart — tidak butuh composite index Firestore
  Future<List<UnitModel>> fetchAll() async {
    try {
      final snap = await _ref
          .where('status', isEqualTo: 1)
          .get(); // ← tanpa orderBy, aman tanpa index
      final list = snap.docs
          .map((d) => UnitModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      list.sort((a, b) => a.namaUnit.compareTo(b.namaUnit)); // sort di Dart
      return list;
    } catch (e) {
      print('Error fetching all units: $e');
      return [];
    }
  }

  /// Ambil satu unit by ID (hanya jika aktif)
  Future<UnitModel?> getById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      if ((data['status'] ?? 1) == 0) return null;
      return UnitModel.fromMap(data, doc.id);
    } catch (e) {
      print('Error getting unit by id: $e');
      return null;
    }
  }

  // ─── WRITE ────────────────────────────────────────────────────────────────

  /// Tambah unit baru (status = 1, deleted_at = null)
  Future<void> addUnit(UnitModel unit) async {
    try {
      final docRef = await _ref.add({
        ...unit.toMap(),
        'status': 1,
        'deleted_at': null,
      });
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error adding unit: $e');
      rethrow;
    }
  }

  /// Update unit
  Future<void> updateUnit(UnitModel unit) async {
    try {
      if (unit.id == null || unit.id!.isEmpty) {
        throw Exception('ID tidak boleh kosong');
      }
      await _ref.doc(unit.id).update(unit.toMap());
    } catch (e) {
      print('Error updating unit: $e');
      rethrow;
    }
  }

  /// Update hanya field tertentu
  Future<void> updatePartial(String id, Map<String, dynamic> data) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _ref.doc(id).update(data);
    } catch (e) {
      print('Error partial updating unit: $e');
      rethrow;
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// Soft delete → status = 0 + catat deleted_at
  Future<void> softDelete(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _ref.doc(id).update({
        'status': 0,
        'deleted_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error soft deleting unit: $e');
      rethrow;
    }
  }

  /// Restore unit yang sudah di-soft delete
  Future<void> restore(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _ref.doc(id).update({
        'status': 1,
        'deleted_at': null,
      });
    } catch (e) {
      print('Error restoring unit: $e');
      rethrow;
    }
  }

  /// Hard delete → hapus permanen dari Firestore
  Future<void> hardDelete(String id) async {
    try {
      if (id.isEmpty) throw Exception('ID tidak boleh kosong');
      await _ref.doc(id).delete();
    } catch (e) {
      print('Error hard deleting unit: $e');
      rethrow;
    }
  }

  // ─── VALIDATION ───────────────────────────────────────────────────────────

  /// Cek apakah kode unit sudah ada dan aktif
  Future<bool> isKodeUnitExist(String kodeUnit) async {
    try {
      final result = await _ref
          .where('kode_unit', isEqualTo: kodeUnit.toUpperCase())
          .where('status', isEqualTo: 1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking kode unit: $e');
      return false;
    }
  }

  /// Cek kode unit sudah ada, exclude dokumen tertentu (untuk edit)
  Future<bool> isKodeUnitExistExclude(String kodeUnit, String excludeId) async {
    try {
      final result = await _ref
          .where('kode_unit', isEqualTo: kodeUnit.toUpperCase())
          .where('status', isEqualTo: 1)
          .get();
      return result.docs.any((doc) => doc.id != excludeId);
    } catch (e) {
      print('Error checking kode unit exclude: $e');
      return false;
    }
  }

  /// Cek apakah nama unit sudah ada dan aktif
  Future<bool> isNamaUnitExist(String namaUnit) async {
    try {
      final result = await _ref
          .where('nama_unit', isEqualTo: namaUnit.toUpperCase())
          .where('status', isEqualTo: 1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking nama unit: $e');
      return false;
    }
  }

  /// Cek nama unit sudah ada, exclude dokumen tertentu (untuk edit)
  Future<bool> isNamaUnitExistExclude(String namaUnit, String excludeId) async {
    try {
      final result = await _ref
          .where('nama_unit', isEqualTo: namaUnit.toUpperCase())
          .where('status', isEqualTo: 1)
          .get();
      return result.docs.any((doc) => doc.id != excludeId);
    } catch (e) {
      print('Error checking nama unit exclude: $e');
      return false;
    }
  }

  /// Ambil kode unit berdasarkan nama unit (hanya yang aktif)
  Future<String?> getKodeByNamaUnit(String namaUnit) async {
    try {
      final result = await _ref
          .where('nama_unit', isEqualTo: namaUnit.toUpperCase())
          .where('status', isEqualTo: 1)
          .limit(1)
          .get();
      if (result.docs.isEmpty) return null;
      final data = result.docs.first.data() as Map<String, dynamic>;
      return data['kode_unit'] as String?;
    } catch (e) {
      print('Error getting kode by nama unit: $e');
      return null;
    }
  }

  // ─── MIGRATION ────────────────────────────────────────────────────────────

  /// Jalankan SEKALI untuk dokumen lama yang belum punya field 'status'.
  Future<void> migrateExistingUnits() async {
    try {
      final snap = await _ref.get();
      WriteBatch batch = _db.batch();
      int operationCount = 0;
      int totalMigrated = 0;

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['status'] == null) {
          batch.update(doc.reference, {
            'status': 1,
            'deleted_at': null,
          });
          operationCount++;
          totalMigrated++;

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

      print('[UnitService] Migrasi selesai: $totalMigrated dokumen diperbarui.');
    } catch (e) {
      print('[UnitService] Error migrasi: $e');
      rethrow;
    }
  }
}