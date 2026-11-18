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

  test('isSetupCompleted defaults to false and becomes true when marked', () {
    expect(AppState.instance.isSetupCompleted, isFalse);
    AppState.instance.markSetupCompleted();
    expect(AppState.instance.isSetupCompleted, isTrue);
  });

  test('daemon state never touches the encrypted auth file', () {
    // Before the fix the daemon read auth.json as plain JSON, got {} back,
    // and wrote its counts over the encrypted Kréta login.
    const encryptedLogin = 'v3:aXY=:Y2lwaGVydGV4dA==';
    AppState.instance.authFile.writeAsStringSync(encryptedLogin);

    final state = AppState.instance.getDaemonState();
    state['gradesCount'] = 3;
    AppState.instance.saveDaemonState(state);

    expect(AppState.instance.authFile.readAsStringSync(), encryptedLogin);
    expect(AppState.instance.getDaemonState()['gradesCount'], 3);
    expect(AppState.instance.daemonStateFile.path, endsWith('daemon_state.json'));

    AppState.instance.authFile.deleteSync();
  });

  test('clearAllData deletes the daemon state', () {
    AppState.instance.saveDaemonState({'gradesCount': 1});

    AppState.instance.clearAllData();

    expect(AppState.instance.daemonStateFile.existsSync(), isFalse);
  });

  test('hasAuth checks if authFile exists', () {
    expect(AppState.instance.hasAuth(), isFalse);
    AppState.instance.authFile.writeAsStringSync('{}');
    expect(AppState.instance.hasAuth(), isTrue);
    AppState.instance.authFile.deleteSync();
    expect(AppState.instance.hasAuth(), isFalse);
  });
}
