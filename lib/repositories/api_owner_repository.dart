import 'package:dio/dio.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../api/directory_cache.dart';
import '../models/owner.dart';
import '../models/owner_query.dart';
import '../models/page_result.dart';
import '../utils/json_helpers.dart';
import 'owner_repository.dart';

class ApiOwnerRepository implements OwnerRepository {
  final Dio _dio;
  final DirectoryCache cache;
  static const _cacheKey = 'owners_all';

  ApiOwnerRepository(this._dio, this.cache);

  @override
  Future<PageResult<Owner>> find(OwnerQuery query) async {
    try {
      final params = <String, dynamic>{
        'page': query.page,
        'size': query.size,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      };
      if (query.search.trim().isNotEmpty) params['search'] = query.search.trim();
      if (query.city != null) params['city'] = query.city;
      if (query.country != null) params['country'] = query.country;
      if (query.includeDeleted) params['includeDeleted'] = true;

      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/owners',
        queryParameters: params,
      );
      final data = JsonHelpers.asMap(res.data);
      final items = (data['items'] as List? ?? [])
          .map((e) => Owner.fromJson(JsonHelpers.asMap(e)))
          .toList();
      return PageResult(
        items: items,
        page: JsonHelpers.asInt(data['page'], 1),
        size: JsonHelpers.asInt(data['size'], 10),
        total: JsonHelpers.asInt(data['total']),
      );
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Owner?> findById(int id) async {
    try {
      final res = await getWithRetry<Map<String, dynamic>>(_dio, '/owners/$id');
      return Owner.fromJson(JsonHelpers.asMap(res.data));
    } on Object catch (e) {
      try {
        mapDioError(e);
      } on NotFoundException {
        return null;
      }
    }
  }

  @override
  Future<List<Owner>> findAllActive() async {
    if (cache.has(_cacheKey)) {
      return List<Owner>.from(cache.get<List<Owner>>(_cacheKey)!);
    }
    final page = await find(const OwnerQuery(size: 100));
    cache.set(_cacheKey, page.items);
    return page.items;
  }

  @override
  Future<Owner> create(Owner owner) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/owners', data: owner.toJson());
      cache.invalidate(_cacheKey);
      return Owner.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Owner> update(Owner owner) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/owners/${owner.id}', data: owner.toJson());
      cache.invalidate(_cacheKey);
      return Owner.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> softDelete(int id) async {
    try {
      await _dio.delete('/owners/$id');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    try {
      await _dio.delete('/owners/$id', queryParameters: {'hard': true});
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> restore(int id) async {
    try {
      await _dio.post('/owners/$id/restore');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/owners/bulk-delete',
        data: {'ids': ids},
      );
      cache.invalidate(_cacheKey);
      return JsonHelpers.asInt(JsonHelpers.asMap(res.data)['deleted']);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async => true;

  @override
  Future<List<String>> distinctCities() async {
    final owners = await findAllActive();
    final cities = owners.map((o) => o.city).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return cities;
  }
}
