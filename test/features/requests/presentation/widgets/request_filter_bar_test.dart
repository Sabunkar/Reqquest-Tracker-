import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_flow/app/theme/app_theme.dart';
import 'package:request_flow/features/requests/domain/entities/request_status.dart';
import 'package:request_flow/features/requests/presentation/widgets/request_filter_bar.dart';

void main() {
  Widget buildTestWidget({
    RequestStatus? selectedFilter,
    ValueChanged<RequestStatus?>? onFilterSelected,
    ThemeData? theme,
    double screenWidth = 400,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 800)),
        child: Scaffold(
          body: RequestFilterBar(
            selectedFilter: selectedFilter,
            onFilterSelected: onFilterSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('RequestFilterBar Tests', () {
    testWidgets('renders all five filter labels clearly', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('selected filter has checkmark and white text', (tester) async {
      await tester.pumpWidget(buildTestWidget(selectedFilter: null));

      final allChipFinder = find.byKey(const ValueKey('filter_chip_all'));
      expect(allChipFinder, findsOneWidget);

      final filterChip = tester.widget<FilterChip>(allChipFinder);
      expect(filterChip.selected, isTrue);
      expect(filterChip.showCheckmark, isTrue);
      expect(filterChip.checkmarkColor, Colors.white);
      expect(filterChip.labelStyle?.color, Colors.white);
    });

    testWidgets(
      'unselected filters have visible high-contrast text and no checkmark',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(selectedFilter: null));

        for (final status in RequestStatus.values) {
          final chipFinder = find.byKey(ValueKey('filter_chip_${status.name}'));
          expect(chipFinder, findsOneWidget);

          final filterChip = tester.widget<FilterChip>(chipFinder);
          expect(filterChip.selected, isFalse);
          expect(filterChip.showCheckmark, isFalse);
          // Ensure text color is not null and not white in light theme
          expect(filterChip.labelStyle?.color, isNotNull);
          expect(filterChip.labelStyle?.color, isNot(Colors.white));
        }
      },
    );

    testWidgets(
      'tapping filter chips triggers onFilterSelected with correct status',
      (tester) async {
        RequestStatus? selected;
        await tester.pumpWidget(
          buildTestWidget(
            selectedFilter: null,
            onFilterSelected: (status) {
              selected = status;
            },
          ),
        );

        // Tap 'Draft'
        await tester.tap(find.text('Draft'));
        await tester.pumpAndSettle();
        expect(selected, RequestStatus.draft);

        // Tap 'Submitted'
        await tester.tap(find.text('Submitted'));
        await tester.pumpAndSettle();
        expect(selected, RequestStatus.submitted);

        // Tap 'Approved'
        await tester.tap(find.text('Approved'));
        await tester.pumpAndSettle();
        expect(selected, RequestStatus.approved);

        // Tap 'Rejected'
        await tester.tap(find.text('Rejected'));
        await tester.pumpAndSettle();
        expect(selected, RequestStatus.rejected);

        // Tap 'All'
        await tester.tap(find.text('All'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(selected, isNull);
      },
    );

    testWidgets('renders properly in dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: AppTheme.darkTheme,
          selectedFilter: RequestStatus.draft,
        ),
      );

      final draftChip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('filter_chip_draft')),
      );
      expect(draftChip.selected, isTrue);
      expect(draftChip.labelStyle?.color, Colors.white);

      final allChip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('filter_chip_all')),
      );
      expect(allChip.selected, isFalse);
      expect(allChip.labelStyle?.color, isNotNull);
    });

    testWidgets('responsive on narrow 320dp screen without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(screenWidth: 320));

      // Should not throw overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text('All'), findsOneWidget);
    });
  });
}
