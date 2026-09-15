import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';
import 'pet_repository.dart';

class InMemoryPetRepository implements PetRepository {
  final List<Pet> _pets = [...seedPets];
  int _nextId = seedPets.length + 1;

  @override
  Future<PageResult<Pet>> find(PetQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _pets.where((b) => q.includeDeleted || !b.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.name.toLowerCase().contains(needle) ||
                b.breed.toLowerCase().contains(needle) ||
                b.chipNumber.toLowerCase().contains(needle),
          )
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
  Future<Pet> create(Pet pet) async {
    final newPet = Pet(
      id: _nextId++,
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
    );
    _pets.add(newPet);
    return newPet;
  }

  @override
  Future<Pet> update(Pet pet) async {
    final i = _pets.indexWhere((p) => p.id == pet.id);
    if (i == -1) throw StateError('Питомец ${pet.id} не найден');
    _pets[i] = pet;
    return pet;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _pets.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Питомец $id не найден');
    _pets[i] = _pets[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _pets.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _pets.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Питомец $id не найден');
    _pets[i] = _pets[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _pets.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _pets[i] = _pets[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<Pet>> findAllActive() async {
    return _pets.where((p) => !p.isDeleted).toList();
  }

  @override
  Future<bool> isChipUnique(String chipNumber, {int? excludeId}) async {
    return !_pets.any(
      (p) =>
          !p.isDeleted &&
          p.chipNumber.toLowerCase() == chipNumber.trim().toLowerCase() &&
          p.id != excludeId,
    );
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    return _pets
        .where((p) => !p.isDeleted && p.ownerIds.contains(ownerId))
        .length;
  }

  @override
  Future<int> countByClinic(int clinicId) async {
    return _pets.where((p) => !p.isDeleted && p.clinicId == clinicId).length;
  }
}
