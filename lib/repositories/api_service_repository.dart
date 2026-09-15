import 'package:dio/dio.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../api/directory_cache.dart';
import '../models/page_result.dart';
import '../models/service.dart';
import '../models/service_query.dart';
import '../utils/json_helpers.dart';
import 'service_repository.dart';

class ApiServiceRepository implements ServiceRepository {
  final Dio _dio;
  final DirectoryCache cache;
  static const _cacheKey = 'services_all';

  ApiServiceRepository(this._dio, this.cache);

  @override
  Future<PageResult<Service>> find(ServiceQuery query) async {
    try {
      final params = <String, dynamic>{
        'page': query.page,
        'size': query.size,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      };
      if (query.search.trim().isNotEmpty){
        params['search'] = query.search.trim();}
      if (query.clinicId != null) params['clinicId'] = query.clinicId;
      if (query.includeDeleted) params['includeDeleted'] = true;

      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/services',
        queryParameters: params,
      );
      final data = JsonHelpers.asMap(res.data);
      final items = (data['items'] as List? ?? [])
          .map((e) => Service.fromJson(JsonHelpers.asMap(e)))
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
  Future<Service?> findById(int id) async {
    try {
      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/services/$id',
      );
      return Service.fromJson(JsonHelpers.asMap(res.data));
    } on Object catch (e) {
      try {
        mapDioError(e);
      } on NotFoundException {
        return null;
      }
    }
  }

  @override
  Future<List<Service>> findAllActive() async {
    if (cache.has(_cacheKey)) {
      return List<Service>.from(cache.get<List<Service>>(_cacheKey)!);
    }
    final page = await find(const ServiceQuery(size: 100));
    cache.set(_cacheKey, page.items);
    return page.items;
  }

  @override
  Future<Service> create(Service service) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/services',
        data: service.toJson(),
      );
      cache.invalidate(_cacheKey);
      return Service.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Service> update(Service service) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/services/${service.id}',
        data: service.toJson(),
      );
      cache.invalidate(_cacheKey);
      return Service.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> softDelete(int id) async {
    try {
      await _dio.delete('/services/$id');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    try {
      await _dio.delete('/services/$id', queryParameters: {'hard': true});
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> restore(int id) async {
    try {
      await _dio.post('/services/$id/restore');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/services/bulk-delete',
        data: {'ids': ids},
      );
      cache.invalidate(_cacheKey);
      return JsonHelpers.asInt(JsonHelpers.asMap(res.data)['deleted']);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<bool> isNameUnique(String name, {int? excludeId}) async => true;

  @override
  Future<int> countByClinic(int clinicId) async {
    final page = await find(ServiceQuery(clinicId: clinicId, size: 1));
    return page.total;
  }
}
