import 'dart:async' as async;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exceptions.dart';

AppException exceptionFromPostgrest({
  required String? code,
  required String? statusCode,
  required String message,
  Map<String, String> fieldErrors = const {},
}) {
  final status = int.tryParse(statusCode ?? '');
  final lower = message.toLowerCase();

  if (status == 401 || code == 'PGRST301' || lower.contains('jwt')) {
    return const UnauthorizedException();
  }
  if (status == 403) {
    return const ForbiddenException();
  }
  if (status == 404) {
    return const NotFoundException();
  }
  if (status == 409 || code == '23505') {
    return ConflictException(_humanizeConflict(message));
  }
  if (status == 422 ||
      code == '23514' ||
      code == '23502' ||
      code == 'PGRST102') {
    return ValidationException(_humanize(message), fieldErrors);
  }
  if (code == '57014' || lower.contains('timeout')) {
    return const TimeoutException();
  }
  return ServerException(_humanize(message), statusCode: status);
}

String _humanize(String message) {
  if (message.trim().isEmpty) return 'Ошибка сервера';
  return message;
}

String _humanizeConflict(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('chip')) {
    return 'Питомец с таким номером чипа уже существует';
  }
  if (lower.contains('email')) {
    return 'Владелец с таким email уже существует';
  }
  if (lower.contains('number') || lower.contains('passports')) {
    return 'Паспорт с таким номером уже существует';
  }
  if (lower.contains('занят') ||
      lower.contains('overlap') ||
      lower.contains('interval')) {
    return 'Мастер уже занят в выбранный интервал';
  }
  if (message.contains('Мастер уже занят')) {
    return message;
  }
  return message.isEmpty ? 'Конфликт данных' : message;
}

Never mapSupabaseError(Object error) {
  if (error is AppException) throw error;
  if (error is AuthException) {
    if (error.statusCode == '401' ||
        error.message.toLowerCase().contains('jwt') ||
        error.message.toLowerCase().contains('expired')) {
      throw const UnauthorizedException();
    }
    throw AppException(error.message);
  }
  if (error is PostgrestException) {
    throw exceptionFromPostgrest(
      code: error.code,
      statusCode: int.tryParse(error.code ?? '') != null ? error.code : null,
      message: error.message,
      fieldErrors: _fieldsFromDetails(error.details, error.message),
    );
  }
  if (error is async.TimeoutException) {
    throw const TimeoutException();
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('failed host') ||
      text.contains('network') ||
      text.contains('connection')) {
    throw const NetworkException();
  }
  if (text.contains('timeout')) {
    throw const TimeoutException();
  }
  throw AppException(error.toString());
}

Map<String, String> _fieldsFromDetails(dynamic details, [String message = '']) {
  final out = <String, String>{};
  if (details is Map) {
    details.forEach((k, v) => out['$k'] = '$v');
  } else if (details is String && details.trim().isNotEmpty) {
    out['details'] = details;
  }
  final text = '${details ?? ''} $message'.toLowerCase();
  void add(String key, String msg) {
    if (text.contains(key) && !out.containsKey(key)) {
      out[key] = msg;
    }
  }

  add('chip_number', 'Некорректный номер чипа');
  add('age_months', 'Возраст вне допустимого диапазона');
  add('weight_kg', 'Некорректный вес');
  add('email', 'Некорректный email');
  add('phone', 'Некорректный телефон');
  add('price', 'Некорректная цена');
  add('full_name', 'Некорректное ФИО');
  add('number', 'Некорректный номер паспорта');
  add('name', 'Некорректное название');
  return out;
}

Future<T> withAuthRetry<T>(Future<T> Function() action) async {
  try {
    return await action().timeout(const Duration(seconds: 10));
  } on TimeoutException {
    rethrow;
  } on async.TimeoutException {
    throw const TimeoutException();
  } on PostgrestException catch (e) {
    final expired = e.code == 'PGRST301' ||
        e.message.toLowerCase().contains('jwt') ||
        e.code == '401';
    if (!expired) mapSupabaseError(e);
    try {
      final refreshed = await Supabase.instance.client.auth.refreshSession();
      if (refreshed.session == null) {
        throw const UnauthorizedException();
      }
      return await action().timeout(const Duration(seconds: 10));
    } on AppException {
      rethrow;
    } on async.TimeoutException {
      throw const TimeoutException();
    } catch (retryError) {
      mapSupabaseError(retryError);
    }
  } catch (e) {
    mapSupabaseError(e);
  }
}
