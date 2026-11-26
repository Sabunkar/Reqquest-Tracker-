import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/user_role.dart';

/// Represents an authenticated user in the simulated authentication system.
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String department;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.department,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'department': department,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String? ?? 'user_1',
    email: json['email'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: (json['role'] as String?) == UserRole.reviewer.name
        ? UserRole.reviewer
        : UserRole.user,
    department: json['department'] as String? ?? 'General Operations',
  );

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? department,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
    );
  }

  @override
  List<Object?> get props => [id, email, name, role, department];
}
