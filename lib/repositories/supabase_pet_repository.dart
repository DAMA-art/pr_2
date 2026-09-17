import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';
import 'pet_repository.dart';

class SupabasePetRepository implements PetRepository {
  SupabaseClient get _c => Supabase.instance.client;

  static const _select =
      '*, clinics(name), pet_owners(owner_id, owners(last_name, first_name)), pet_services(service_id, services(name))';

  Pet _map(Map<String, dynamic> r) {
    final ownerLinks = r['pet_owners'];
    final ownerIds = <int>[];
    final ownerNames = <String>[];
    if (ownerLinks is List) {
      for (final raw in ownerLinks) {
        if (raw is! Map) continue;
        final oid = (raw['owner_id'] as num?)?.toInt();
        if (oid != null) ownerIds.add(oid);
        final owners = raw['owners'];
        if (owners is Map) {
          ownerNames.add('${owners['last_name'] ?? ''} ${owners['first_name'] ?? ''}'.trim());
        }
      }
    }
    if (ownerIds.isEmpty) {
      final ownerId = (r['owner_id'] as num?)?.toInt();
      if (ownerId != null && ownerId > 0) ownerIds.add(ownerId);
    }

    final serviceLinks = r['pet_services'];
    final serviceIds = <int>[];
    final serviceNames = <String>[];
    if (serviceLinks is List) {
      for (final raw in serviceLinks) {
        if (raw is! Map) continue;
        final sid = (raw['service_id'] as num?)?.toInt();
        if (sid != null) serviceIds.add(sid);
        final services = raw['services'];
        if (services is Map) {
          serviceNames.add('${services['name'] ?? ''}');
        }
      }
    }

    final clinic = r['clinics'];
    return Pet(
      id: (r['id'] as num).toInt(),
      name: '${r['name'] ?? ''}',
      species: '${r['species'] ?? 'cat'}',
      breed: '${r['breed'] ?? ''}',
      chipNumber: '${r['chip_number'] ?? ''}',
      ageMonths: (r['age_months'] as num?)?.toInt() ?? 0,
      weightKg: (r['weight_kg'] as num?)?.toDouble() ?? 0,
      clinicId: (r['clinic_id'] as num?)?.toInt() ?? 0,
      clinicName: clinic is Map ? '${clinic['name'] ?? ''}' : null,
      ownerIds: ownerIds,
      ownerNames: ownerNames,
      serviceIds: serviceIds,
      serviceNames: serviceNames,
      notes: '${r['notes'] ?? ''}',
      deletedAt: r['deleted_at'] != null
          ? DateTime.tryParse('${r['deleted_at']}')
          : null,
    );
  }

  Map<String, dynamic> _body(Pet p) => {
        'name': p.name,
        'species': p.species,
        'breed': p.breed,
        'chip_number': p.chipNumber,
        'age_months': p.ageMonths,
        'weight_kg': p.weightKg,
        'clinic_id': p.clinicId == 0 ? null : p.clinicId,
        'owner_id': p.ownerIds.isNotEmpty ? p.ownerIds.first : null,
        'notes': p.notes,
      };

  Future<void> _syncLinks(int petId, Pet p) async {
    await _c.from('pet_owners').delete().eq('pet_id', petId);
    if (p.ownerIds.isNotEmpty) {
      await _c.from('pet_owners').insert([
        for (final id in p.ownerIds) {'pet_id': petId, 'owner_id': id},
      ]);
    }
    await _c.from('pet_services').delete().eq('pet_id', petId);
    if (p.serviceIds.isNotEmpty) {
      await _c.from('pet_services').insert([
        for (final id in p.serviceIds) {'pet_id': petId, 'service_id': id},
      ]);
    }
  }

  @override
  Future<PageResult<Pet>> find(PetQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('pets').select(_select);
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or(
          'name.ilike.%$s%,breed.ilike.%$s%,chip_number.ilike.%$s%',
        );
      }
      if (q.species != null && '${q.species}'.isNotEmpty) {
        query = query.eq('species', q.species!);
      }
      if (q.ownerId != null) query = query.eq('owner_id', q.ownerId!);
      if (q.clinicId != null) query = query.eq('clinic_id', q.clinicId!);
      if (q.ageFrom != null) query = query.gte('age_months', q.ageFrom!);
      if (q.ageTo != null) query = query.lte('age_months', q.ageTo!);

      final col = switch (q.sortField) {
        'chipNumber' => 'chip_number',
        'ageMonths' => 'age_months',
        'species' => 'species',
        'breed' => 'breed',
        _ => 'name',
      };
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
      final res =
          await query.order(col, ascending: q.sortAscending).range(from, to).count(
                CountOption.exact,
              );
      final items = (res.data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
      return PageResult(
        items: items,
        page: q.page,
        size: q.size,
        total: res.count,
      );
    });
  }

  @override
  Future<Pet?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('pets').select(_select).eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<Pet>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('pets')
          .select(_select)
          .isFilter('deleted_at', null)
          .order('name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Pet> create(Pet pet) async {
    return withAuthRetry(() async {
      final r = await _c.from('pets').insert(_body(pet)).select(_select).single();
      final created = _map(r);
      await _syncLinks(created.id, pet);
      return (await findById(created.id)) ?? created;
    });
  }

  @override
  Future<Pet> update(Pet pet) async {
    return withAuthRetry(() async {
      await _c.from('pets').update(_body(pet)).eq('id', pet.id);
      await _syncLinks(pet.id, pet);
      return (await findById(pet.id)) ?? pet;
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('pets')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('pets').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('pets').update({'deleted_at': null}).eq('id', id);
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await softDelete(id);
    }
    return ids.length;
  }

  @override
  Future<bool> isChipUnique(String chipNumber, {int? excludeId}) async {
    return withAuthRetry(() async {
      final data =
          await _c.from('pets').select('id').eq('chip_number', chipNumber);
      final list = data as List;
      if (list.isEmpty) return true;
      if (excludeId != null &&
          list.length == 1 &&
          (list.first as Map)['id'] == excludeId) {
        return true;
      }
      return false;
    });
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    return withAuthRetry(() async {
      final res = await _c
          .from('pets')
          .select('id')
          .eq('owner_id', ownerId)
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return res.count;
    });
  }

  @override
  Future<int> countByClinic(int clinicId) async {
    return withAuthRetry(() async {
      final res = await _c
          .from('pets')
          .select('id')
          .eq('clinic_id', clinicId)
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return res.count;
    });
  }
}
