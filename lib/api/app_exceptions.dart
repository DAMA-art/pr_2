class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Нет соединения с сервером']);
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'Превышено время ожидания ответа сервера',
  ]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Объект не найден']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Требуется вход в систему']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Недостаточно прав для операции']);
}

class ConflictException extends AppException {
  const ConflictException([super.message = 'Конфликт данных']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  const ValidationException(super.message, this.fieldErrors);

  String? errorFor(List<String> keys) {
    for (final key in keys) {
      final value = fieldErrors[key];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class CancelledException extends AppException {
  const CancelledException([super.message = 'Запрос отменён']);
}
