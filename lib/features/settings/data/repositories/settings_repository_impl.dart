import '../../domain/entities/app_settings.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<AppSettings> getSettings() async {
    final roleStr = localDataSource.getUserRole();
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.user,
    );

    final themeMode = localDataSource.getThemeMode() ?? 'system';
    final simulateFailure = localDataSource.getSimulateApiFailure();

    return AppSettings(
      role: role,
      themeMode: themeMode,
      simulateApiFailure: simulateFailure,
    );
  }

  @override
  Future<void> setUserRole(UserRole role) async {
    await localDataSource.setUserRole(role.name);
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    await localDataSource.setThemeMode(themeMode);
  }

  @override
  Future<void> setSimulateApiFailure(bool simulate) async {
    await localDataSource.setSimulateApiFailure(simulate);
  }
}
