import '../data/seed_data.dart';
import '../models/owner.dart';
import '../models/owner_query.dart';
import '../models/page_result.dart';
import 'owner_repository.dart';

class InMemoryOwnerRepository implements OwnerRepository {
  final List<Owner> _owners = [...seedOwners];
  int _nextId = seedOwners.length + 1;

  @override
  Future<PageResult<Owner>> find(OwnerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _owners.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.lastName.toLowerCase().contains(needle) ||
                b.firstName.toLowerCase().contains(needle) ||
                b.phone.contains(needle) ||
                b.country.toLowerCase().contains(needle),
          )
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
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Owner>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Owner?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _owners.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
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
    return newOwner;
  }

  @override
  Future<Owner> update(Owner owner) async {
    final i = _owners.indexWhere((p) => p.id == owner.id);
    if (i == -1) throw StateError('Владелец ${owner.id} не найден');
    _owners[i] = owner;
    return owner;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _owners.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Владелец $id не найден');
    _owners[i] = _owners[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _owners.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _owners.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Владелец $id не найден');
    _owners[i] = _owners[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _owners.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _owners[i] = _owners[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<Owner>> findAllActive() async {
    return _owners.where((o) => !o.isDeleted).toList();
  }

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    return !_owners.any(
      (o) =>
          !o.isDeleted &&
          o.email.toLowerCase() == email.toLowerCase() &&
          o.id != excludeId,
    );
  }

  @override
  Future<List<String>> distinctCities() async {
    final cities = _owners
        .where((o) => !o.isDeleted)
        .map((o) => o.city)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }
}
