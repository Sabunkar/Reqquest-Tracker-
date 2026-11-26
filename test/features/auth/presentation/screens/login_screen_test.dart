import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:request_flow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:request_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/data/repositories/settings_repository_impl.dart';
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

  Widget buildTestWidget({ThemeData? theme}) {
    final testRouter = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Text('Onboarding Page')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard Page')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.lightTheme,
        routerConfig: testRouter,
      ),
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('renders Tracker branding and role selection login controls', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tracker'), findsOneWidget);
      expect(
        find.text('Enterprise Request & Approval Platform'),
        findsOneWidget,
      );
      expect(find.text('Select a role to sign in to Tracker:'), findsOneWidget);

      // Email and password are removed
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Email address'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Remember me'), findsNothing);
      expect(find.text('Log In'), findsNothing);

      // Direct role logins exist
      expect(find.text('Continue as Requester'), findsOneWidget);
      expect(find.text('Continue as Reviewer'), findsOneWidget);
    });

    testWidgets('role login as Requester updates auth and settings state', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue as Requester'));
      await tester.tap(find.text('Continue as Requester'));
      await tester.pumpAndSettle();

      expect(authCubit.state.isAuthenticated, isTrue);
      expect(authCubit.state.user?.role.isUser, isTrue);
      expect(settingsCubit.state.role.isUser, isTrue);
    });

    testWidgets('role login as Reviewer updates auth and settings state', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue as Reviewer'));
      await tester.tap(find.text('Continue as Reviewer'));
      await tester.pumpAndSettle();

      expect(authCubit.state.isAuthenticated, isTrue);
      expect(authCubit.state.user?.role.isReviewer, isTrue);
      expect(settingsCubit.state.role.isReviewer, isTrue);
    });
  });
}
