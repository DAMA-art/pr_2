import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';
import '../utils/json_helpers.dart';
import 'pet_repository.dart';

class PersistentPetRepository implements PetRepository {
  static const _key = 'pets_v2';
  final SharedPreferences _prefs;
  List<Pet> _pets = [];
  int _nextId = 1;

  PersistentPetRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _pets = [...seedPets];
      _nextId = _maxId(_pets) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _pets = list
          .map((e) => Pet.fromJson(JsonHelpers.asMap(e)))
          .toList();
      _nextId = _maxId(_pets) + 1;
    } catch (_) {
      _pets = [...seedPets];
      _nextId = _maxId(_pets) + 1;
      _persist();
    }
  }

  int _maxId(List<Pet> items) =>
      items.map((e) => e.id).fold(0, (a, b) => a > b ? a : b);

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_pets.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Pet>> find(PetQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _pets.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.name.toLowerCase().contains(needle) ||
              b.breed.toLowerCase().contains(needle) ||
              b.chipNumber.toLowerCase().contains(needle))
          .toList();
    }
    if (q.species != null && q.species!.isNotEmpty) {
      rows = rows.where((b) => b.species == q.species).toList();
    }
    if (q.ownerId != null) {
      rows = rows.where((b) => b.ownerIds.contains(q.ownerId)).toList();
    }
    if (q.clinicId != null) {
      rows = rows.where((b) => b.clinicId == q.clinicId).toList();
    }
    if (q.ageFrom != null) {
      rows = rows.where((b) => b.ageMonths >= q.ageFrom!).toList();
    }
    if (q.ageTo != null) {
      rows = rows.where((b) => b.ageMonths <= q.ageTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'ageMonths' => a.ageMonths.compareTo(b.ageMonths),
        'weightKg' => a.weightKg.compareTo(b.weightKg),
        'species' => a.species.compareTo(b.species),
        'chipNumber' => a.chipNumber.compareTo(b.chipNumber),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Pet>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Pet?> findById(int id) async {
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Pet>> findAllActive() async {
    return _pets.where((p) => !p.isDeleted).toList();
  }

  Pet _copyWithId(Pet pet, int id) => Pet(
        id: id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        chipNumber: pet.chipNumber,
        ageMonths: pet.ageMonths,
        weightKg: pet.weightKg,
        clinicId: pet.clinicId,
        ownerIds: List.from(pet.ownerIds),
        serviceIds: List.from(pet.serviceIds),
        notes: pet.notes,
        deletedAt: pet.deletedAt,
      );

  @override
  Future<Pet> create(Pet pet) async {
    final newPet = _copyWithId(pet, _nextId++);
    _pets.add(newPet);
    await _persist();
    return newPet;
  }

  @override
  Future<Pet> update(Pet pet) async {
    final idx = _pets.indexWhere((p) => p.id == pet.id);
    if (idx < 0) throw Exception('Pet not found');
    _pets[idx] = pet;
    await _persist();
    return pet;
  }

  @override
  Future<void> softDelete(int id) async {
    final idx = _pets.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _pets[idx] = _pets[idx].copyWith(deletedAt: DateTime.now());
      await _persist();
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    _pets.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final idx = _pets.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _pets[idx] = _pets[idx].copyWith(clearDeletedAt: true);
      await _persist();
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _pets.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _pets[i] = _pets[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isChipUnique(String chipNumber, {int? excludeId}) async {
    final needle = chipNumber.trim().toLowerCase();
    return !_pets.any((p) =>
        !p.isDeleted &&
        p.chipNumber.toLowerCase() == needle &&
        p.id != excludeId);
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    return _pets.where((p) => !p.isDeleted && p.ownerIds.contains(ownerId)).length;
  }

  @override
  Future<int> countByClinic(int clinicId) async {
    return _pets.where((p) => !p.isDeleted && p.clinicId == clinicId).length;
  }
}
