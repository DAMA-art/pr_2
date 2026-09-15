import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';
import '../utils/json_helpers.dart';
import 'pet_passport_repository.dart';

class PersistentPetPassportRepository implements PetPassportRepository {
  static const _key = 'pet_passports_v2';
  final SharedPreferences _prefs;
  List<PetPassport> _items = [];
  int _nextId = 1;

  PersistentPetPassportRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedPetPassports];
      _nextId = _maxId() + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => PetPassport.fromJson(JsonHelpers.asMap(e)))
          .toList();
      _nextId = _maxId() + 1;
    } catch (_) {
      _items = [...seedPetPassports];
      _nextId = _maxId() + 1;
      _persist();
    }
  }

  int _maxId() => _items.map((e) => e.id).fold(0, (a, b) => a > b ? a : b);

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<PageResult<PetPassport>> find(PetPassportQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _items.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.number.toLowerCase().contains(needle) ||
                b.microchip.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.petId != null) {
      rows = rows.where((b) => b.petId == q.petId).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'issuedAt' => a.issuedAt.compareTo(b.issuedAt),
        'microchip' => a.microchip.toLowerCase().compareTo(
          b.microchip.toLowerCase(),
        ),
        _ => a.number.toLowerCase().compareTo(b.number.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <PetPassport>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<PetPassport?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PetPassport?> findByPetId(int petId) async {
    try {
      return _items.firstWhere((p) => p.petId == petId && !p.isDeleted);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PetPassport>> findAllActive() async {
    return _items.where((p) => !p.isDeleted).toList();
  }

  @override
  Future<PetPassport> create(PetPassport passport) async {
    final item = PetPassport(
      id: _nextId++,
      petId: passport.petId,
      number: passport.number,
      microchip: passport.microchip,
      issuedAt: passport.issuedAt,
    );
    _items.add(item);
    await _persist();
    return item;
  }

  @override
  Future<PetPassport> update(PetPassport passport) async {
    final idx = _items.indexWhere((p) => p.id == passport.id);
    if (idx < 0) throw Exception('PetPassport not found');
    _items[idx] = passport;
    await _persist();
    return passport;
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
  Future<bool> isNumberUnique(String number, {int? excludeId}) async {
    final needle = number.trim().toLowerCase();
    return !_items.any(
      (p) =>
          !p.isDeleted && p.number.toLowerCase() == needle && p.id != excludeId,
    );
  }

  @override
  Future<bool> isPetFree(int petId, {int? excludeId}) async {
    return !_items.any(
      (p) => !p.isDeleted && p.petId == petId && p.id != excludeId,
    );
  }
}
