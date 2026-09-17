import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/app_exceptions.dart';
import '../api/supabase_errors.dart';
import '../models/review.dart';

class ReviewRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Review _map(Map<String, dynamic> r) => Review(
        id: (r['id'] as num).toInt(),
        visitId: (r['visit_id'] as num?)?.toInt(),
        authorId: '${r['author_id'] ?? ''}',
        rating: (r['rating'] as num?)?.toInt() ?? 0,
        comment: '${r['comment'] ?? ''}',
        createdAt:
            DateTime.tryParse('${r['created_at'] ?? ''}') ?? DateTime.now(),
        deletedAt: r['deleted_at'] != null
            ? DateTime.tryParse('${r['deleted_at']}')
            : null,
      );

  Future<List<Review>> listMine({bool includeDeleted = false}) async {
    return withAuthRetry(() async {
      final uid = _c.auth.currentUser?.id;
      if (uid == null) return const [];
      var query = _c.from('reviews').select().eq('author_id', uid);
      if (!includeDeleted) query = query.isFilter('deleted_at', null);
      final data = await query.order('created_at', ascending: false);
      return (data as List)
          .map((e) => _map(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<Review> create({
    required int rating,
    required String comment,
    int? visitId,
  }) async {
    return withAuthRetry(() async {
      final uid = _c.auth.currentUser?.id;
      if (uid == null) throw const UnauthorizedException();
      final r = await _c.from('reviews').insert({
        'author_id': uid,
        'rating': rating,
        'comment': comment,
        'visit_id': visitId,
      }).select().single();
      return _map(r);
    });
  }

  Future<Review> update(Review review) async {
    return withAuthRetry(() async {
      final r = await _c.from('reviews').update({
        'rating': review.rating,
        'comment': review.comment,
        'visit_id': review.visitId,
      }).eq('id', review.id).select().single();
      return _map(r);
    });
  }

  Future<void> softDelete(int id) async {
    await withAuthRetry(() async {
      await _c
          .from('reviews')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    });
  }

  Future<void> hardDelete(int id) async {
    await withAuthRetry(() async {
      await _c.from('reviews').delete().eq('id', id);
    });
  }

  Future<void> restore(int id) async {
    await withAuthRetry(() async {
      await _c.from('reviews').update({'deleted_at': null}).eq('id', id);
    });
  }

  Future<int> deleteMany(List<int> ids) async {
    for (final id in ids) {
      await softDelete(id);
    }
    return ids.length;
  }
}
