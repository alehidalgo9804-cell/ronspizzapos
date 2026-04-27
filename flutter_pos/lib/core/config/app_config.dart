import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _hostgatorBaseUrl =
      'https://ronspizza.net/ronspizzapos/backend/public';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    // Default deployment target is HostGator.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _hostgatorBaseUrl;
    }

    return _hostgatorBaseUrl;
  }

  static const String apiVersion = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiVersion';
}
