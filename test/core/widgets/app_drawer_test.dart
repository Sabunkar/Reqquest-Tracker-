import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/core/widgets/app_drawer.dart';
import 'package:request_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:request_flow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsCubit settingsCubit;
  late AuthCubit authCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepositoryImpl(
      localDataSource: SettingsLocalDataSourceImpl(prefs),
    );
    settingsCubit = SettingsCubit(settingsRepo);
    authCubit = AuthCubit(
      localDataSource: AuthLocalDataSourceImpl(prefs),
      settingsCubit: settingsCubit,
    );
  });

  Widget buildTestWidget({
    String currentLocation = '/dashboard',
    ThemeData? theme,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1000)),
          child: Scaffold(
            drawer: AppDrawer(currentLocation: currentLocation),
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AppDrawer Tests', () {
    testWidgets(
      'renders drawer navigation destinations without Notifications',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open drawer
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Verify workflow destinations
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('My Requests'), findsOneWidget);
        expect(find.text('Create Request'), findsOneWidget);
        expect(find.text('Review Queue'), findsOneWidget);
        expect(find.text('Activity History'), findsOneWidget);
        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Help & About'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);

        // Verify Notifications is removed from drawer
        expect(find.widgetWithText(ListTile, 'Notifications'), findsNothing);

        // Verify Role Switcher is present in drawer
        expect(find.text('ACTIVE ROLE'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('drawer_role_requester')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('drawer_role_reviewer')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'role switcher in drawer switches active role and updates state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open drawer
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Tap 'Reviewer' in the role switcher
        await tester.tap(find.byKey(const ValueKey('drawer_role_reviewer')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.role, UserRole.reviewer);

        // Tap 'Requester' to switch back
        await tester.tap(find.byKey(const ValueKey('drawer_role_requester')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.role, UserRole.user);
      },
    );

    testWidgets('displays Requester profile info in header', (tester) async {
      await authCubit.loginAsDemoRole(UserRole.user);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Alex Johnson'), findsOneWidget);
      expect(find.text('requester@requestflow.internal'), findsOneWidget);
      expect(find.text('Requester'), findsWidgets);
      expect(find.text('AJ'), findsOneWidget);
    });

    testWidgets(
      'displays Reviewer profile info in header and restricts Create Request',
      (tester) async {
        await authCubit.loginAsDemoRole(UserRole.reviewer);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Sarah Miller'), findsOneWidget);
        expect(find.text('reviewer@requestflow.internal'), findsOneWidget);
        expect(find.text('Approver'), findsOneWidget);
        expect(find.text('SM'), findsOneWidget);

        // Tap Create Request as Reviewer
        await tester.tap(find.text('Create Request'));
        await tester.pumpAndSettle();

        // Should show SnackBar explaining permission restriction
        expect(
          find.text(
            'Reviewers cannot create requests. Switch to Requester role in Settings to create requests.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping Logout displays confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
