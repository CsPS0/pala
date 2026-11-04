// Every page in demo mode at a phone and a desktop size. Any exception
// (including a RenderFlex overflow) fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala_app/core/adaptive/adaptive_scaffold.dart';
import 'package:pala_app/core/theme/m3_theme.dart';
import 'package:pala_app/features/grades/widgets/grade_summary_card.dart';
import 'package:pala_app/state/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _railPages = [
  'Vezérlőpult',
  'Órarend',
  'Osztályzatok',
  'Feladatok & Dolgozatok',
  'Üzenetek',
  'Mulasztások',
  'Fiók & Profil',
];

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('hu_HU', null);
  });

  Future<AppModel> pumpDemo(WidgetTester tester, Size size, {bool dark = true}) async {
    final appModel = AppModel();
    await tester.runAsync(() async {
      await appModel.loginDemo();
      await appModel.setDarkMode(dark);
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: dark ? M3Theme.darkTheme : M3Theme.lightTheme,
      home: AdaptiveScaffold(appModel: appModel),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    return appModel;
  }

  Future<void> settle(WidgetTester tester) async {
    // The dashboard clock ticks forever; pump fixed frames instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final dark in [true, false]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('desktop 1440x900 ($theme): every rail page renders without errors', (tester) async {
      await pumpDemo(tester, const Size(1440, 900), dark: dark);
      final rail = find.byType(NavigationRail);
      for (final page in _railPages) {
        await tester.tap(find.descendant(of: rail, matching: find.text(page)));
        await settle(tester);
      }
      // Back on Osztályzatok, open one subject card: the class-average chart lives inside.
      await tester.tap(find.descendant(of: rail, matching: find.text('Osztályzatok')));
      await settle(tester);
      final list = find.descendant(
        of: find.byKey(const PageStorageKey<String>('grades_subject_list')),
        matching: find.byType(Scrollable),
      );
      // Subject cards sit below the comparison card and are built lazily.
      for (var i = 0; i < 10 && find.byType(GradeSummaryCard).hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(list.first, const Offset(0, -300));
        await settle(tester);
      }
      await tester.tap(find.byType(GradeSummaryCard).first);
      await settle(tester);
    });

    testWidgets('phone 360x740 ($theme): every page renders without errors', (tester) async {
      await pumpDemo(tester, const Size(360, 740), dark: dark);
      final bar = find.byType(NavigationBar);
      for (final label in ['Órarend', 'Jegyek', 'Mulasztás', 'Főoldal']) {
        await tester.tap(find.descendant(of: bar, matching: find.text(label)));
        await settle(tester);
      }
      for (final page in ['Feladatok & Dolgozatok', 'Üzenetek', 'Fiók & Profil']) {
        await tester.tap(find.descendant(of: bar, matching: find.text('Több')));
        await settle(tester);
        await tester.tap(find.text(page).last);
        await settle(tester);
      }
      // A message's detail sheet.
      await tester.tap(find.descendant(of: bar, matching: find.text('Több')));
      await settle(tester);
      await tester.tap(find.text('Üzenetek').last);
      await settle(tester);
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await settle(tester);
    });
  }
}
