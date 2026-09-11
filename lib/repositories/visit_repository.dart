import 'package:dio/dio.dart';

import '../api/dio_client.dart';
import '../models/visit.dart';
import '../utils/json_helpers.dart';

class VisitRepository {
  final Dio _dio;

  VisitRepository(this._dio);

  Future<Visit> create({
    required int petId,
    required int clinicId,
    int days = 1,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/visits',
        data: {'petId': petId, 'clinicId': clinicId, 'days': days},
      );
      return Visit.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }

  Future<Visit> returnVisit(int id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/visits/$id/return');
      return Visit.fromJson(JsonHelpers.asMap(res.data));
    } catch (e) {
      mapDioError(e);
    }
  }
}
