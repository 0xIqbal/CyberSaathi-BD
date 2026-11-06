import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticated,
  submitting,
  error
}

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;
  AuthStatus status = AuthStatus.initializing;
  User? user;
  String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  Future<void> restoreSession() async {
    try {
      user = await _repository.restore();
      status =
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    } on ApiException {
      user = null;
      status = AuthStatus.unauthenticated;
    } catch (_) {
      user = null;
      status = AuthStatus.error;
      errorMessage = 'Unable to restore your session.';
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      user = (await _repository.login(email: email, password: password)).user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmation,
  ) async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      user = (await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: confirmation,
      ))
          .user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      user = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
