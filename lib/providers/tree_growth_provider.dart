import 'package:flutter/material.dart';
import '../models/tree_growth.dart';
import '../services/tree_growth_service.dart';

class TreeGrowthProvider with ChangeNotifier {
  final TreeGrowthService _service = TreeGrowthService();
  List<TreeGrowth> _items = [];
  bool _loading = false;
  String? _error;

  List<TreeGrowth> get items => _items;
  bool get isLoading => _loading;
  String? get errorMessage => _error;

  // Stream data aktif
  Stream<List<TreeGrowth>> watchAll() => _service.watchAll();

  // Muat data aktif
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchAll();
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Tambah data baru
  Future<bool> add(String name, double growthRate) async {
    try {
      final created = await _service.create(name, growthRate);
      _items = [..._items, created]..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah data: $e';
      notifyListeners();
      return false;
    }
  }

  // Perbarui data
  Future<bool> update(TreeGrowth item) async {
    try {
      await _service.update(item);
      final idx = _items.indexWhere((x) => x.id == item.id);
      if (idx != -1) {
        _items[idx] = item;
        _items.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Gagal memperbarui data: $e';
      notifyListeners();
      return false;
    }
  }

  // Soft delete data
  Future<bool> remove(String id) async {
    try {
      await _service.softDelete(id);
      _items.removeWhere((x) => x.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus data: $e';
      notifyListeners();
      return false;
    }
  }

  // Jalankan migrasi status (sekali saja)
  Future<void> migrateData() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.migrateStatusToExistingDocuments();
      _items = await _service.fetchAll(); // Reload data setelah migrasi
    } catch (e) {
      _error = 'Gagal migrasi data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}