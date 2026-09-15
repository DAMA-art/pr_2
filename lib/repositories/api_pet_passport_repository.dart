import 'package:dio/dio.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../models/page_result.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';
import '../utils/json_helpers.dart';
import 'pet_passport_repository.dart';

class ApiPetPassportRepository implements PetPassportRepository {
  final Dio _dio;

  ApiPetPassportRepository(this._dio);

  @override
  Future<PageResult<PetPassport>> find(PetPassportQuery query) async {
    try {
      final params = <String, dynamic>{
        'page': query.page,
        'size': query.size,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      };
      if (query.search.trim().isNotEmpty){
        params['search'] = query.search.trim();}
      if (query.petId != null) params['petId'] = query.petId;
      if (query.includeDeleted) params['includeDeleted'] = true;

      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/passports',
        queryParameters: params,
      );
      final data = JsonHelpers.asMap(res.data);
      final items = (data['items'] as List? ?? [])
          .map((e) => PetPassport.fromJson(JsonHelpers.asMap(e)))
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
  Future<PetPassport?> findById(int id) async {
    try {
      final res = await getWithRetry<Map<String, dynamic>>(
        _dio,
        '/passports/$id',
      );
      return PetPassport.fromJson(JsonHelpers.asMap(res.data));
    } on Object catch (e) {
      try {
        mapDioError(e);
      } on NotFoundException {
        return null;
      }
    }
  }

  @override
  Future<PetPassport?> findByPetId(int petId) async {
    final page = await find(PetPassportQuery(petId: petId, size: 1));
    if (page.items.isEmpty) return null;
    return page.items.first;
  }

  @override
  Future<List<PetPassport>> findAllActive() async {
    final page = await find(const PetPassportQuery(size: 100));
    return page.items;
  }

  @override
  Future<PetPassport> create(PetPassport passport) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/passports',
        data: {
          'petId': passport.petId,
          'number': passport.number,
          'microchip': passport.microchip,
          'issuedAt': passport.issuedAt.toIso8601String(),
        },
      );
      return PetPassport.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<PetPassport> update(PetPassport passport) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/passports/${passport.id}',
        data: {
          'petId': passport.petId,
          'number': passport.number,
          'microchip': passport.microchip,
          'issuedAt': passport.issuedAt.toIso8601String(),
        },
      );
      return PetPassport.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> softDelete(int id) async {
    try {
      await _dio.delete('/passports/$id');
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> hardDelete(int id) async {
    try {
      await _dio.delete('/passports/$id', queryParameters: {'hard': true});
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<void> restore(int id) async {
    try {
      await _dio.post('/passports/$id/restore');
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/passports/bulk-delete',
        data: {'ids': ids},
      );
      return JsonHelpers.asInt(JsonHelpers.asMap(res.data)['deleted']);
    } catch (e) {
      mapDioError(e);
    }
  }

  @override
  Future<bool> isNumberUnique(String number, {int? excludeId}) async => true;

  @override
  Future<bool> isPetFree(int petId, {int? excludeId}) async => true;
}
