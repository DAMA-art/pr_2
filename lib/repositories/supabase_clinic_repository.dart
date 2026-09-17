import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/clinic.dart';
import '../models/clinic_query.dart';
import '../models/page_result.dart';
import 'clinic_repository.dart';

class SupabaseClinicRepository implements ClinicRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Clinic _map(Map<String, dynamic> r) => Clinic(
        id: (r['id'] as num).toInt(),
        name: '${r['name'] ?? ''}',
        address: '${r['address'] ?? ''}',
        phone: '${r['phone'] ?? ''}',
        city: '${r['city'] ?? ''}',
        slotsTotal: (r['slots_total'] as num?)?.toInt() ?? 0,
        slotsAvailable: (r['slots_available'] as num?)?.toInt() ?? 0,
        deletedAt: r['deleted_at'] != null
            ? DateTime.tryParse('${r['deleted_at']}')
            : null,
      );

  Map<String, dynamic> _body(Clinic c) => {
        'name': c.name,
        'address': c.address,
        'phone': c.phone,
        'city': c.city,
        'slots_total': c.slotsTotal,
        'slots_available': c.slotsAvailable == 0 ? c.slotsTotal : c.slotsAvailable,
      };

  @override
  Future<PageResult<Clinic>> find(ClinicQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('clinics').select();
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or('name.ilike.%$s%,city.ilike.%$s%,address.ilike.%$s%');
      }
      if (q.city != null && q.city!.isNotEmpty) query = query.eq('city', q.city!);
      if (q.hasFreeSlots == true) {
        query = query.gt('slots_available', 0);
      }
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
      final col = switch (q.sortField) {
        'city' => 'city',
        'address' => 'address',
        'phone' => 'phone',
        _ => 'name',
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
  Future<Clinic?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('clinics').select().eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<Clinic>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('clinics')
          .select()
          .isFilter('deleted_at', null)
          .order('name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Clinic> create(Clinic clinic) async {
    return withAuthRetry(() async {
      final r =
          await _c.from('clinics').insert(_body(clinic)).select().single();
      return _map(r);
    });
  }

  @override
  Future<Clinic> update(Clinic clinic) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('clinics')
          .update(_body(clinic))
          .eq('id', clinic.id)
          .select()
          .single();
      return _map(r);
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('clinics')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('clinics').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('clinics').update({'deleted_at': null}).eq('id', id);
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
  Future<bool> isNameUnique(String name, {int? excludeId}) async {
    return withAuthRetry(() async {
      final data =
          await _c.from('clinics').select('id').eq('name', name.trim());
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
  Future<List<String>> distinctCities() async {
    return withAuthRetry(() async {
      final data =
          await _c.from('clinics').select('city').isFilter('deleted_at', null);
      final set = <String>{};
      for (final e in data as List) {
        final c = '${(e as Map)['city'] ?? ''}';
        if (c.isNotEmpty) set.add(c);
      }
      return set.toList()..sort();
    });
  }
}
