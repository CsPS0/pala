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
      // The phone bar holds Mulasztások itself; the rest is under "Több".
      final bar = find.byType(NavigationBar);
      expect(find.descendant(of: bar, matching: find.text('Mulasztás')), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.text('Több')), findsOneWidget);

      // "Több" lists Feladatok & Dolgozatok, Üzenetek and Fiók & Profil.
      await tester.tap(find.descendant(of: bar, matching: find.text('Több')));
      await tester.pumpAndSettle();
      expect(find.text('Üzenetek'), findsWidgets);
      expect(find.text('Feladatok & Dolgozatok'), findsOneWidget);
      expect(find.text('Fiók & Profil'), findsWidgets);
      await tester.tap(find.text('Üzenetek').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Feljegyzések ('), findsOneWidget);

      await tester.tap(find.descendant(of: bar, matching: find.text('Mulasztás')));
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
      // Demo mode shows it outside the summer break too.
      expect(find.widgetWithText(TextButton, 'Pala Wrapped'), findsNothing);
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Pala Wrapped'));
      await tester.pumpAndSettle();
      expect(find.text('Itt a te tanéved összegzése'), findsOneWidget);
    });
  });
}
