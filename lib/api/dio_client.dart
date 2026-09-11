import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'app_exceptions.dart';
import 'auth_session.dart';

class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AuthSession.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers.putIfAbsent('Content-Type', () => 'application/json');

    if (ApiConfig.forceDelayMs > 0) {
      options.queryParameters['__delay'] = ApiConfig.forceDelayMs;
    }
    if (ApiConfig.forceFailCode > 0) {
      options.queryParameters['__fail'] = ApiConfig.forceFailCode;
    }

    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '← ${response.requestOptions.method} ${response.requestOptions.uri} '
        '→ ${response.statusCode}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✕ ${err.requestOptions.method} ${err.requestOptions.uri} '
        '→ ${err.response?.statusCode ?? err.type}',
      );
    }
    handler.reject(err);
  }
}

Never mapDioError(Object error) {
  if (error is AppException) throw error;
  if (error is! DioException) {
    throw AppException(error.toString());
  }

  final err = error;
  if (err.type == DioExceptionType.cancel) {
    throw const CancelledException();
  }
  if (err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.sendTimeout ||
      err.type == DioExceptionType.receiveTimeout) {
    throw const TimeoutException();
  }
  if (err.type == DioExceptionType.connectionError) {
    throw const NetworkException();
  }

  final status = err.response?.statusCode;
  final data = err.response?.data;
  var message = 'Ошибка сервера';
  var fieldErrors = <String, String>{};

  if (data is Map) {
    message = (data['message'] as String?) ?? message;
    final errors = data['errors'];
    if (errors is Map) {
      fieldErrors = errors.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  }

  switch (status) {
    case 400:
      throw AppException(message);
    case 401:
      throw UnauthorizedException(message);
    case 403:
      throw ForbiddenException(message);
    case 404:
      throw NotFoundException(message);
    case 409:
      throw ConflictException(message);
    case 422:
      throw ValidationException(message, fieldErrors);
    default:
      throw ServerException(message, statusCode: status);
  }
}

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(ApiLoggingInterceptor());
  return dio;
}

Future<Response<T>> getWithRetry<T>(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  int maxAttempts = 3,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      lastError = e;
      final retryable = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      if (!retryable || attempt == maxAttempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 300 * (1 << (attempt - 1))));
    }
  }
  throw lastError!;
}
