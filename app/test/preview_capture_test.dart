// Captures the website's hero preview screenshots from the real app in demo mode.
// Skipped by default. Run from app/:
//   flutter test test/preview_capture_test.dart --dart-define=CAPTURE_PREVIEWS=true
// Output: <repo>/build/previews/*.png, then scripts/previews/to_webp.py (see docs/DEV.md).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala/utils/pala_clock.dart';
import 'package:pala_app/core/theme/m3_theme.dart';
import 'package:pala_app/main.dart';
import 'package:pala_app/state/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _capture = bool.fromEnvironment('CAPTURE_PREVIEWS');

/// Every page at phone size into build/walkthrough/ (for looking the app over):
///   flutter test test/preview_capture_test.dart --dart-define=CAPTURE_PREVIEWS=true --dart-define=WALKTHROUGH=true
const _walkthrough = bool.fromEnvironment('WALKTHROUGH');

/// Test fonts are a placeholder box font; load the real Roboto and Material icons from the SDK.
Future<void> _loadSdkFonts() async {
  // The test runs inside the Flutter SDK (flutter_tester); walk up to the folder that holds bin/cache.
  Directory? dir = File(Platform.resolvedExecutable).parent;
  while (dir != null && !Directory('${dir.path}/bin/cache/artifacts/material_fonts').existsSync()) {
    dir = dir.parent.path == dir.path ? null : dir.parent;
  }
  if (dir == null) throw StateError('Material fonts not found above ${Platform.resolvedExecutable}');
  final fontsDir = Directory('${dir.path}/bin/cache/artifacts/material_fonts');
  ByteData read(String name) => ByteData.sublistView(File('${fontsDir.path}/$name').readAsBytesSync());

  // Styles without a family resolve to 'FlutterTest' in tests (the system font on devices), so Roboto backs both.
  for (final family in ['Roboto', 'FlutterTest']) {
    final loader = FontLoader(family);
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-light.ttf']) {
      loader.addFont(Future.value(read(f)));
    }
    await loader.load();
  }
  await (FontLoader('MaterialIcons')..addFont(Future.value(read('materialicons-regular.otf')))).load();
}

/// Theme sub-styles that set no font family skip the theme's Roboto default and hit the
/// test engine's box font. On devices they use the system font, so give them Roboto here.
ThemeData _withPlatformFont(ThemeData t) {
  TextStyle? f(TextStyle? s) => s?.copyWith(fontFamily: 'Roboto');
  WidgetStateProperty<TextStyle?>? w(WidgetStateProperty<TextStyle?>? p) =>
      p == null ? null : WidgetStateProperty.resolveWith((states) => f(p.resolve(states)));
  ButtonStyle? b(ButtonStyle? style) => style?.copyWith(textStyle: w(style.textStyle));
  return t.copyWith(
    appBarTheme: t.appBarTheme.copyWith(titleTextStyle: f(t.appBarTheme.titleTextStyle)),
    navigationRailTheme: t.navigationRailTheme.copyWith(
      selectedLabelTextStyle: f(t.navigationRailTheme.selectedLabelTextStyle),
      unselectedLabelTextStyle: f(t.navigationRailTheme.unselectedLabelTextStyle),
    ),
    navigationBarTheme: t.navigationBarTheme.copyWith(labelTextStyle: w(t.navigationBarTheme.labelTextStyle)),
    filledButtonTheme: FilledButtonThemeData(style: b(t.filledButtonTheme.style)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: b(t.elevatedButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: b(t.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(style: b(t.textButtonTheme.style)),
  );
}

class _Shot {
  final String name;
  final Size logicalSize;
  final double pixelRatio;
  final List<String> taps;
  const _Shot(this.name, this.logicalSize, this.pixelRatio, [this.taps = const []]);
}

const _shots = [
  _Shot('desktop-vezerlopult', Size(1280, 800), 2),
  _Shot('desktop-jegyek', Size(1280, 800), 2, ['Osztályzatok']),
  _Shot('phone-fooldal', Size(390, 844), 3),
  _Shot('phone-orarend', Size(390, 844), 3, ['Órarend']),
];

const _walkthroughShots = [
  _Shot('phone-1-fooldal', Size(360, 740), 2),
  _Shot('phone-2-orarend', Size(360, 740), 2, ['Órarend']),
  _Shot('phone-3-jegyek', Size(360, 740), 2, ['Jegyek']),
  _Shot('phone-4-mulasztas', Size(360, 740), 2, ['Mulasztás']),
  _Shot('phone-5-tobb', Size(360, 740), 2, ['Több']),
  _Shot('phone-6-feladatok', Size(360, 740), 2, ['Több', 'Feladatok & Dolgozatok']),
  _Shot('phone-7-uzenetek', Size(360, 740), 2, ['Több', 'Üzenetek']),
  _Shot('phone-8-profil', Size(360, 740), 2, ['Több', 'Fiók & Profil']),
  _Shot('desktop-1-vezerlopult', Size(1440, 900), 1),
  _Shot('desktop-2-orarend', Size(1440, 900), 1, ['Órarend']),
  _Shot('desktop-3-osztalyzatok', Size(1440, 900), 1, ['Osztályzatok']),
  _Shot('desktop-4-uzenetek', Size(1440, 900), 1, ['Üzenetek']),
  _Shot('desktop-5-mulasztasok', Size(1440, 900), 1, ['Mulasztások']),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!_capture) return;
    // Screenshots show a school Monday morning, during the second lesson,
    // whenever they are taken (the demo has no lessons on Wednesdays).
    PalaClock.fix(DateTime(2026, 11, 9, 9, 10));
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('hu_HU', null);
    await _loadSdkFonts();
  });

  for (final dark in _walkthrough ? [true] : [true, false]) {
    for (final shot in _walkthrough ? _walkthroughShots : _shots) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('capture ${shot.name}-$theme', skip: !_capture, (tester) async {
        final appModel = AppModel();
        await tester.runAsync(() async {
          await appModel.loginDemo();
          await appModel.setDarkMode(dark);
        });

        tester.view.physicalSize = shot.logicalSize * shot.pixelRatio;
        tester.view.devicePixelRatio = shot.pixelRatio;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final boundaryKey = GlobalKey();
        // Same MaterialApp as PalaMobileApp in main.dart, with the font fix above.
        await tester.pumpWidget(RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            title: 'Pala',
            debugShowCheckedModeBanner: false,
            theme: _withPlatformFont(dark ? M3Theme.darkTheme : M3Theme.lightTheme),
            home: PalaShell(appModel: appModel),
          ),
        ));
        // The dashboard ticker never settles, so pump fixed frames instead of pumpAndSettle.
        await tester.pump(const Duration(milliseconds: 500));

        for (final label in shot.taps) {
          await tester.tap(find.text(label).last);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 500));
        }

        await tester.runAsync(() async {
          final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: shot.pixelRatio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final out = File('../build/${_walkthrough ? 'walkthrough' : 'previews'}/${shot.name}-$theme.png');
          await out.parent.create(recursive: true);
          await out.writeAsBytes(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
