import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';

abstract class AuthLocalDataSource {
  Future<AuthUser?> getSavedUser();
  Future<bool> isRememberMe();
  Future<void> saveUser(AuthUser user, {required bool rememberMe});
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  static const String _keyUser = 'auth_saved_user';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keyLoggedIn = 'auth_is_logged_in';

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<AuthUser?> getSavedUser() async {
    final isLoggedIn = _prefs.getBool(_keyLoggedIn) ?? false;
    final rememberMe = _prefs.getBool(_keyRememberMe) ?? false;

    if (!isLoggedIn || !rememberMe) {
      return null;
    }

    final raw = _prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isRememberMe() async {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  @override
  Future<void> saveUser(AuthUser user, {required bool rememberMe}) async {
    await _prefs.setBool(_keyLoggedIn, true);
    await _prefs.setBool(_keyRememberMe, rememberMe);
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearUser() async {
    await _prefs.setBool(_keyLoggedIn, false);
    await _prefs.remove(_keyUser);
    // Keep rememberMe preference or clear as appropriate
  }
}
