import 'user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.token});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  final User user;
  final String token;
}
