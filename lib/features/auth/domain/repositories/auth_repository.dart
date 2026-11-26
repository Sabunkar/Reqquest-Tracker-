import '../entities/auth_user.dart';

/// Contract defining persistence and retrieval operations for the authenticated user session.
abstract class AuthRepository {
  /// Retrieves the saved user if a valid session exists.
  Future<AuthUser?> getSavedUser();

  /// Returns whether the 'remember me' flag is active.
  Future<bool> isRememberMe();

  /// Persists the active user session.
  Future<void> saveUser(AuthUser user, {required bool rememberMe});

  /// Clears the user session on logout.
  Future<void> clearUser();
}
