import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/owner.dart';
import '../models/owner_query.dart';
import '../models/page_result.dart';
import 'owner_repository.dart';

class SupabaseOwnerRepository implements OwnerRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Owner _map(Map<String, dynamic> r) {
    final full = '${r['full_name'] ?? ''}';
    var last = '${r['last_name'] ?? ''}';
    var first = '${r['first_name'] ?? ''}';
    if (last.isEmpty && full.isNotEmpty) {
      final p = full.split(' ');
      last = p.first;
      first = p.length > 1 ? p.sublist(1).join(' ') : '';
    }
    return Owner(
      id: (r['id'] as num).toInt(),
      lastName: last,
      firstName: first,
      phone: '${r['phone'] ?? ''}',
      email: '${r['email'] ?? ''}',
      city: '${r['city'] ?? ''}',
      country: '${r['country'] ?? 'Россия'}',
      deletedAt: r['deleted_at'] != null
          ? DateTime.tryParse('${r['deleted_at']}')
          : null,
    );
  }

  Map<String, dynamic> _body(Owner o) => {
        'last_name': o.lastName,
        'first_name': o.firstName,
        'full_name': o.fullName,
        'phone': o.phone,
        'email': o.email,
        'city': o.city,
        'country': o.country,
      };

  @override
  Future<PageResult<Owner>> find(OwnerQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('owners').select();
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or(
          'full_name.ilike.%$s%,last_name.ilike.%$s%,first_name.ilike.%$s%,phone.ilike.%$s%,email.ilike.%$s%',
        );
      }
      if (q.city != null && q.city!.isNotEmpty) query = query.eq('city', q.city!);
      if (q.country != null && q.country!.isNotEmpty) {
        query = query.eq('country', q.country!);
      }
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
      final res = await query
          .order('last_name', ascending: q.sortAscending)
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
  Future<Owner?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('owners').select().eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<Owner>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('owners')
          .select()
          .isFilter('deleted_at', null)
          .order('last_name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Owner> create(Owner owner) async {
    return withAuthRetry(() async {
      final r =
          await _c.from('owners').insert(_body(owner)).select().single();
      return _map(r);
    });
  }

  @override
  Future<Owner> update(Owner owner) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('owners')
          .update(_body(owner))
          .eq('id', owner.id)
          .select()
          .single();
      return _map(r);
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('owners')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('owners').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('owners').update({'deleted_at': null}).eq('id', id);
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
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    return withAuthRetry(() async {
      final data =
          await _c.from('owners').select('id').eq('email', email.trim());
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
          await _c.from('owners').select('city').isFilter('deleted_at', null);
      final set = <String>{};
      for (final e in data as List) {
        final c = '${(e as Map)['city'] ?? ''}';
        if (c.isNotEmpty) set.add(c);
      }
      return set.toList()..sort();
    });
  }
}
