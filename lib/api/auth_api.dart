import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'app_exceptions.dart';
import 'dio_client.dart';

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;
  final int expiresIn;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
  });
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<LoginResult> login(String username, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return _parseLogin(res.data ?? {});
    } catch (e) {
      mapDioError(e);
    }
  }

  Future<LoginResult> register({
    required String username,
    required String password,
    required String fullName,
    String email = '',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
        },
      );
      return _parseLogin(res.data ?? {});
    } catch (e) {
      mapDioError(e);
    }
  }

  Future<LoginResult> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return _parseLogin(res.data ?? {});
    } catch (e) {
      mapDioError(e);
    }
  }

  Future<AppUser> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(Map<String, dynamic>.from(res.data ?? {}));
    } catch (e) {
      mapDioError(e);
    }
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
  }

  LoginResult _parseLogin(Map<String, dynamic> data) {
    final userMap = data['user'];
    if (userMap is! Map) {
      throw const AppException('Сервер не вернул данные пользователя');
    }
    return LoginResult(
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 900,
      user: AppUser.fromJson(Map<String, dynamic>.from(userMap)),
    );
  }
}