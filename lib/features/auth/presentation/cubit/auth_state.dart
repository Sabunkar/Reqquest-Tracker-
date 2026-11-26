import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_user.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final AuthUser? user;
  final String? errorMessage;
  final bool rememberMe;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.rememberMe = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    AuthUser? user,
    String? errorMessage,
    bool? rememberMe,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [
    isAuthenticated,
    isLoading,
    user,
    errorMessage,
    rememberMe,
  ];
}
