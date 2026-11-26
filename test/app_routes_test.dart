import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/app.dart';
import 'package:request_flow/app/routes/app_router.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/injection/dependency_injection.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initDependencies(mockApiDelay: Duration.zero);
    AppRouter.router.go(AppRouter.dashboardPath);
  });

  tearDown(() {
    sl.reset();
  });

  group('Route resolution and theme tests', () {
    testWidgets('Dashboard route resolves and displays title', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();
      expect(find.text('Tracker'), findsOneWidget);
    });

    testWidgets('Create request route resolves', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.createRequestPath);
      await tester.pumpAndSettle();

      expect(find.text('New Request'), findsOneWidget);
      expect(find.text('Save as Draft'), findsOneWidget);
    });

    testWidgets('Settings route resolves and displays options', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.settingsPath);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.text('User Profile & Role'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(
        find.text('Simulate API Failure', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('Request detail route resolves for existing request', (
      tester,
    ) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      // Navigate to seeded REQ-1001
      AppRouter.router.go('/requests/f1a00001-0000-4000-8000-000000000001');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Request Details'), findsOneWidget);
    });

    testWidgets(
      'Login route resolves and displays branding and demo login options',
      (tester) async {
        await tester.pumpWidget(const RequestFlowApp());
        await tester.pumpAndSettle();

        AppRouter.router.go(AppRouter.loginPath);
        await tester.pumpAndSettle();

        expect(find.text('Tracker'), findsWidgets);
        expect(find.text('Continue as Requester'), findsOneWidget);
        expect(find.text('Continue as Reviewer'), findsOneWidget);
      },
    );

    testWidgets('Review queue route resolves', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.reviewQueuePath);
      await tester.pumpAndSettle();

      expect(find.text('Review Queue'), findsOneWidget);
    });

    testWidgets('Activity history route resolves', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.activityHistoryPath);
      await tester.pumpAndSettle();

      expect(find.text('Activity History'), findsOneWidget);
    });

    testWidgets('Profile route resolves', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.profilePath);
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('About route resolves', (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      AppRouter.router.go(AppRouter.aboutPath);
      await tester.pumpAndSettle();

      expect(find.text('Help & About'), findsOneWidget);
    });

    test('Theme configurations have valid light and dark definitions', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
    });
  });
}
