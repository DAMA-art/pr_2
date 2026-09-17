import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/supabase_errors.dart';
import '../models/groomer.dart';
import '../models/groomer_query.dart';
import '../models/page_result.dart';
import 'groomer_repository.dart';

class SupabaseGroomerRepository implements GroomerRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Groomer _map(Map<String, dynamic> r) {
    final clinic = r['clinics'];
    return Groomer(
      id: (r['id'] as num).toInt(),
      fullName: '${r['full_name'] ?? ''}',
      phone: '${r['phone'] ?? ''}',
      specialization: '${r['specialization'] ?? 'all'}',
      clinicId: (r['clinic_id'] as num?)?.toInt() ?? 0,
      clinicName: clinic is Map ? '${clinic['name'] ?? ''}' : null,
      experienceYears: (r['experience_years'] as num?)?.toInt() ?? 0,
      deletedAt: r['deleted_at'] != null
          ? DateTime.tryParse('${r['deleted_at']}')
          : null,
    );
  }

  Map<String, dynamic> _body(Groomer g) => {
        'full_name': g.fullName,
        'phone': g.phone,
        'specialization': g.specialization,
        'clinic_id': g.clinicId == 0 ? null : g.clinicId,
        'experience_years': g.experienceYears,
      };

  @override
  Future<PageResult<Groomer>> find(GroomerQuery q) async {
    return withAuthRetry(() async {
      var query = _c.from('groomers').select('*, clinics(name)');
      if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
      if (q.search.isNotEmpty) {
        final s = q.search.trim();
        query = query.or('full_name.ilike.%$s%,phone.ilike.%$s%');
      }
      if (q.clinicId != null) query = query.eq('clinic_id', q.clinicId!);
      if (q.specialization != null && q.specialization!.isNotEmpty) {
        query = query.eq('specialization', q.specialization!);
      }
      final from = (q.page - 1) * q.size;
      final to = from + q.size - 1;
      final col = switch (q.sortField) {
        'experience_years' || 'experienceYears' => 'experience_years',
        'specialization' => 'specialization',
        'phone' => 'phone',
        _ => 'full_name',
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
  Future<Groomer?> findById(int id) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('groomers')
          .select('*, clinics(name)')
          .eq('id', id)
          .maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  @override
  Future<List<Groomer>> findAllActive() async {
    return withAuthRetry(() async {
      final data = await _c
          .from('groomers')
          .select('*, clinics(name)')
          .isFilter('deleted_at', null)
          .order('full_name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<List<Groomer>> findByClinic(int clinicId) async {
    return withAuthRetry(() async {
      final data = await _c
          .from('groomers')
          .select('*, clinics(name)')
          .eq('clinic_id', clinicId)
          .isFilter('deleted_at', null)
          .order('full_name');
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  @override
  Future<Groomer> create(Groomer groomer) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('groomers')
          .insert(_body(groomer))
          .select('*, clinics(name)')
          .single();
      return _map(r);
    });
  }

  @override
  Future<Groomer> update(Groomer groomer) async {
    return withAuthRetry(() async {
      final r = await _c
          .from('groomers')
          .update(_body(groomer))
          .eq('id', groomer.id)
          .select('*, clinics(name)')
          .single();
      return _map(r);
    });
  }

  @override
  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('groomers')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  @override
  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('groomers').delete().eq('id', id);
    });
  }

  @override
  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('groomers').update({'deleted_at': null}).eq('id', id);
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await softDelete(id);
    }
    return ids.length;
  }
}
