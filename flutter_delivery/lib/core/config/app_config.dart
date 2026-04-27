class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiVersion';
}
