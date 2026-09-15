import 'package:flutter_test/flutter_test.dart';
import 'package:pr_2/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('пустая строка отклоняется', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
    test('непустая принимается', () {
      expect(Validators.required('Барсик'), isNull);
    });
  });

  group('Validators.email', () {
    test('некорректный email', () {
      expect(Validators.email('abc'), isNotNull);
    });
    test('корректный email', () {
      expect(Validators.email('a@b.ru'), isNull);
    });
  });

  group('Validators.phone', () {
    test('короткий номер отклоняется', () {
      expect(Validators.phone('123'), isNotNull);
    });
  });

  group('Validators.positiveInt', () {
    test('ноль и отрицательное отклоняются', () {
      expect(Validators.positiveInt('0'), isNotNull);
      expect(Validators.positiveInt('-1'), isNotNull);
    });
    test('положительное принимается', () {
      expect(Validators.positiveInt('5'), isNull);
    });
  });
}
