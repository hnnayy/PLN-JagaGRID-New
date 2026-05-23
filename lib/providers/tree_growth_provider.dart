import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_growth.dart';
import '../services/tree_growth_service.dart';

class TreeGrowthProvider with ChangeNotifier {
  final TreeGrowthService _service = TreeGrowthService();
  List<TreeGrowth> _items = [];
  bool _loading = false;
  String? _error;
  String _sessionUnit = '';
  int _sessionLevel = 1;

  List<TreeGrowth> get items => _items;
  bool get isLoading => _loading;
  String? get errorMessage => _error;
  String get sessionUnit => _sessionUnit;
  int get sessionLevel => _sessionLevel;

  // Stream data aktif sesuai session
  Stream<List<TreeGrowth>> watchAll() =>
      _service.watchAll(sessionUnit: _sessionLevel == 1 ? null : _sessionUnit);

  // Muat session + data
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Ambil session
      final prefs = await SharedPreferences.getInstance();
      _sessionLevel = prefs.getInt('session_level') ?? 1;
      _sessionUnit = prefs.getString('session_unit') ?? '';

      _items = await _service.fetchAll(
          sessionUnit: _sessionLevel == 1 ? null : _sessionUnit);
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Tambah data baru
  // Admin UP3 → unit = 'all' (global)
  // User ULP → unit = nama ULP mereka
  Future<bool> add(String name, double growthRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt('session_level') ?? 1;
      final unit = level == 1
          ? 'all'
          : (prefs.getString('session_unit') ?? 'all');

      final created = await _service.create(name, growthRate, unit: unit);
      _items = [..._items, created]..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menambah data: $e';
      notifyListeners();
      return false;
    }
  }

  // Perbarui data — hanya bisa kalau milik sendiri atau Admin
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

  // Soft delete — hanya bisa kalau milik sendiri atau Admin
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

  // Migrasi data lama
  Future<void> migrateData() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.migrateStatusToExistingDocuments();
      _items = await _service.fetchAll(
          sessionUnit: _sessionLevel == 1 ? null : _sessionUnit);
    } catch (e) {
      _error = 'Gagal migrasi data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}