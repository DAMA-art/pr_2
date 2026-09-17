import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/page_result.dart';
import '../models/service.dart';
import '../models/service_query.dart';
import 'service_repository.dart';

class SupabaseServiceRepository implements ServiceRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Service _map(Map<String, dynamic> r) => Service(
        id: (r['id'] as num).toInt(),
        name: '${r['name'] ?? ''}',
        description: '${r['description'] ?? ''}',
        price: (r['price'] as num?)?.toDouble() ?? 0,
        clinicId: (r['clinic_id'] as num?)?.toInt() ?? 0,
        deletedAt: r['deleted_at'] != null
            ? DateTime.tryParse('${r['deleted_at']}')
            : null,
      );

  Map<String, dynamic> _body(Service s) => {
        'name': s.name,
        'description': s.description,
        'price': s.price,
        'clinic_id': s.clinicId == 0 ? null : s.clinicId,
      };

  @override
  Future<PageResult<Service>> find(ServiceQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('services').select();
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or('name.ilike.%$s%,description.ilike.%$s%');
      }
      if (q.clinicId != null) query = query.eq('clinic_id', q.clinicId!);
      if (q.maxPrice != null) query = query.lte('price', q.maxPrice!);
      final col = q.sortField == 'price' ? 'price' : 'name';
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
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
  Future<Service?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('services').select().eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<Service>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('services')
          .select()
          .isFilter('deleted_at', null)
          .order('name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Service> create(Service service) async {
    return withAuthRetry(() async {
      final r =
          await _c.from('services').insert(_body(service)).select().single();
      return _map(r);
    });
  }

  @override
  Future<Service> update(Service service) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('services')
          .update(_body(service))
          .eq('id', service.id)
          .select()
          .single();
      return _map(r);
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('services')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('services').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('services').update({'deleted_at': null}).eq('id', id);
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
          await _c.from('services').select('id').eq('name', name.trim());
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
  Future<int> countByClinic(int clinicId) async {
    return withAuthRetry(() async {
      final res = await _c
          .from('services')
          .select('id')
          .eq('clinic_id', clinicId)
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return res.count;
    });
  }
}
