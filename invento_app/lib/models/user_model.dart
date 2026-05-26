import '../core/utils/date_utils.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.role = 'manager',
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': toTimestamp(createdAt),
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: map['role'] as String? ?? 'manager',
      createdAt: readDateTime(map['createdAt']),
    );
  }
}
