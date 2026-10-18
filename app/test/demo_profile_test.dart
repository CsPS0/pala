import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala_app/core/adaptive/adaptive_scaffold.dart';
import 'package:pala_app/core/theme/m3_theme.dart';
import 'package:pala_app/state/app_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('hu_HU', null);
  });

  group('Demo Profile ("Teszt Elek") Integrity tests', () {
    testWidgets('loads demo data offline and renders all views', (tester) async {
      final appModel = AppModel();
      await appModel.loginDemo();

      expect(appModel.isDemo, isTrue);
      expect(appModel.isAuthenticated, isTrue);
      expect(appModel.student?.name, contains('Teszt Elek'));
      expect(appModel.grades, isNotEmpty);
      expect(appModel.timetable, isNotEmpty);
      expect(appModel.absences, isNotEmpty);
      expect(appModel.overallGpa, greaterThan(0));

      // Test rendering in Compact viewport
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: M3Theme.darkTheme,
          home: AdaptiveScaffold(appModel: appModel),
        ),
      );
      await tester.pumpAndSettle();

      // Check Demo badge; the PALA badge is hidden on phones
      expect(find.text('DEMÓ'), findsOneWidget);
      expect(find.text('PALA'), findsNothing); // brand badge is wide-only
      expect(find.text('Vezérlőpult'), findsWidgets);
      // Tasks & messages must stay reachable from the phone bar.
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Feladatok')), findsOneWidget);

      // Absences has no phone bar slot; reach it through the dashboard KPI tile.
      await tester.tap(find.text('Hiányzás'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('/ 250 óra'), findsOneWidget);
      expect(find.text('Igazolt'), findsOneWidget);
      expect(find.text('Igazolatlan'), findsOneWidget);

      // Open Global Search and test accent-insensitive search
      await tester.tap(find.byTooltip('Globális kereső'));
      await tester.pump(const Duration(milliseconds: 300));
      final searchBar = find.byType(SearchBar);
      expect(searchBar, findsOneWidget);
      await tester.enterText(searchBar, 'tortenelem');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('JEGYEK'), findsOneWidget);

      // Close Global Search
      Navigator.of(tester.element(searchBar)).pop();
      await tester.pumpAndSettle();

      // Open Pala Wrapped view: the app bar shortcut is wide-only (phones use Settings).
      expect(find.byTooltip('Pala Wrapped éves összegző'), findsNothing);
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pala Wrapped éves összegző'));
      await tester.pumpAndSettle();
      expect(find.text('Itt a te tanéved összegzése'), findsOneWidget);
    });
  });
}
