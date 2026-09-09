import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/clinic.dart';
import '../models/clinic_query.dart';
import '../utils/json_helpers.dart';
import 'clinic_repository.dart';

class PersistentClinicRepository implements ClinicRepository {
  static const _key = 'clinics_v2';
  final SharedPreferences _prefs;
  List<Clinic> _items = [];
  int _nextId = 1;

  PersistentClinicRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedClinics];
      _nextId = _maxId() + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => Clinic.fromJson(JsonHelpers.asMap(e))).toList();
      _nextId = _maxId() + 1;
    } catch (_) {
      _items = [...seedClinics];
      _nextId = _maxId() + 1;
      _persist();
    }
  }

  int _maxId() => _items.map((e) => e.id).fold(0, (a, b) => a > b ? a : b);

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Clinic>> find(ClinicQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _items.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.name.toLowerCase().contains(needle) ||
              b.address.toLowerCase().contains(needle) ||
              b.city.toLowerCase().contains(needle))
          .toList();
    }
    if (q.city != null && q.city!.isNotEmpty) {
      rows = rows.where((b) => b.city == q.city).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'address' => a.address.toLowerCase().compareTo(b.address.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Clinic>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Clinic?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Clinic>> findAllActive() async {
    return _items.where((s) => !s.isDeleted).toList();
  }

  @override
  Future<Clinic> create(Clinic clinic) async {
    final item = Clinic(
      id: _nextId++,
      name: clinic.name,
      address: clinic.address,
      phone: clinic.phone,
      city: clinic.city,
    );
    _items.add(item);
    await _persist();
    return item;
  }

  @override
  Future<Clinic> update(Clinic clinic) async {
    final idx = _items.indexWhere((p) => p.id == clinic.id);
    if (idx < 0) throw Exception('Clinic not found');
    _items[idx] = clinic;
    await _persist();
    return clinic;
  }

  @override
  Future<void> softDelete(int id) async {
    final idx = _items.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final idx = _items.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isNameUnique(String name, {int? excludeId}) async {
    return !_items.any((p) =>
        !p.isDeleted &&
        p.name.toLowerCase() == name.trim().toLowerCase() &&
        p.id != excludeId);
  }

  @override
  Future<List<String>> distinctCities() async {
    final cities = _items.where((c) => !c.isDeleted).map((c) => c.city).toSet().toList();
    cities.sort();
    return cities;
  }
}
