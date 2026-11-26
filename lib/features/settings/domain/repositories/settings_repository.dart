import '../entities/app_settings.dart';
import '../entities/user_role.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> setUserRole(UserRole role);
  Future<void> setThemeMode(String themeMode);
  Future<void> setSimulateApiFailure(bool simulate);
}
