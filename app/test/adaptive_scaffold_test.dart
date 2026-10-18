import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala_app/core/adaptive/adaptive_breakpoints.dart';
import 'package:pala_app/core/adaptive/adaptive_scaffold.dart';
import 'package:pala_app/core/theme/m3_theme.dart';
import 'package:pala_app/state/app_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu_HU', null);
  });

  group('AdaptiveScaffold & Breakpoints tests', () {
    test('AdaptiveBreakpoints evaluates compact vs expanded thresholds', () {
      expect(AdaptiveBreakpoints.compactBreakpoint, 600.0);
      expect(AdaptiveBreakpoints.isCompactConstraints(const BoxConstraints(maxWidth: 599)), isTrue);
      expect(AdaptiveBreakpoints.isCompactConstraints(const BoxConstraints(maxWidth: 600)), isFalse);
      expect(AdaptiveBreakpoints.isExpandedConstraints(const BoxConstraints(maxWidth: 600)), isTrue);
      expect(AdaptiveBreakpoints.isExpandedConstraints(const BoxConstraints(maxWidth: 1200)), isTrue);
    });

    testWidgets('renders bottom NavigationBar on compact viewport (<600dp)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appModel = AppModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: M3Theme.darkTheme,
          home: AdaptiveScaffold(appModel: appModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('PALA'), findsNothing); // brand badge is wide-only
    });

    testWidgets('renders left NavigationRail on expanded viewport (>=600dp)', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appModel = AppModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: M3Theme.darkTheme,
          home: AdaptiveScaffold(appModel: appModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('PALA'), findsOneWidget);
    });

    testWidgets('preserves active tab and GradesView mock calculator state across <600dp <-> >=600dp resize', (tester) async {
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appModel = AppModel();
      await appModel.loginDemo();

      await tester.pumpWidget(
        MaterialApp(
          theme: M3Theme.darkTheme,
          home: AdaptiveScaffold(appModel: appModel),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify compact NavigationBar is shown
      expect(find.byType(NavigationBar), findsOneWidget);

      // Navigate to Grades tab (index 1)
      await tester.tap(find.text('Jegyek'));
      await tester.pump(const Duration(milliseconds: 200));

      // Enter search text in GradesView
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Mat');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Mat'), findsOneWidget);

      // Resize viewport to Expanded (>=600dp)
      tester.view.physicalSize = const Size(1100, 1200);
      await tester.pump(const Duration(milliseconds: 200));

      // Confirm NavigationRail is now active and search text + tab state persisted
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Mat'), findsOneWidget);

      // Add a mock grade in the inline GhostGradeCalculator panel on Expanded viewport
      final addMockBtn = find.text('Szellem jegy hozzáadása');
      expect(addMockBtn, findsOneWidget);
      await tester.tap(addMockBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Aktív szellem jegyek (1)'), findsOneWidget);

      // Resize back to Compact (<600dp) and then back to Expanded (>=600dp)
      tester.view.physicalSize = const Size(420, 1200);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Mat'), findsOneWidget);

      tester.view.physicalSize = const Size(1100, 1200);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.textContaining('Aktív szellem jegyek (1)'), findsOneWidget);
    });
  });
}
