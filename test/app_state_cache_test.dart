import 'dart:io';

import 'package:pala/app/state/app_state.dart';
import 'package:test/test.dart';

void main() {
  late Directory config;
  late Directory cache;

  setUpAll(() {
    config = Directory.systemTemp.createTempSync('pala_config');
    cache = Directory.systemTemp.createTempSync('pala_cache');
    AppState.configDirOverride = config.path;
    AppState.cacheDirOverride = cache.path;
  });

  tearDownAll(() {
    config.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  test('legacy cache.json moves out of the config dir', () {
    File('${config.path}/cache.json').writeAsStringSync('{"grades":[]}');

    final file = AppState.instance.cacheFile;

    expect(file.path, startsWith(cache.path));
    expect(file.readAsStringSync(), '{"grades":[]}');
    expect(File('${config.path}/cache.json').existsSync(), isFalse);
  });

  test('clearAllData deletes the cache file', () {
    AppState.instance.cacheFile.writeAsStringSync('{}');

    AppState.instance.clearAllData();

    expect(File('${cache.path}/cache.json').existsSync(), isFalse);
  });
}
