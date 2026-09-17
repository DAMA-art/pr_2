import 'package:flutter_test/flutter_test.dart';
import 'package:pr_2/api/app_exceptions.dart';
import 'package:pr_2/api/supabase_errors.dart';

void main() {
  test('23505 становится ConflictException', () {
    final e = exceptionFromPostgrest(
      code: '23505',
      statusCode: '409',
      message: 'duplicate key chip_number',
    );
    expect(e, isA<ConflictException>());
    expect(e.message, contains('чипа'));
  });

  test('422 становится ValidationException', () {
    final e = exceptionFromPostgrest(
      code: '23514',
      statusCode: '422',
      message: 'check constraint',
      fieldErrors: {'age_months': 'диапазон'},
    );
    expect(e, isA<ValidationException>());
    expect((e as ValidationException).fieldErrors['age_months'], 'диапазон');
  });

  test('jwt становится UnauthorizedException', () {
    final e = exceptionFromPostgrest(
      code: 'PGRST301',
      statusCode: '401',
      message: 'JWT expired',
    );
    expect(e, isA<UnauthorizedException>());
  });

  test('ValidationException.errorFor ищет ключи поля', () {
    const e = ValidationException('fail', {'chip_number': 'занят'});
    expect(e.errorFor(['chipNumber', 'chip_number']), 'занят');
    expect(e.errorFor(['email']), isNull);
  });

  test('пересечение мастера — конфликт', () {
    final e = exceptionFromPostgrest(
      code: '23505',
      statusCode: null,
      message: 'Мастер уже занят в выбранный интервал',
    );
    expect(e, isA<ConflictException>());
  });
}
