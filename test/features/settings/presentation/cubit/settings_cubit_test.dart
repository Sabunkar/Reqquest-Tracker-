import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:request_flow/features/settings/domain/entities/app_settings.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:request_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('SettingsCubit', () {
    late MockSettingsRepository mockRepo;
    late SettingsCubit cubit;

    setUp(() {
      mockRepo = MockSettingsRepository();
      cubit = SettingsCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default user role and system theme mode', () {
      expect(cubit.state, const SettingsState());
      expect(cubit.state.role, UserRole.user);
      expect(cubit.state.themeMode, ThemeMode.system);
    });

    blocTest<SettingsCubit, SettingsState>(
      'loads settings correctly',
      build: () {
        when(() => mockRepo.getSettings()).thenAnswer(
          (_) async => const AppSettings(
            role: UserRole.reviewer,
            themeMode: 'dark',
            simulateApiFailure: true,
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsState(isLoading: true),
        const SettingsState(
          role: UserRole.reviewer,
          themeMode: ThemeMode.dark,
          simulateApiFailure: true,
          isLoading: false,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setUserRole updates role and persists',
      build: () {
        when(
          () => mockRepo.setUserRole(UserRole.reviewer),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.setUserRole(UserRole.reviewer),
      expect: () => [const SettingsState(role: UserRole.reviewer)],
      verify: (_) {
        verify(() => mockRepo.setUserRole(UserRole.reviewer)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setThemeMode updates theme and persists',
      build: () {
        when(() => mockRepo.setThemeMode('light')).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.setThemeMode(ThemeMode.light),
      expect: () => [const SettingsState(themeMode: ThemeMode.light)],
      verify: (_) {
        verify(() => mockRepo.setThemeMode('light')).called(1);
      },
    );
  });
}
