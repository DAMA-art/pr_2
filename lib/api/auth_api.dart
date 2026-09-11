import 'package:dio/dio.dart';

import 'auth_session.dart';
import 'dio_client.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = res.data ?? {};
      AuthSession.accessToken = data['accessToken'] as String?;
      AuthSession.refreshToken = data['refreshToken'] as String?;
      AuthSession.user = (data['user'] as Map?)?.cast<String, dynamic>();
    } catch (e) {
      mapDioError(e);
    }
  }
}
