import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/service.dart';
import '../models/service_query.dart';
import '../utils/json_helpers.dart';
import 'service_repository.dart';

class PersistentServiceRepository implements ServiceRepository {
  static const _key = 'services_v2';
  final SharedPreferences _prefs;
  List<Service> _items = [];
  int _nextId = 1;

  PersistentServiceRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedServices];
      _nextId = _maxId() + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => Service.fromJson(JsonHelpers.asMap(e))).toList();
      _nextId = _maxId() + 1;
    } catch (_) {
      _items = [...seedServices];
      _nextId = _maxId() + 1;
      _persist();
    }
  }

  int _maxId() => _items.map((e) => e.id).fold(0, (a, b) => a > b ? a : b);

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Service>> find(ServiceQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _items.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.name.toLowerCase().contains(needle) ||
              b.description.toLowerCase().contains(needle))
          .toList();
    }
    if (q.clinicId != null) {
      rows = rows.where((b) => b.clinicId == q.clinicId).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'clinicId' => a.clinicId.compareTo(b.clinicId),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Service>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Service?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Service>> findAllActive() async {
    return _items.where((s) => !s.isDeleted).toList();
  }

  @override
  Future<Service> create(Service service) async {
    final item = Service(
      id: _nextId++,
      name: service.name,
      description: service.description,
      price: service.price,
      clinicId: service.clinicId,
    );
    _items.add(item);
    await _persist();
    return item;
  }

  @override
  Future<Service> update(Service service) async {
    final idx = _items.indexWhere((p) => p.id == service.id);
    if (idx < 0) throw Exception('Service not found');
    _items[idx] = service;
    await _persist();
    return service;
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
  Future<int> countByClinic(int clinicId) async {
    return _items.where((s) => !s.isDeleted && s.clinicId == clinicId).length;
  }
}
