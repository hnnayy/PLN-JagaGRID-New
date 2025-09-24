import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/asset_model.dart';

class AssetService {
  final CollectionReference _assetCollection =
      FirebaseFirestore.instance.collection("daftarjtm");

  /// 🔹 Ambil semua data asset secara real-time, hanya yang aktif (status = 1)
  Stream<List<AssetModel>> getAssets() {
    return _assetCollection
        .where('status', isEqualTo: 1)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssetModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// 🔹 Ambil 1 asset by ID, hanya jika aktif (status = 1)
  Future<AssetModel?> getAssetById(String id) async {
    try {
      final doc = await _assetCollection.doc(id).get();
      if (doc.exists && (doc.data() as Map<String, dynamic>)['status'] == 1) {
        return AssetModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting asset by ID: $e');
      rethrow;
    }
  }

  /// 🔹 Tambah asset baru, default status = 1 (aktif)
  Future<void> addAsset(AssetModel asset) async {
    try {
      await _assetCollection.add({
        ...asset.toMap(),
        'status': 1, // Pastikan status aktif saat ditambahkan
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding asset: $e');
      rethrow;
    }
  }

  /// 🔹 Update asset by AssetModel (method utama untuk edit)
  Future<void> updateAsset(AssetModel asset) async {
    try {
      await _assetCollection.doc(asset.id).update(asset.toUpdateMap());
    } catch (e) {
      print('Error updating asset: $e');
      rethrow;
    }
  }

  /// 🔹 Update asset by ID dan AssetModel (method alternatif)
  Future<void> updateAssetById(String id, AssetModel asset) async {
    try {
      await _assetCollection.doc(id).update(asset.toUpdateMap());
    } catch (e) {
      print('Error updating asset by ID: $e');
      rethrow;
    }
  }

  /// 🔹 Update field tertentu saja
  Future<void> updateAssetFields(String id, Map<String, dynamic> fields) async {
    try {
      await _assetCollection.doc(id).update(fields);
    } catch (e) {
      print('Error updating asset fields: $e');
      rethrow;
    }
  }

  /// 🔹 Soft delete asset by ID (set status = 0)
  Future<void> deleteAsset(String id) async {
    try {
      await _assetCollection.doc(id).update({'status': 0});
    } catch (e) {
      print('Error soft deleting asset: $e');
      rethrow;
    }
  }

  /// 🔹 Batch update multiple assets
  Future<void> updateMultipleAssets(List<AssetModel> assets) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final asset in assets) {
        final docRef = _assetCollection.doc(asset.id);
        batch.update(docRef, asset.toUpdateMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error batch updating assets: $e');
      rethrow;
    }
  }

  /// 🔹 Check apakah asset dengan ID tertentu ada dan aktif
  Future<bool> assetExists(String id) async {
    try {
      final doc = await _assetCollection.doc(id).get();
      return doc.exists && (doc.data() as Map<String, dynamic>)['status'] == 1;
    } catch (e) {
      print('Error checking asset existence: $e');
      return false;
    }
  }

  /// 🔹 Get total count assets yang aktif
  Future<int> getAssetCount() async {
    try {
      final snapshot = await _assetCollection.where('status', isEqualTo: 1).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting asset count: $e');
      return 0;
    }
  }

  /// 🔹 Ambil assets berdasarkan penyulang, hanya yang aktif
  Future<List<AssetModel>> getAssetsByPenyulang(String penyulang) async {
    try {
      final snapshot = await _assetCollection
          .where('penyulang', isEqualTo: penyulang)
          .where('status', isEqualTo: 1)
          .get();
      return snapshot.docs
          .map((doc) => AssetModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting assets by penyulang: $e');
      rethrow;
    }
  }

  /// 🔹 Cari asset yang paling cocok berdasarkan kombinasi beberapa field
  /// Strategi: query berdasarkan penyulang dulu, hanya yang aktif, lalu filter di memori
  Future<AssetModel?> findBestMatchingAsset({
    required String penyulang,
    String? section,
    String? zonaProteksi,
    String? up3,
    String? ulp,
  }) async {
    try {
      // Ambil kandidat berdasarkan penyulang, hanya yang aktif
      final candidates = await getAssetsByPenyulang(penyulang);
      if (candidates.isEmpty) return null;

      // Skor kecocokan berdasarkan jumlah field yang cocok
      AssetModel? best;
      int bestScore = -1;

      for (final a in candidates) {
        int score = 0;
        if (section != null && section.isNotEmpty && a.section.trim().toLowerCase() == section.trim().toLowerCase()) {
          score += 2; // section lebih spesifik, beri bobot lebih
        }
        if (zonaProteksi != null && zonaProteksi.isNotEmpty &&
            a.zonaProteksi.trim().toLowerCase() == zonaProteksi.trim().toLowerCase()) {
          score += 2; // zona juga cukup spesifik
        }
        if (up3 != null && up3.isNotEmpty && a.up3.trim().toLowerCase() == up3.trim().toLowerCase()) {
          score += 1;
        }
        if (ulp != null && ulp.isNotEmpty && a.ulp.trim().toLowerCase() == ulp.trim().toLowerCase()) {
          score += 1;
        }

        if (score > bestScore) {
          bestScore = score;
          best = a;
        }
      }

      return best;
    } catch (e) {
      print('Error finding best matching asset: $e');
      return null;
    }
  }
}