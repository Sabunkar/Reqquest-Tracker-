import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl(this.localDataSource);

  @override
  Future<AuthUser?> getSavedUser() => localDataSource.getSavedUser();

  @override
  Future<bool> isRememberMe() => localDataSource.isRememberMe();

  @override
  Future<void> saveUser(AuthUser user, {required bool rememberMe}) =>
      localDataSource.saveUser(user, rememberMe: rememberMe);

  @override
  Future<void> clearUser() => localDataSource.clearUser();
}
