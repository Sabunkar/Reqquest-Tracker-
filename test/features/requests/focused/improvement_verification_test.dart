import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/core/widgets/app_drawer.dart';
import 'package:request_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:request_flow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:request_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:request_flow/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_cubit.dart';
import 'package:request_flow/features/requests/presentation/screens/dashboard_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_state.dart';
import 'package:request_flow/features/splash/presentation/screens/splash_screen.dart';
import 'package:request_flow/injection/dependency_injection.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsCubit settingsCubit;
  late AuthCubit authCubit;
  late RequestRepository requestRepo;

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
    requestRepo = sl<RequestRepository>();
    OnboardingScreen.resetSession();
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildScopedTestApp({
    required Widget child,
    double width = 800,
    double height = 1000,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<RequestListCubit>(
          create: (_) => RequestListCubit(requestRepo),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Improvement 1 & 2: AppBar, Drawer, Theme Toggle, and Notifications', () {
    testWidgets(
      'Dashboard AppBar contains Theme Toggle and Notifications, but NOT Settings',
      (tester) async {
        await tester.pumpWidget(
          buildScopedTestApp(child: const DashboardScreen()),
        );
        await tester.pumpAndSettle();

        // Notifications is on the AppBar
        expect(
          find.byKey(const ValueKey('dashboard_notifications_button')),
          findsOneWidget,
        );

        // Theme toggle is on the AppBar
        expect(
          find.byKey(const ValueKey('dashboard_theme_toggle')),
          findsOneWidget,
        );

        // Settings icon is NOT in the Dashboard AppBar
        expect(
          find.widgetWithIcon(IconButton, Icons.settings_outlined),
          findsNothing,
        );
      },
    );

    testWidgets('Theme Toggle applies changes immediately and persists', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScopedTestApp(child: const DashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(settingsCubit.state.themeMode, ThemeMode.system);

      // Toggle to dark
      await tester.tap(find.byKey(const ValueKey('dashboard_theme_toggle')));
      await tester.pumpAndSettle();

      expect(settingsCubit.state.themeMode, ThemeMode.dark);

      // Toggle back to light
      await tester.tap(find.byKey(const ValueKey('dashboard_theme_toggle')));
      await tester.pumpAndSettle();

      expect(settingsCubit.state.themeMode, ThemeMode.light);
    });
  });

  group('Improvement 3: Startup, Mandatory Login, and Onboarding Flow', () {
    testWidgets(
      'Fresh launch does not auto-bypass login even if previously remembered',
      (tester) async {
        // Setup saved user in repository
        await authCubit.loginAsDemoRole(UserRole.user, rememberMe: true);

        // Simulate a brand new launch
        final freshAuthCubit = AuthCubit(
          localDataSource: AuthLocalDataSourceImpl(prefs),
          settingsCubit: settingsCubit,
        );
        await freshAuthCubit.checkAuthStatus();

        // Fresh launch must require explicit user login
        expect(freshAuthCubit.state.isAuthenticated, isFalse);
        expect(
          freshAuthCubit.state.user,
          isNotNull,
        ); // Credential preserved, but session not bypassed
      },
    );

    testWidgets('SplashScreen displays logo, app name, and tagline', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScopedTestApp(
          child: const SplashScreen(delay: Duration(seconds: 10)),
        ),
      );
      await tester.pump();

      expect(find.text('Tracker'), findsOneWidget);
      expect(
        find.text('Enterprise Request Lifecycle & Approval Engine'),
        findsOneWidget,
      );
    });

    testWidgets(
      'OnboardingScreen navigates across all three screens and finishes on Get Started',
      (tester) async {
        final testRouter = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard View')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Screen 1
        expect(find.text('What is Request Tracker?'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Back'), findsNothing);

        // Advance to Screen 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Create & Track Requests'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);

        // Advance to Screen 3
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Reviewer Decisions & Approvals'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(find.text('Skip'), findsNothing);

        // Tap Get Started -> Navigates to Dashboard
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard View'), findsOneWidget);
        expect(OnboardingScreen.hasCompletedThisLaunch, isTrue);
      },
    );

    testWidgets(
      'OnboardingScreen Skip button immediately navigates to Dashboard and marks completed',
      (tester) async {
        final testRouter = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard View')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard View'), findsOneWidget);
        expect(OnboardingScreen.hasCompletedThisLaunch, isTrue);
      },
    );

    testWidgets(
      'Login navigates to Onboarding on first login of launch, and Dashboard on subsequent logins',
      (tester) async {
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
                  const Scaffold(body: Text('Onboarding View')),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard View')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SettingsCubit>.value(value: settingsCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // First login during this launch session -> goes to onboarding
        await tester.tap(find.text('Continue as Requester'));
        await tester.pumpAndSettle();

        expect(find.text('Onboarding View'), findsOneWidget);

        // Now mark onboarding as completed
        OnboardingScreen.hasCompletedThisLaunch = true;

        // Navigate back to login
        testRouter.go('/login');
        await tester.pumpAndSettle();

        // Second login during this launch session -> goes directly to dashboard
        await tester.ensureVisible(find.text('Continue as Reviewer'));
        await tester.tap(find.text('Continue as Reviewer'));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard View'), findsOneWidget);
      },
    );
  });

  group('Improvement 4 & 6: Prominent Request ID and Export PDF Button', () {
    testWidgets(
      'RequestDetailScreen displays prominent Request ID and noticeable Export PDF button',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final sample = requests.first;

        await tester.pumpWidget(
          buildScopedTestApp(child: RequestDetailScreen(requestId: sample.id)),
        );
        await tester.pumpAndSettle();

        // Verify prominent Request ID banner
        expect(find.text('REQUEST ID'), findsOneWidget);
        expect(find.text(sample.id), findsOneWidget);

        // Verify noticeable Export PDF button (icon + text)
        expect(find.widgetWithText(FilledButton, 'Export PDF'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Export PDF'),
          findsOneWidget,
        );
      },
    );
  });

  group('Improvement 5: Role Switching in Navigation Drawer', () {
    testWidgets(
      'Drawer role switcher updates state and active role immediately',
      (tester) async {
        await tester.pumpWidget(
          buildScopedTestApp(
            child: Scaffold(
              drawer: const AppDrawer(currentLocation: '/dashboard'),
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    child: const Text('Open Drawer'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open drawer
        await tester.tap(find.text('Open Drawer'));
        await tester.pumpAndSettle();

        expect(find.text('ACTIVE ROLE'), findsOneWidget);
        expect(settingsCubit.state.role, UserRole.user);

        // Switch to Reviewer
        await tester.tap(find.byKey(const ValueKey('drawer_role_reviewer')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.role, UserRole.reviewer);

        // Switch back to Requester
        await tester.tap(find.byKey(const ValueKey('drawer_role_requester')));
        await tester.pumpAndSettle();

        expect(settingsCubit.state.role, UserRole.user);
      },
    );
  });
}
