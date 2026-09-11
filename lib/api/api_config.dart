class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);

  static const int forceDelayMs = int.fromEnvironment('API_DELAY_MS', defaultValue: 0);
  static const int forceFailCode = int.fromEnvironment('API_FAIL', defaultValue: 0);
}
