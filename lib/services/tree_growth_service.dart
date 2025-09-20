import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tree_growth.dart';

class TreeGrowthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'tree_growth';

  Stream<List<TreeGrowth>> watchAll() {
    return _db
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TreeGrowth.fromMap(d.data(), d.id))
            .toList());
  }

  Future<List<TreeGrowth>> fetchAll() async {
    final snap = await _db.collection(_collection).orderBy('name').get();
    return snap.docs.map((d) => TreeGrowth.fromMap(d.data(), d.id)).toList();
  }

  Future<TreeGrowth> create(String name, double growthRate) async {
    final now = DateTime.now();
    final docRef = await _db.collection(_collection).add({
      'name': name,
      'growth_rate': growthRate,
      'created_at': Timestamp.fromDate(now),
    });
    await docRef.update({'id': docRef.id});
    return TreeGrowth(id: docRef.id, name: name, growthRate: growthRate, createdAt: now);
  }

  Future<void> update(TreeGrowth item) async {
    await _db.collection(_collection).doc(item.id).update({
      'name': item.name,
      'growth_rate': item.growthRate,
    });
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
