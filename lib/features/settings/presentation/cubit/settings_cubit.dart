import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    try {
      final settings = await _repository.getSettings();
      ThemeMode mode;
      switch (settings.themeMode) {
        case 'light':
          mode = ThemeMode.light;
          break;
        case 'dark':
          mode = ThemeMode.dark;
          break;
        default:
          mode = ThemeMode.system;
      }
      emit(
        state.copyWith(
          role: settings.role,
          themeMode: mode,
          simulateApiFailure: settings.simulateApiFailure,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> setUserRole(UserRole role) async {
    emit(state.copyWith(role: role));
    await _repository.setUserRole(role);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _repository.setThemeMode(modeStr);
  }

  Future<void> setSimulateApiFailure(bool simulate) async {
    emit(state.copyWith(simulateApiFailure: simulate));
    await _repository.setSimulateApiFailure(simulate);
  }
}
