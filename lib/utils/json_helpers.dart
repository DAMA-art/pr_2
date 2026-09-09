class JsonHelpers {
  static int asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static double asDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  static String asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString();
    return text == 'null' ? fallback : text;
  }

  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<int> asIntList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value) asInt(item),
    ];
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return const {};
  }
}
