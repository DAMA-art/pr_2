import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: Role.fromCode(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.code,
  };
}
