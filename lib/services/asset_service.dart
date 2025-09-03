import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/asset_model.dart';

class AssetService {
  final CollectionReference _assetCollection =
      FirebaseFirestore.instance.collection("daftarjtm");

  /// 🔹 Ambil semua data asset secara real-time
  Stream<List<AssetModel>> getAssets() {
    return _assetCollection
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssetModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// 🔹 Ambil 1 asset by ID
  Future<AssetModel?> getAssetById(String id) async {
    final doc = await _assetCollection.doc(id).get();
    if (doc.exists) {
      return AssetModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }
    return null;
  }

  /// 🔹 Tambah asset baru
  Future<void> addAsset(AssetModel asset) async {
    await _assetCollection.add({
      ...asset.toMap(),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Update asset by ID
  Future<void> updateAsset(String id, AssetModel asset) async {
    await _assetCollection.doc(id).update(asset.toMap());
  }

  /// 🔹 Hapus asset by ID
  Future<void> deleteAsset(String id) async {
    await _assetCollection.doc(id).delete();
  }
}
