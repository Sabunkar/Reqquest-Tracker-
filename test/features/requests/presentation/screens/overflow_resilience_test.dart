import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/core/widgets/app_drawer.dart';
import 'package:request_flow/features/about/presentation/screens/about_screen.dart';
import 'package:request_flow/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:request_flow/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:request_flow/features/auth/presentation/screens/login_screen.dart';
import 'package:request_flow/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:request_flow/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:request_flow/features/profile/presentation/screens/profile_screen.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/domain/repositories/request_repository.dart';
import 'package:request_flow/features/requests/presentation/cubit/request_list_cubit.dart';
import 'package:request_flow/features/requests/presentation/screens/activity_history_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/create_request_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/dashboard_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/edit_request_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/request_list_screen.dart';
import 'package:request_flow/features/requests/presentation/screens/review_queue_screen.dart';
import 'package:request_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:request_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:request_flow/features/settings/domain/entities/user_role.dart';
import 'package:request_flow/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:request_flow/features/settings/presentation/screens/settings_screen.dart';
import 'package:request_flow/injection/dependency_injection.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsCubit settingsCubit;
  late AuthCubit authCubit;
  late RequestListCubit requestListCubit;
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
    requestListCubit = RequestListCubit(requestRepo);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildScreenTestWidget({
    required Widget child,
    double width = 360,
    double height = 640,
    double textScale = 1.0,
    UserRole role = UserRole.user,
  }) {
    settingsCubit.setUserRole(role);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              textScaler: TextScaler.linear(textScale),
            ),
            child: child,
          ),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<RequestListCubit>.value(value: requestListCubit),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('Request Detail Screen Overflow Resilience Tests', () {
    testWidgets(
      'renders draft request on narrow mobile (320dp) with zero overflow',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final draft = requests.firstWhere(
          (r) => r.status == RequestStatus.draft,
        );

        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: RequestDetailScreen(requestId: draft.id),
            width: 320,
            height: 600,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(draft.title), findsOneWidget);
      },
    );

    testWidgets(
      'renders submitted request for reviewer on 360dp with high text scaling without overflow',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final submitted = requests.firstWhere(
          (r) => r.status == RequestStatus.submitted,
        );

        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: RequestDetailScreen(requestId: submitted.id),
            width: 360,
            height: 740,
            textScale: 1.25,
            role: UserRole.reviewer,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Approve Request'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
      },
    );

    testWidgets(
      'renders rejected request with lengthy rejection reason without overflow',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final rejected = requests.firstWhere(
          (r) => r.status == RequestStatus.rejected,
        );

        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: RequestDetailScreen(requestId: rejected.id),
            width: 360,
            height: 740,
            role: UserRole.user,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Rejection Reason'), findsOneWidget);
        expect(find.text(rejected.rejectionReason!), findsOneWidget);
      },
    );

    testWidgets(
      'renders read-only status banner without overflow when user views submitted request',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final submitted = requests.firstWhere(
          (r) => r.status == RequestStatus.submitted,
        );

        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: RequestDetailScreen(requestId: submitted.id),
            width: 320,
            height: 568,
            role: UserRole.user,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.text('Submitted for Review • Awaiting Approval'),
          findsOneWidget,
        );
      },
    );
  });

  group('Application-Wide Screen Overflow Resilience Tests', () {
    testWidgets(
      'RequestListScreen renders cleanly on 320dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const RequestListScreen(),
            width: 320,
            height: 568,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Requests'), findsOneWidget);
      },
    );

    testWidgets(
      'CreateRequestScreen renders cleanly on 320dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const CreateRequestScreen(),
            width: 320,
            height: 568,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('New Request'), findsOneWidget);
      },
    );

    testWidgets(
      'EditRequestScreen renders cleanly on 320dp width without overflow',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final draft = requests.firstWhere(
          (r) => r.status == RequestStatus.draft,
        );

        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: EditRequestScreen(requestId: draft.id),
            width: 320,
            height: 568,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Save Changes'), findsOneWidget);
      },
    );

    testWidgets(
      'SettingsScreen renders cleanly on 320dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const SettingsScreen(),
            width: 320,
            height: 568,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets('LoginScreen renders cleanly on 320dp width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreenTestWidget(
          child: const LoginScreen(),
          width: 320,
          height: 568,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tracker'), findsOneWidget);
    });

    testWidgets(
      'RequestDetailScreen prominently displays Request ID and Export PDF button',
      (tester) async {
        final requests = await requestRepo.getRequests();
        final draft = requests.firstWhere(
          (r) => r.status == RequestStatus.draft,
        );

        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: RequestDetailScreen(requestId: draft.id),
            width: 320,
            height: 600,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('REQUEST ID'), findsOneWidget);
        expect(find.text(draft.id), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Export PDF'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Export PDF'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OnboardingScreen renders cleanly on 320dp, 360dp, and 390dp without overflow',
      (tester) async {
        for (final width in [320.0, 360.0, 390.0]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildScreenTestWidget(
              child: const OnboardingScreen(),
              width: width,
              height: 700,
              textScale: 1.25,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('What is Request Tracker?'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'DashboardScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const DashboardScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Request Overview'), findsOneWidget);
        expect(find.text('Recent Activity'), findsOneWidget);
      },
    );

    testWidgets(
      'ReviewQueueScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const ReviewQueueScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
            role: UserRole.reviewer,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Review Queue'), findsOneWidget);
      },
    );

    testWidgets(
      'ActivityHistoryScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const ActivityHistoryScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Activity History'), findsOneWidget);
      },
    );

    testWidgets(
      'NotificationsScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const NotificationsScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Notifications'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const ProfileScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('My Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'AboutScreen renders cleanly on 320dp width with 1.25x text scaling without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const AboutScreen(),
            width: 320,
            height: 640,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Help & About'), findsOneWidget);
      },
    );

    testWidgets(
      'AppDrawer renders cleanly in narrow and landscape modes without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildScreenTestWidget(
            child: const Scaffold(
              drawer: AppDrawer(),
              body: Center(child: Text('Home')),
            ),
            width: 320,
            height: 568,
            textScale: 1.25,
          ),
        );
        await tester.pumpAndSettle();

        final scaffoldState = tester.firstState<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('ACTIVE ROLE'), findsOneWidget);
      },
    );
  });
}
