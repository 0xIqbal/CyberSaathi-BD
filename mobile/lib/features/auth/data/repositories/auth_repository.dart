import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../models/auth_session.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(
    this._api, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  final ApiService _api;
  final FlutterSecureStorage _storage;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return _saveSession(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return _saveSession(response);
  }

  Future<User?> restore() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _api.get('/auth/me', token: token);
      return User.fromJson(response['data']['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _storage.delete(key: _tokenKey);
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    try {
      if (token != null) await _api.post('/auth/logout', token: token);
    } finally {
      await _storage.delete(key: _tokenKey);
    }
  }

  Future<AuthSession> _saveSession(Map<String, dynamic> response) async {
    final session = AuthSession.fromJson(
      response['data'] as Map<String, dynamic>,
    );
    await _storage.write(key: _tokenKey, value: session.token);
    return session;
  }
}
