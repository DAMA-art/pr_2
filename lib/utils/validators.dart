class Validators {
  static String? required(String? value, {String field = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field обязательно для заполнения';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'Поле'}) {
    if (value != null && value.length > max) {
      return '$field не должно превышать $max символов';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Поле'}) {
    if (value != null && value.trim().length < min) {
      return '$field должно содержать минимум $min символов';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email обязателен';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Некорректный формат email';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Телефон обязателен';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) {
      return 'Некорректный формат телефона';
    }
    return null;
  }

  static String? positiveInt(String? value, {String field = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$field обязательно';
    final n = int.tryParse(value);
    if (n == null) return '$field должно быть числом';
    if (n <= 0) return '$field должно быть положительным';
    return null;
  }

  static String? nonNegativeInt(String? value, {String field = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$field обязательно';
    final n = int.tryParse(value);
    if (n == null) return '$field должно быть числом';
    if (n < 0) return '$field не может быть отрицательным';
    return null;
  }

  static String? positiveDouble(String? value, {String field = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$field обязательно';
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null) return '$field должно быть числом';
    if (n <= 0) return '$field должно быть положительным';
    return null;
  }

  static String? rangeInt(String? value, int min, int max, {String field = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$field обязательно';
    final n = int.tryParse(value);
    if (n == null) return '$field должно быть числом';
    if (n < min || n > max) return '$field должно быть от $min до $max';
    return null;
  }

  static String? date(String? value, {String field = 'Дата'}) {
    if (value == null || value.trim().isEmpty) return '$field обязательна';
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return '$field должна быть в формате ГГГГ-ММ-ДД';
    return null;
  }

  static String? chipNumber(String? value, {String field = 'Номер чипа'}) {
    return combine([
      () => required(value, field: field),
      () => minLength(value, 8, field: field),
      () => maxLength(value, 20, field: field),
    ]);
  }

  static String? combine(List<String? Function()> validators) {
    for (final v in validators) {
      final err = v();
      if (err != null) return err;
    }
    return null;
  }
}