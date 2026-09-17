import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/app_exceptions.dart';
import '../api/supabase_errors.dart';
import '../models/visit.dart';
import '../utils/grooming_quote.dart';

class VisitRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Visit _map(Map<String, dynamic> r) {
    final pet = r['pets'];
    final clinic = r['clinics'];
    final groomer = r['groomers'];
    final links = r['visit_services'];
    final serviceIds = <int>[];
    if (links is List) {
      for (final raw in links) {
        if (raw is Map) {
          final id = (raw['service_id'] as num?)?.toInt();
          if (id != null) serviceIds.add(id);
        }
      }
    }
    return Visit(
      id: (r['id'] as num).toInt(),
      petId: (r['pet_id'] as num?)?.toInt() ?? 0,
      petName: pet is Map ? '${pet['name'] ?? ''}' : null,
      clinicId: (r['clinic_id'] as num?)?.toInt() ?? 0,
      clinicName: clinic is Map ? '${clinic['name'] ?? ''}' : null,
      groomerId: (r['groomer_id'] as num?)?.toInt(),
      groomerName: groomer is Map ? '${groomer['full_name'] ?? ''}' : null,
      issuedAt: DateTime.tryParse('${r['issued_at'] ?? ''}') ?? DateTime.now(),
      dueAt: DateTime.tryParse('${r['due_at'] ?? ''}') ?? DateTime.now(),
      returnedAt: r['returned_at'] != null
          ? DateTime.tryParse('${r['returned_at']}')
          : null,
      status: '${r['status'] ?? 'scheduled'}',
      totalPrice: (r['total_price'] as num?)?.toDouble() ?? 0,
      serviceIds: serviceIds,
      deletedAt: r['deleted_at'] != null
          ? DateTime.tryParse('${r['deleted_at']}')
          : null,
    );
  }

  static const _select =
      '*, pets(name, weight_kg, species), clinics(name), groomers(full_name), visit_services(service_id)';

  Future<List<Visit>> list({bool includeDeleted = false}) async {
    return withAuthRetry(() async {
      var query = _c.from('visits').select(_select);
      if (!includeDeleted) query = query.isFilter('deleted_at', null);
      final data = await query.order('issued_at', ascending: false);
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<Visit?> findById(int id) async {
    return withAuthRetry(() async {
      final r =
          await _c.from('visits').select(_select).eq('id', id).maybeSingle();
      return r == null ? null : _map(r);
    });
  }

  Future<bool> hasOverlap({
    required int groomerId,
    required DateTime start,
    required DateTime end,
    int? excludeId,
  }) async {
    return withAuthRetry(() async {
      final data = await _c
          .from('visits')
          .select('id, issued_at, due_at, status')
          .eq('groomer_id', groomerId)
          .isFilter('deleted_at', null);
      for (final raw in data as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = (row['id'] as num).toInt();
        if (excludeId != null && id == excludeId) continue;
        final status = '${row['status'] ?? ''}';
        if (status == 'cancelled' || status == 'returned' || status == 'done') {
          continue;
        }
        final a = DateTime.tryParse('${row['issued_at']}') ?? start;
        final b = DateTime.tryParse('${row['due_at']}') ?? end;
        if (GroomingQuote.intervalsOverlap(start, end, a, b)) return true;
      }
      return false;
    });
  }

  Future<int> countCompletedByPet(int petId) async {
    return withAuthRetry(() async {
      final res = await _c
          .from('visits')
          .select('id')
          .eq('pet_id', petId)
          .inFilter('status', ['done', 'returned'])
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return res.count;
    });
  }

  Future<Visit> create({
    required int petId,
    required int clinicId,
    int? groomerId,
    required DateTime start,
    required DateTime end,
    required List<int> serviceIds,
    required double totalPrice,
  }) async {
    return withAuthRetry(() async {
      if (groomerId != null) {
        final clash = await hasOverlap(
          groomerId: groomerId,
          start: start,
          end: end,
        );
        if (clash) {
          throw const ConflictException('Мастер уже занят в выбранный интервал');
        }
      }
      final r = await _c.from('visits').insert({
        'pet_id': petId,
        'clinic_id': clinicId,
        'groomer_id': groomerId,
        'issued_at': start.toIso8601String(),
        'due_at': end.toIso8601String(),
        'status': 'scheduled',
        'total_price': totalPrice,
      }).select(_select).single();
      final created = _map(r);
      if (serviceIds.isNotEmpty) {
        await _c.from('visit_services').insert([
          for (final id in serviceIds)
            {'visit_id': created.id, 'service_id': id},
        ]);
      }
      return (await findById(created.id)) ?? created;
    });
  }

  Future<Visit> update(Visit visit) async {
    return withAuthRetry(() async {
      if (visit.groomerId != null) {
        final clash = await hasOverlap(
          groomerId: visit.groomerId!,
          start: visit.issuedAt,
          end: visit.dueAt,
          excludeId: visit.id,
        );
        if (clash) {
          throw const ConflictException('Мастер уже занят в выбранный интервал');
        }
      }
      await _c.from('visits').update({
        'pet_id': visit.petId,
        'clinic_id': visit.clinicId,
        'groomer_id': visit.groomerId,
        'issued_at': visit.issuedAt.toIso8601String(),
        'due_at': visit.dueAt.toIso8601String(),
        'status': visit.status,
        'total_price': visit.totalPrice,
      }).eq('id', visit.id);
      await _c.from('visit_services').delete().eq('visit_id', visit.id);
      if (visit.serviceIds.isNotEmpty) {
        await _c.from('visit_services').insert([
          for (final id in visit.serviceIds)
            {'visit_id': visit.id, 'service_id': id},
        ]);
      }
      return (await findById(visit.id)) ?? visit;
    });
  }

  Future<Visit> complete(int id) async {
    return withAuthRetry(() async {
      final r = await _c.from('visits').update({
        'returned_at': DateTime.now().toIso8601String(),
        'status': 'done',
      }).eq('id', id).select(_select).single();
      return _map(r);
    });
  }

  Future<Visit> extend(int id, {int minutes = 30}) async {
    return withAuthRetry(() async {
      final cur = await _c.from('visits').select().eq('id', id).single();
      final due = DateTime.tryParse('${cur['due_at']}') ?? DateTime.now();
      final r = await _c.from('visits').update({
        'due_at': due.add(Duration(minutes: minutes)).toIso8601String(),
      }).eq('id', id).select(_select).single();
      return _map(r);
    });
  }

  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('visits')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('visits').delete().eq('id', id);
    });
  }

  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('visits').update({'deleted_at': null}).eq('id', id);
    });
  }

  Future<int> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await softDelete(id);
    }
    return ids.length;
  }

  /// Совместимость со старым экраном «продлить / выписать».
  Future<Visit> returnVisit(int id) => complete(id);
}
