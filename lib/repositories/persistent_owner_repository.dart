import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/owner.dart';
import '../models/owner_query.dart';
import '../utils/json_helpers.dart';
import 'owner_repository.dart';

class PersistentOwnerRepository implements OwnerRepository {
  static const _key = 'owners_v2';
  final SharedPreferences _prefs;
  List<Owner> _owners = [];
  int _nextId = 1;

  PersistentOwnerRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _owners = [...seedOwners];
      _nextId = _maxId() + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _owners = list.map((e) => Owner.fromJson(JsonHelpers.asMap(e))).toList();
      _nextId = _maxId() + 1;
    } catch (_) {
      _owners = [...seedOwners];
      _nextId = _maxId() + 1;
      _persist();
    }
  }

  int _maxId() => _owners.map((e) => e.id).fold(0, (a, b) => a > b ? a : b);

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_owners.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Owner>> find(OwnerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _owners.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.lastName.toLowerCase().contains(needle) ||
              b.firstName.toLowerCase().contains(needle) ||
              b.email.toLowerCase().contains(needle) ||
              b.phone.contains(needle) ||
              b.country.toLowerCase().contains(needle))
          .toList();
    }
    if (q.city != null && q.city!.isNotEmpty) {
      rows = rows.where((b) => b.city == q.city).toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((b) => b.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Owner>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Owner?> findById(int id) async {
    try {
      return _owners.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Owner>> findAllActive() async {
    return _owners.where((o) => !o.isDeleted).toList();
  }

  @override
  Future<Owner> create(Owner owner) async {
    final newOwner = Owner(
      id: _nextId++,
      lastName: owner.lastName,
      firstName: owner.firstName,
      phone: owner.phone,
      email: owner.email,
      city: owner.city,
      country: owner.country,
    );
    _owners.add(newOwner);
    await _persist();
    return newOwner;
  }

  @override
  Future<Owner> update(Owner owner) async {
    final idx = _owners.indexWhere((p) => p.id == owner.id);
    if (idx < 0) throw Exception('Owner not found');
    _owners[idx] = owner;
    await _persist();
    return owner;
  }

  @override
  Future<void> softDelete(int id) async {
    final idx = _owners.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _owners[idx] = _owners[idx].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _owners.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final idx = _owners.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _owners[idx] = _owners[idx].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _owners.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _owners[i] = _owners[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    final needle = email.trim().toLowerCase();
    return !_owners.any((p) =>
        !p.isDeleted &&
        p.email.toLowerCase() == needle &&
        p.id != excludeId);
  }

  @override
  Future<List<String>> distinctCities() async {
    final cities = _owners.where((o) => !o.isDeleted).map((o) => o.city).toSet().toList();
    cities.sort();
    return cities;
  }
}
