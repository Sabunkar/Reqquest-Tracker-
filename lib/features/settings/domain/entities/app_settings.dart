import 'package:equatable/equatable.dart';
import 'user_role.dart';

class AppSettings extends Equatable {
  final UserRole role;
  final String themeMode; // 'system', 'light', 'dark'
  final bool simulateApiFailure;

  const AppSettings({
    this.role = UserRole.user,
    this.themeMode = 'system',
    this.simulateApiFailure = false,
  });

  AppSettings copyWith({
    UserRole? role,
    String? themeMode,
    bool? simulateApiFailure,
  }) {
    return AppSettings(
      role: role ?? this.role,
      themeMode: themeMode ?? this.themeMode,
      simulateApiFailure: simulateApiFailure ?? this.simulateApiFailure,
    );
  }

  @override
  List<Object?> get props => [role, themeMode, simulateApiFailure];
}
