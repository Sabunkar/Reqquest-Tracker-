import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/requests/data/datasources/request_local_datasource.dart';
import '../features/requests/data/datasources/request_mock_api.dart';
import '../features/requests/data/datasources/shared_preferences_request_datasource.dart';
import '../features/requests/data/repositories/request_repository_impl.dart';
import '../features/requests/domain/repositories/request_repository.dart';
import '../features/settings/data/datasources/settings_local_datasource.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/entities/user_role.dart';
import '../features/settings/domain/repositories/settings_repository.dart';

class ServiceLocator {
  final Map<Type, dynamic> _instances = {};

  void register<T>(T instance) {
    _instances[T] = instance;
  }

  T get<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw StateError('ServiceLocator: Service of type $T is not registered');
    }
    return instance as T;
  }

  T call<T>() => get<T>();

  void reset() {
    _instances.clear();
  }
}

final sl = ServiceLocator();

Future<void> initDependencies({
  SharedPreferences? sharedPreferences,
  Duration mockApiDelay = const Duration(milliseconds: 600),
}) async {
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
  sl.register<SharedPreferences>(prefs);

  // Data Sources
  final requestLocalDataSource = SharedPreferencesRequestDataSource(prefs);
  sl.register<RequestLocalDataSource>(requestLocalDataSource);

  final settingsLocalDataSource = SettingsLocalDataSourceImpl(prefs);
  sl.register<SettingsLocalDataSource>(settingsLocalDataSource);

  final authLocalDataSource = AuthLocalDataSourceImpl(prefs);
  sl.register<AuthLocalDataSource>(authLocalDataSource);

  // Auth Repository
  final authRepository = AuthRepositoryImpl(authLocalDataSource);
  sl.register<AuthRepository>(authRepository);

  // Settings Repository
  final settingsRepository = SettingsRepositoryImpl(
    localDataSource: settingsLocalDataSource,
  );
  sl.register<SettingsRepository>(settingsRepository);

  // Mock API
  final requestMockApi = RequestMockApi(
    localDataSource: requestLocalDataSource,
    artificialDelay: mockApiDelay,
    currentRoleProvider: () {
      final roleStr = settingsLocalDataSource.getUserRole();
      return roleStr == UserRole.reviewer.name
          ? UserRole.reviewer
          : UserRole.user;
    },
    failureSimulationProvider: () {
      return settingsLocalDataSource.getSimulateApiFailure();
    },
  );
  sl.register<RequestMockApi>(requestMockApi);

  // Requests Repository
  final requestRepository = RequestRepositoryImpl(mockApi: requestMockApi);
  sl.register<RequestRepository>(requestRepository);
}
