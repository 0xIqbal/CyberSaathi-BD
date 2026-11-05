class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String name;
  final String email;
  final String? createdAt;
}
