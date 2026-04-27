import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiClient {
  String? token;
  int? branchId;
  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}$path'),
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      return _decode(response.statusCode, response.body);
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'message': 'Timeout al conectar con API (${AppConfig.apiUrl})',
      };
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'No se pudo conectar con API (${AppConfig.apiUrl})',
      };
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> payload) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiUrl}$path'),
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      return _decode(response.statusCode, response.body);
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'message': 'Timeout al conectar con API (${AppConfig.apiUrl})',
      };
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'No se pudo conectar con API (${AppConfig.apiUrl})',
      };
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiUrl}$path'), headers: _headers())
          .timeout(_timeout);
      return _decode(response.statusCode, response.body);
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'message': 'Timeout al conectar con API (${AppConfig.apiUrl})',
      };
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'No se pudo conectar con API (${AppConfig.apiUrl})',
      };
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (branchId != null) {
      headers['X-Branch-Id'] = '$branchId';
    }
    return headers;
  }

  Map<String, dynamic> _decode(int statusCode, String raw) {
    try {
      final dynamic decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        if (!decoded.containsKey('success') && statusCode >= 400) {
          decoded['success'] = false;
        }
        return decoded;
      }
      return <String, dynamic>{
        'success': false,
        'message': 'Respuesta invalida del API',
      };
    } on FormatException {
      return <String, dynamic>{
        'success': false,
        'message': 'Respuesta no JSON del API (status $statusCode)',
      };
    }
  }
}
