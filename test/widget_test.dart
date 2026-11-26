import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:request_flow/app/app.dart';
import 'package:request_flow/app/routes/app_router.dart';
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

  testWidgets(
    'App renders Tracker dashboard successfully with seeded requests',
    (tester) async {
      await tester.pumpWidget(const RequestFlowApp());
      await tester.pumpAndSettle();

      expect(find.text('Tracker'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard_total_card')),
        findsOneWidget,
      );
      // Verifies seed data is displayed on dashboard
      expect(find.text('REQ-1001: Leave Request'), findsOneWidget);
    },
  );
}
