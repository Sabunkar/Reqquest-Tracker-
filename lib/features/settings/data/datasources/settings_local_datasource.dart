import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_constants.dart';

abstract class SettingsLocalDataSource {
  String? getUserRole();
  Future<void> setUserRole(String role);
  String? getThemeMode();
  Future<void> setThemeMode(String themeMode);
  bool getSimulateApiFailure();
  Future<void> setSimulateApiFailure(bool simulate);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences _sharedPreferences;

  SettingsLocalDataSourceImpl(this._sharedPreferences);

  @override
  String? getUserRole() {
    return _sharedPreferences.getString(AppConstants.keyUserRole);
  }

  @override
  Future<void> setUserRole(String role) async {
    await _sharedPreferences.setString(AppConstants.keyUserRole, role);
  }

  @override
  String? getThemeMode() {
    return _sharedPreferences.getString(AppConstants.keyThemeMode);
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    await _sharedPreferences.setString(AppConstants.keyThemeMode, themeMode);
  }

  @override
  bool getSimulateApiFailure() {
    return _sharedPreferences.getBool(AppConstants.keySimulateFailure) ?? false;
  }

  @override
  Future<void> setSimulateApiFailure(bool simulate) async {
    await _sharedPreferences.setBool(AppConstants.keySimulateFailure, simulate);
  }
}
