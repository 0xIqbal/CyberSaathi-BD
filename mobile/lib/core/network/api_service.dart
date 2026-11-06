import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';

class ApiService {
  ApiService({
    Dio? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? _defaultBaseUrl,
                connectTimeout: const Duration(seconds: 120),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 120),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) => handler.next(error),
      ),
    );
  }

  static const _tokenKey = 'auth_token';

  final Dio _client;
  final FlutterSecureStorage _storage;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    return 'http://10.0.2.2:8000/api/v1';
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await _client.post(
        path,
        data: body ?? <String, dynamic>{},
        options: _authorizationOptions(token),
      );
      return _parseResponse(response.data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final response = await _client.get(
        path,
        options: _authorizationOptions(token),
      );
      return _parseResponse(response.data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> upload(
    String path, {
    required MultipartFile file,
    required String fieldName,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return multipart(
      path,
      fields: <String, dynamic>{fieldName: file},
      onSendProgress: onSendProgress,
    );
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, dynamic> fields = const {},
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _client.post(
        path,
        data: FormData.fromMap(fields),
        onSendProgress: onSendProgress,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return _parseResponse(response.data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Options? _authorizationOptions(String? token) {
    final headers = _authorizationHeaders(token);
    return headers.isEmpty ? null : Options(headers: headers);
  }

  Map<String, String> _authorizationHeaders(String? token) {
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid response.',
      );
    }
    return data;
  }

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    final payload =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return ApiException(
      message: payload['message'] as String? ?? 'Request failed.',
      statusCode: error.response?.statusCode,
      code: payload['code'] as String?,
      errors: payload['errors'] as Map<String, dynamic>? ?? const {},
    );
  }
}
