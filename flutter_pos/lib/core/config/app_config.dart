import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _hostgatorBaseUrl =
      'https://ronspizza.net/ronspizzapos/backend/public';
  static const String _apiVersion = '/api/v1';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return _normalizeBaseUrl(override);
    }

    // Default deployment target is HostGator.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _normalizeBaseUrl(_hostgatorBaseUrl);
    }

    return _normalizeBaseUrl(_hostgatorBaseUrl);
  }

  static const String apiVersion = _apiVersion;

  static String get apiUrl => '$apiBaseUrl$apiVersion';

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _hostgatorBaseUrl;
    }

    var value = trimmed;
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    if (value.endsWith(_apiVersion)) {
      value = value.substring(0, value.length - _apiVersion.length);
      while (value.endsWith('/')) {
        value = value.substring(0, value.length - 1);
      }
    }

    return value;
  }
}
