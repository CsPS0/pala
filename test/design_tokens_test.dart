import 'dart:io';

import 'package:test/test.dart';

/// The design tokens live in three copies: Kréta Web's page
/// (lib/web/pala_web_html.dart), the extension (extension/shared/tokens.css)
/// and the Flutter app (app/lib/core/theme/pala_tokens.dart). This keeps them
/// equal, so the surfaces cannot drift apart again.

/// The `--name: value;` pairs of the first CSS block that starts with [selector].
Map<String, String> cssBlock(String source, String selector) {
  final start = source.indexOf(selector);
  if (start == -1) throw StateError('CSS block $selector not found');
  final open = source.indexOf('{', start);
  final close = source.indexOf('}', open);
  final body = source.substring(open + 1, close);
  return {
    for (final m in RegExp(r'--([a-z0-9-]+):\s*([^;]+);').allMatches(body)) m.group(1)!: m.group(2)!.trim().toLowerCase(),
  };
}

/// `static const name = Color(0xFFrrggbb);` in the Dart token file, as `#rrggbb`.
Map<String, String> dartColors(String source) {
  return {
    for (final m in RegExp(r'static const (\w+) = Color\(0xFF([0-9A-Fa-f]{6})\);').allMatches(source))
      m.group(1)!: '#${m.group(2)!.toLowerCase()}',
  };
}

void main() {
  final web = File('lib/web/pala_web_html.dart').readAsStringSync();
  final ext = File('extension/shared/tokens.css').readAsStringSync();
  final app = File('app/lib/core/theme/pala_tokens.dart').readAsStringSync();

  // Kréta Web nests its light block in a media query; the extension switches on data-theme.
  final webDark = cssBlock(web, ':root {');
  final webLight = cssBlock(web.substring(web.indexOf('@media (prefers-color-scheme: light)')), ':root {');
  final extDark = cssBlock(ext, ':root {');
  final extLight = cssBlock(ext, ':root[data-theme="light"] {');

  for (final (theme, a, b) in [('dark', webDark, extDark), ('light', webLight, extLight)]) {
    test('Kréta Web and the extension share every $theme token', () {
      // --font is the extension's own (Kréta Web sets the font on *).
      final keys = {...a.keys, ...b.keys}..remove('font');
      for (final k in keys) {
        expect(b[k], a[k], reason: '--$k ($theme): Kréta Web has ${a[k]}, the extension has ${b[k]}');
      }
    });
  }

  test('the app uses the same surface and text colours', () {
    final colors = dartColors(app);
    const pairs = {
      'Bg': 'bg',
      'Sidebar': 'sidebar',
      'Card': 'card',
      'Border': 'border',
      'Text': 'text',
      'TextMuted': 'text-muted',
    };
    for (final (prefix, css) in [('dark', webDark), ('light', webLight)]) {
      for (final MapEntry(key: dartName, value: cssName) in pairs.entries) {
        expect(colors['$prefix$dartName'], css[cssName], reason: '$prefix$dartName vs --$cssName');
      }
    }
  });

  test('every grade colour has matching rgb channels', () {
    for (final block in [webDark, webLight, extDark, extLight]) {
      for (final n in ['1', '2', '3', '4', '5']) {
        final hex = block['grade-$n']!;
        final channels = [1, 3, 5].map((i) => int.parse(hex.substring(i, i + 2), radix: 16)).join(', ');
        expect(block['grade-$n-rgb'], channels, reason: '--grade-$n-rgb does not match $hex');
      }
    }
  });
}
