import 'dart:convert';
import 'dart:io';

import 'package:pala/app/state/app_state.dart';
import 'package:test/test.dart';

void main() {
  late Directory config;
  late Directory cache;

  setUp(() {
    config = Directory.systemTemp.createTempSync('pala_alias_config');
    cache = Directory.systemTemp.createTempSync('pala_alias_cache');
    AppState.configDirOverride = config.path;
    AppState.cacheDirOverride = cache.path;
  });

  tearDown(() {
    config.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  test('an alias set in the settings is applied', () {
    AppState.instance.setAlias('Matematika', 'Matek');

    expect(AppState.instance.getAliases()['Matematika'], 'Matek');
    expect(AppState.instance.applyAlias('Matematika'), 'Matek');
  });

  test('a removed alias is no longer applied', () {
    AppState.instance.setAlias('Fizika', 'Fiz');
    AppState.instance.removeAlias('Fizika');

    expect(AppState.instance.applyAlias('Fizika'), 'Fizika');
  });

  test('aliases saved in state.json by older versions move to aliases.json', () {
    File('${config.path}/state.json').writeAsStringSync(jsonEncode({
      'themeMode': 'dark',
      'aliases': {'Történelem': 'Töri'},
    }));

    expect(AppState.instance.getAliases()['Történelem'], 'Töri');
    final state = jsonDecode(File('${config.path}/state.json').readAsStringSync()) as Map;
    expect(state.containsKey('aliases'), isFalse);
    expect(state['themeMode'], 'dark');
  });
}
