import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:request_flow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_cubit.dart';
import 'package:request_flow/features/requests/presentation/screens/dashboard_screen.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_state.dart';
import 'package:request_flow/injection/dependency_injection.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsCubit settingsCubit;
  late AuthCubit authCubit;
  late RequestListCubit requestListCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initDependencies(mockApiDelay: Duration.zero);
    prefs = sl<SharedPreferences>();
    final settingsRepo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(prefs),
    );
    settingsCubit = SettingsCubit(settingsRepo);
    authCubit = AuthCubit(
      localDataSource: AuthLocalDataSourceImpl(prefs),
      settingsCubit: settingsCubit,
    );
    requestListCubit = RequestListCubit(sl<RequestRepository>());
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget({double width = 800}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<RequestListCubit>.value(value: requestListCubit),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: const DashboardScreen(),
          ),
        ),
      ),
    );
  }

  group('DashboardScreen Resilience Tests', () {
    testWidgets(
      'renders properly without assertion errors on standard desktop width',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(width: 1200));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Tracker'), findsOneWidget);
        expect(find.text('Request Overview'), findsOneWidget);
      },
    );

    testWidgets(
      'renders without throwing when width is ultra narrow (e.g. 50dp or 0dp)',
      (tester) async {
        // Test ultra-narrow constraints where columns * spacing would exceed available width
        await tester.pumpWidget(buildTestWidget(width: 50));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'handles tight zero-width constraints without negative BoxConstraints',
      (tester) async {
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<RequestListCubit>.value(value: requestListCubit),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(width: 0, child: DashboardScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must not throw BoxConstraints has a negative minimum width
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Dashboard AppBar renders theme toggle and notifications buttons',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(width: 800));
        await tester.pumpAndSettle();

        // Verify Theme Toggle and Notifications buttons in AppBar
        expect(
          find.byKey(const ValueKey('dashboard_theme_toggle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dashboard_notifications_button')),
          findsOneWidget,
        );

        // Verify tapping Theme Toggle toggles theme mode
        expect(settingsCubit.state.themeMode, ThemeMode.system);
        await tester.tap(find.byKey(const ValueKey('dashboard_theme_toggle')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.themeMode, ThemeMode.dark);
        expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);

        // Tap again to switch to Light Theme
        await tester.tap(find.byKey(const ValueKey('dashboard_theme_toggle')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.themeMode, ThemeMode.light);
        expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);
      },
    );

    testWidgets(
      'greeting card displays Total Requests summary and overview has 4 status cards',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(width: 800));
        await tester.pumpAndSettle();

        // Total Requests summary card is in the greeting card
        expect(
          find.byKey(const ValueKey('dashboard_total_card')),
          findsOneWidget,
        );
        expect(find.text('Total Requests'), findsOneWidget);

        // 'New Request' button is NOT in the greeting card
        // (verified by checking that find.widgetWithText(ElevatedButton, 'New Request') is absent)
        expect(
          find.widgetWithText(ElevatedButton, 'New Request'),
          findsNothing,
        );

        // Request Overview has the 4 status cards: Draft, Submitted, Approved, Rejected
        expect(find.text('Draft'), findsWidgets);
        expect(find.text('Submitted'), findsWidgets);
        expect(find.text('Approved'), findsWidgets);
        expect(find.text('Rejected'), findsWidgets);
      },
    );
  });
}
