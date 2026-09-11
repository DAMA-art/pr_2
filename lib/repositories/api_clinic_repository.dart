import 'package:dio/dio.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../api/directory_cache.dart';
import '../models/clinic.dart';
import '../models/clinic_query.dart';
import '../models/page_result.dart';
import '../utils/json_helpers.dart';
import 'clinic_repository.dart';

class ApiClinicRepository implements ClinicRepository {
  final Dio _dio;
  final DirectoryCache cache;
  static const _cacheKey = 'clinics_all';

  ApiClinicRepository(this._dio, this.cache);

  @override
  Future<PageResult<Clinic>> find(ClinicQuery query) async {
    try {
      final params = <String, dynamic>{
        'page': query.page,
        'size': query.size,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      };
      if (query.search.trim().isNotEmpty) params['search'] = query.search.trim();
      if (query.city != null) params['city'] = query.city;
      if (query.includeDeleted) params['includeDeleted'] = true;

      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/clinics',
        queryParameters: params,
      );
      final data = JsonHelpers.asMap(res.data);
      final items = (data['items'] as List? ?? [])
          .map((e) => Clinic.fromJson(JsonHelpers.asMap(e)))
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
  Future<Clinic?> findById(int id) async {
    try {
      final res = await getWithRetry<Map<String, dynamic>>(_dio, '/clinics/$id');
      return Clinic.fromJson(JsonHelpers.asMap(res.data));
    } on Object catch (e) {
      try {
        mapDioError(e);
      } on NotFoundException {
        return null;
      }
    }
  }

  @override
  Future<List<Clinic>> findAllActive() async {
    if (cache.has(_cacheKey)) {
      return List<Clinic>.from(cache.get<List<Clinic>>(_cacheKey)!);
    }
    final page = await find(const ClinicQuery(size: 100));
    cache.set(_cacheKey, page.items);
    return page.items;
  }

  @override
  Future<Clinic> create(Clinic clinic) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/clinics', data: clinic.toJson());
      cache.invalidate(_cacheKey);
      return Clinic.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Clinic> update(Clinic clinic) async {
    try {
      final res =
          await _dio.put<Map<String, dynamic>>('/clinics/${clinic.id}', data: clinic.toJson());
      cache.invalidate(_cacheKey);
      return Clinic.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> softDelete(int id) async {
    try {
      await _dio.delete('/clinics/$id');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    try {
      await _dio.delete('/clinics/$id', queryParameters: {'hard': true});
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> restore(int id) async {
    try {
      await _dio.post('/clinics/$id/restore');
      cache.invalidate(_cacheKey);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/clinics/bulk-delete',
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
  Future<List<String>> distinctCities() async {
    final clinics = await findAllActive();
    final cities = clinics.map((c) => c.city).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return cities;
  }
}
