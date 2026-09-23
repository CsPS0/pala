import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pala/api/client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';
import 'package:pala_app/state/session_store.dart';

KretaClient client(String access, String refresh) =>
    KretaClient(instituteCode: 'klik000000')
      ..accessToken = access
      ..refreshToken = refresh;

void main() {
  late Directory dir;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('pala_session');
    AppState.configDirOverride = dir.path;
    EncryptionUtil.configDirOverride = dir.path;
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  test('save and load round-trip, leaving no temp file behind', () async {
    await SessionStore.save(client('a1', 'r1'));

    final saved = await SessionStore.load();
    expect(saved?['accessToken'], 'a1');
    expect(saved?['refreshToken'], 'r1');
    expect(File('${dir.path}/mobile_session.dat.tmp').existsSync(), isFalse);
  });

  test('a client adopts tokens another process rotated', () async {
    final app = client('a1', 'r1');
    SessionStore.attach(app);

    // The background worker refreshed (Kréta refresh tokens are single-use).
    await SessionStore.save(client('a2', 'r2'));

    expect(await app.reloadTokens!(), isTrue);
    expect(app.accessToken, 'a2');
    expect(app.refreshToken, 'r2');
    // Nothing newer on disk now, so a real refresh is needed.
    expect(await app.reloadTokens!(), isFalse);
  });
}
