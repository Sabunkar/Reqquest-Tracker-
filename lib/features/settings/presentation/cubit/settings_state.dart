import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/user_role.dart';

class SettingsState extends Equatable {
  final UserRole role;
  final ThemeMode themeMode;
  final bool simulateApiFailure;
  final bool isLoading;

  const SettingsState({
    this.role = UserRole.user,
    this.themeMode = ThemeMode.system,
    this.simulateApiFailure = false,
    this.isLoading = false,
  });

  SettingsState copyWith({
    UserRole? role,
    ThemeMode? themeMode,
    bool? simulateApiFailure,
    bool? isLoading,
  }) {
    return SettingsState(
      role: role ?? this.role,
      themeMode: themeMode ?? this.themeMode,
      simulateApiFailure: simulateApiFailure ?? this.simulateApiFailure,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [role, themeMode, simulateApiFailure, isLoading];
}
