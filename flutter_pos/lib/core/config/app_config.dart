import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/ronspizzapos/backend/public';
    }

    return 'http://localhost/ronspizzapos/backend/public';
  }
  static const String apiVersion = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiVersion';
}
