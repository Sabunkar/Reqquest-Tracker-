import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../settings/domain/entities/user_role.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final SettingsCubit settingsCubit;

  AuthCubit({
    AuthRepository? repository,
    AuthLocalDataSource? localDataSource,
    required this.settingsCubit,
  }) : _repository =
           repository ??
           (localDataSource != null
               ? AuthRepositoryImpl(localDataSource)
               : throw ArgumentError(
                   'Either repository or localDataSource must be provided',
                 )),
       super(const AuthState()) {
    checkAuthStatus();
  }

  AuthCubit.withDependencies(
    AuthLocalDataSource localDataSource,
    this.settingsCubit,
  ) : _repository = AuthRepositoryImpl(localDataSource),
      super(const AuthState()) {
    checkAuthStatus();
  }

  static const AuthUser demoRequester = AuthUser(
    id: 'usr_requester_01',
    email: 'requester@requestflow.internal',
    name: 'Alex Johnson',
    role: UserRole.user,
    department: 'Engineering Operations',
  );

  static const AuthUser demoReviewer = AuthUser(
    id: 'usr_reviewer_02',
    email: 'reviewer@requestflow.internal',
    name: 'Sarah Miller',
    role: UserRole.reviewer,
    department: 'Compliance & Approvals',
  );

  Future<void> checkAuthStatus() async {
    emit(state.copyWith(isLoading: true));
    try {
      final savedUser = await _repository.getSavedUser();
      final rememberMe = await _repository.isRememberMe();

      if (savedUser != null) {
        // Keep settings synchronized with saved role
        await settingsCubit.setUserRole(savedUser.role);
        emit(
          state.copyWith(
            isAuthenticated: false, // Mandatory login on every fresh launch
            user: savedUser,
            rememberMe: rememberMe,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isAuthenticated: false,
            user: null,
            rememberMe: rememberMe,
            isLoading: false,
          ),
        );
      }
    } catch (_) {
      emit(state.copyWith(isAuthenticated: false, isLoading: false));
    }
  }

  void toggleRememberMe(bool value) {
    emit(state.copyWith(rememberMe: value));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  Future<bool> loginWithCredentials({
    required String email,
    required String password,
    required bool rememberMe,
    Duration delay = Duration.zero,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    // Validation
    if (trimmedEmail.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Email address is required.',
        ),
      );
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Please enter a valid work email address.',
        ),
      );
      return false;
    }

    if (trimmedPassword.isEmpty) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Password is required.'),
      );
      return false;
    }

    if (trimmedPassword.length < 6) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Password must be at least 6 characters long.',
        ),
      );
      return false;
    }

    // Role assignment based on email keyword or match
    final isReviewer =
        trimmedEmail.contains('reviewer') ||
        trimmedEmail.contains('approver') ||
        trimmedEmail.contains('admin');

    final role = isReviewer ? UserRole.reviewer : UserRole.user;
    final name = isReviewer ? 'Sarah Miller' : 'Alex Johnson';
    final department = isReviewer
        ? 'Compliance & Approvals'
        : 'Engineering Operations';

    final user = AuthUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: trimmedEmail,
      name: name,
      role: role,
      department: department,
    );

    // Save and synchronize
    await _repository.saveUser(user, rememberMe: rememberMe);
    await settingsCubit.setUserRole(role);

    emit(
      state.copyWith(
        isAuthenticated: true,
        user: user,
        rememberMe: rememberMe,
        isLoading: false,
      ),
    );
    return true;
  }

  Future<void> loginAsDemoRole(
    UserRole role, {
    bool rememberMe = true,
    Duration delay = Duration.zero,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final user = role == UserRole.reviewer ? demoReviewer : demoRequester;

    await _repository.saveUser(user, rememberMe: rememberMe);
    await settingsCubit.setUserRole(role);

    emit(
      state.copyWith(
        isAuthenticated: true,
        user: user,
        rememberMe: rememberMe,
        isLoading: false,
      ),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoading: true));
    await _repository.clearUser();
    emit(
      state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  void onRoleChangedInSettings(UserRole newRole) {
    if (state.user != null && state.user!.role != newRole) {
      final updatedUser = state.user!.copyWith(
        role: newRole,
        name: newRole == UserRole.reviewer ? 'Sarah Miller' : 'Alex Johnson',
        department: newRole == UserRole.reviewer
            ? 'Compliance & Approvals'
            : 'Engineering Operations',
      );
      _repository.saveUser(updatedUser, rememberMe: state.rememberMe);
      emit(state.copyWith(user: updatedUser));
    }
  }
}
