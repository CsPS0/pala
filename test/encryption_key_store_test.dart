import 'dart:io';

import 'package:pala/utils/encryption.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late File keyFile;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pala_keystore');
    EncryptionUtil.configDirOverride = dir.path;
    keyFile = File('${dir.path}/.pala_keyfile');
    // An unavailable store puts the process back on the keyfile, as a fresh
    // older-version install would be.
    await expectLater(
      EncryptionUtil.useKeyStore(read: () async => throw StateError('no store'), write: (_) async {}),
      throwsStateError,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('migrates an existing keyfile into the store and deletes it', () async {
    // Written by an older version, with only the keyfile.
    final session = EncryptionUtil.encrypt('session');
    expect(keyFile.existsSync(), isTrue);

    final store = <String, String>{};
    await EncryptionUtil.useKeyStore(
      read: () async => store['key'],
      write: (value) async => store['key'] = value,
    );

    expect(keyFile.existsSync(), isFalse);
    expect(EncryptionUtil.decrypt(session), 'session');
    // New data uses the stored key and never recreates the keyfile.
    expect(EncryptionUtil.decrypt(EncryptionUtil.encrypt('new')), 'new');
    expect(keyFile.existsSync(), isFalse);

    // A second process (or the next launch) gets the same key from the store.
    await EncryptionUtil.useKeyStore(
      read: () async => store['key'],
      write: (value) async => store['key'] = value,
    );
    expect(EncryptionUtil.decrypt(session), 'session');
  });

  test('keeps the keyfile when the store does not hold the key', () async {
    final session = EncryptionUtil.encrypt('session');

    // A store whose writes are silently lost.
    await expectLater(
      EncryptionUtil.useKeyStore(read: () async => null, write: (_) async {}),
      throwsStateError,
    );

    expect(keyFile.existsSync(), isTrue);
    expect(EncryptionUtil.decrypt(session), 'session');
  });

  test('keepKeyFile leaves the shared keyfile but still reads older data', () async {
    final session = EncryptionUtil.encrypt('session');
    final keyBefore = keyFile.readAsStringSync();

    final store = <String, String>{};
    await EncryptionUtil.useKeyStore(
      read: () async => store['key'],
      write: (value) async => store['key'] = value,
      keepKeyFile: true,
    );

    expect(keyFile.readAsStringSync(), keyBefore);
    expect(store['key'], isNot(keyBefore));
    expect(EncryptionUtil.decrypt(session), 'session');
    expect(EncryptionUtil.decrypt(EncryptionUtil.encrypt('new')), 'new');
  });
}
