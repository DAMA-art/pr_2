import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/page_result.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';
import 'pet_passport_repository.dart';

class SupabasePassportRepository implements PetPassportRepository {
  SupabaseClient get _c => Supabase.instance.client;

  PetPassport _map(Map<String, dynamic> r) => PetPassport(
        id: (r['id'] as num).toInt(),
        petId: (r['pet_id'] as num).toInt(),
        number: '${r['number'] ?? ''}',
        microchip: '${r['microchip'] ?? ''}',
        issuedAt: r['issued_at'] != null
            ? DateTime.tryParse('${r['issued_at']}') ?? DateTime.now()
            : DateTime.now(),
        deletedAt: r['deleted_at'] != null
            ? DateTime.tryParse('${r['deleted_at']}')
            : null,
      );

  Map<String, dynamic> _body(PetPassport p) => {
        'pet_id': p.petId,
        'number': p.number,
        'microchip': p.microchip,
        'issued_at': p.issuedAt.toIso8601String().split('T').first,
      };

  @override
  Future<PageResult<PetPassport>> find(PetPassportQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('passports').select();
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or('number.ilike.%$s%,microchip.ilike.%$s%');
      }
      if (q.petId != null) query = query.eq('pet_id', q.petId!);
      if (q.hasMicrochip == true) {
        query = query.neq('microchip', '');
      }
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
      final col = switch (q.sortField) {
        'microchip' => 'microchip',
        'issuedAt' || 'issued_at' => 'issued_at',
        _ => 'number',
      };
      final res = await query
          .order(col, ascending: q.sortAscending)
          .range(from, to)
          .count(CountOption.exact);
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
  Future<PetPassport?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('passports').select().eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<PetPassport?> findByPetId(int petId) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('passports')
          .select()
          .eq('pet_id', petId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<PetPassport>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('passports')
          .select()
          .isFilter('deleted_at', null)
          .order('number');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<PetPassport> create(PetPassport passport) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('passports')
          .insert(_body(passport))
          .select()
          .single();
      return _map(r);
    });
  }

  @override
  Future<PetPassport> update(PetPassport passport) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('passports')
          .update(_body(passport))
          .eq('id', passport.id)
          .select()
          .single();
      return _map(r);
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('passports')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('passports').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('passports').update({'deleted_at': null}).eq('id', id);
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
  Future<bool> isNumberUnique(String number, {int? excludeId}) async {
    return withAuthRetry(() async {
      final data =
          await _c.from('passports').select('id').eq('number', number.trim());
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
  Future<bool> isPetFree(int petId, {int? excludeId}) async {
    return withAuthRetry(() async {
      final data = await _c
          .from('passports')
          .select('id')
          .eq('pet_id', petId)
          .isFilter('deleted_at', null);
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
}
