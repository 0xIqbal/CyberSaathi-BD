import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiService {
  ApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    return 'http://10.0.2.2:8000/api/v1';
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );

    return _parseResponse(response);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: decoded['message'] as String? ?? 'Request failed.',
        statusCode: response.statusCode,
        code: decoded['code'] as String?,
        errors: decoded['errors'] as Map<String, dynamic>? ?? const {},
      );
    }

    return decoded;
  }
}
