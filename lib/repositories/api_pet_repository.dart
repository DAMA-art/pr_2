import 'package:dio/dio.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../api/directory_cache.dart';
import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';
import '../utils/json_helpers.dart';
import 'pet_repository.dart';

class ApiPetRepository implements PetRepository {
  final Dio _dio;
  final SearchCancel searchCancel;

  ApiPetRepository(this._dio, {SearchCancel? searchCancel})
    : searchCancel = searchCancel ?? SearchCancel();

  Map<String, dynamic> _queryParams(PetQuery q) {
    final params = <String, dynamic>{
      'page': q.page,
      'size': q.size,
      'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
    };
    if (q.search.trim().isNotEmpty) params['search'] = q.search.trim();
    if (q.species != null && q.species!.isNotEmpty) {
      params['species'] = q.species;}
    if (q.ownerId != null) params['ownerId'] = q.ownerId;
    if (q.clinicId != null) params['clinicId'] = q.clinicId;
    if (q.ageFrom != null) params['ageFrom'] = q.ageFrom;
    if (q.ageTo != null) params['ageTo'] = q.ageTo;
    if (q.includeDeleted) params['includeDeleted'] = true;
    return params;
  }

  PageResult<Pet> _parsePage(Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? [])
        .map((e) => Pet.fromJson(JsonHelpers.asMap(e)))
        .toList();
    return PageResult(
      items: items,
      page: JsonHelpers.asInt(data['page'], 1),
      size: JsonHelpers.asInt(data['size'], 10),
      total: JsonHelpers.asInt(data['total']),
    );
  }

  @override
  Future<PageResult<Pet>> find(PetQuery query) async {
    final token = searchCancel.next();
    try {
      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/pets',
        queryParameters: _queryParams(query),
        cancelToken: token,
      );
      return _parsePage(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Pet?> findById(int id) async {
    try {
      final res = await getWithRetry<Map<String, dynamic>>(_dio, '/pets/$id');
      return Pet.fromJson(JsonHelpers.asMap(res.data));
    } on Object catch (e) {
      try {
        mapDioError(e);
      } on NotFoundException {
        return null;
      }
    }
  }

  @override
  Future<List<Pet>> findAllActive() async {
    final page = await find(const PetQuery(size: 100, page: 1));
    return page.items;
  }

  @override
  Future<Pet> create(Pet pet) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/pets',
        data: pet.toJson(),
      );
      return Pet.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<Pet> update(Pet pet) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/pets/${pet.id}',
        data: pet.toJson(),
      );
      return Pet.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> softDelete(int id) async {
    try {
      await _dio.delete('/pets/$id');
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    try {
      await _dio.delete('/pets/$id', queryParameters: {'hard': true});
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> restore(int id) async {
    try {
      await _dio.post('/pets/$id/restore');
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/pets/bulk-delete',
        data: {'ids': ids},
      );
      return JsonHelpers.asInt(JsonHelpers.asMap(res.data)['deleted']);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<bool> isChipUnique(String chipNumber, {int? excludeId}) async {
    // Uniqueness is enforced by the server (422). Client pre-check optional.
    return true;
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    final page = await find(PetQuery(ownerId: ownerId, size: 1, page: 1));
    return page.total;
  }

  @override
  Future<int> countByClinic(int clinicId) async {
    final page = await find(PetQuery(clinicId: clinicId, size: 1, page: 1));
    return page.total;
  }
}
