import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  // Legacy (v1/v2) key derivation: hostname + OS + username are all locally
  // observable, not secret, so this only obfuscated the auth file rather
  // than actually protecting it. Kept ONLY to decrypt files written by
  // older Pala versions during migration to the v3 random keyfile below.
  static List<int> _getLegacyKeyBytes(String salt) {
    final hostname = Platform.localHostname;
    final os = Platform.operatingSystem;
    final user = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown_user';
    final seed = "$hostname-$os-$user-$salt";
    return sha256.convert(utf8.encode(seed)).bytes;
  }

  static Encrypter _getLegacyEncrypter(String salt) {
    final bytes = _getLegacyKeyBytes(salt);
    final key = Key(Uint8List.fromList(bytes));
    return Encrypter(AES(key, mode: AESMode.gcm));
  }

  static IV _getLegacyIV(String salt) {
    final bytes = _getLegacyKeyBytes(salt);
    return IV(Uint8List.fromList(bytes.sublist(0, 16)));
  }

  /// Set by the Flutter app on Android/iOS to a writable app-specific
  /// directory before any encrypt/decrypt call, since those platforms have
  /// no HOME/USERPROFILE env var and the process working directory is
  /// read-only. See AppState.configDirOverride for the same pattern.
  static String? configDirOverride;

  static String get _configDir {
    if (configDirOverride != null) return configDirOverride!;
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/.config/pala';
  }

  /// Loads (or creates on first use) a per-installation random 256-bit key,
  /// stored in its own file separate from the encrypted auth data.
  /// Unlike the old hostname/username-derived key, this value is not
  /// reconstructable from anything an attacker can observe externally —
  /// recovering it requires actually reading the keyfile off disk.
  static Key _getMachineKey() {
    final dir = Directory(_configDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final keyFile = File('$_configDir/.pala_keyfile');

    if (keyFile.existsSync()) {
      final existing = _parseKey(keyFile.readAsStringSync());
      if (existing != null) return existing;
      // Corrupt/unexpected keyfile: fall through and regenerate below.
    }

    final key = _randomKey();
    keyFile.writeAsStringSync(base64.encode(key.bytes));
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        Process.runSync('chmod', ['600', keyFile.path]);
      } catch (_) {}
    }
    return key;
  }

  /// Set by [useKeyStore]; while non-null the keyfile is not used.
  static Key? _storeKey;

  /// Keyfile key that data written before [useKeyStore] may still need, see
  /// its `keepKeyFile` parameter.
  static Key? _fallbackKey;

  static Key? _parseKey(String? raw) {
    if (raw == null) return null;
    try {
      final bytes = base64.decode(raw.trim());
      return bytes.length == 32 ? Key(Uint8List.fromList(bytes)) : null;
    } on FormatException {
      return null;
    }
  }

  /// Moves this process to a key kept in an OS secure store (the Flutter app
  /// passes flutter_secure_storage here) instead of the plaintext keyfile.
  /// Must run before any [encrypt]/[decrypt].
  ///
  /// An existing keyfile is migrated: copied into the store, read back,
  /// checked with a test decrypt, and only then deleted, so whatever it
  /// encrypted keeps working. With [keepKeyFile] (the keyfile is shared with
  /// the CLI, which still needs it) it is left alone instead: the store gets
  /// its own key, and [decrypt] falls back to the keyfile for older data.
  ///
  /// Throws when the store fails; this process then keeps using the keyfile.
  static Future<void> useKeyStore({
    required Future<String?> Function() read,
    required Future<void> Function(String value) write,
    bool keepKeyFile = false,
  }) async {
    _storeKey = null;
    _fallbackKey = null;
    final keyFile = File('$_configDir/.pala_keyfile');
    final fileKey = _parseKey(keyFile.existsSync() ? keyFile.readAsStringSync() : null);
    var stored = _parseKey(await read());

    // A keyfile left on disk is what the current data was encrypted with
    // (an older version, or a launch where the store failed), so it wins.
    final migrate = fileKey != null && !keepKeyFile;
    if (migrate || stored == null) {
      final key = migrate ? fileKey : _randomKey();
      await write(base64.encode(key.bytes));
      stored = _parseKey(await read());
      if (stored == null) throw StateError('A kulcs nem került be a biztonságos tárolóba.');
      // AES-GCM authentication makes this throw if the stored key differs.
      final iv = IV.fromSecureRandom(16);
      Encrypter(AES(stored, mode: AESMode.gcm))
          .decrypt(Encrypter(AES(key, mode: AESMode.gcm)).encrypt('pala', iv: iv), iv: iv);
    }

    _storeKey = stored;
    if (keepKeyFile) _fallbackKey = fileKey;
    if (migrate) {
      try {
        keyFile.deleteSync();
      } on FileSystemException catch (_) {
        // The other process (app or background worker) deleted it first.
      }
    }
  }

  static Key _randomKey() {
    final random = Random.secure();
    return Key(Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256))));
  }

  static Encrypter _getEncrypter() {
    return Encrypter(AES(_storeKey ?? _getMachineKey(), mode: AESMode.gcm));
  }

  /// Encrypts plaintext using AES-GCM with a per-installation random key and
  /// a cryptographically secure random IV. Output format:
  /// "v3:<iv_base64>:<ciphertext_base64>"
  static String encrypt(String plainText) {
    try {
      final encrypter = _getEncrypter();
      final iv = IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return 'v3:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Hiba a titkosítás során: $e');
      return '';
    }
  }

  /// Decrypts ciphertext. Supports the current v3 random-key format, and
  /// falls back to older v2/v1 formats (derived from machine/user info) so
  /// existing profiles keep working; callers should re-save after a
  /// successful legacy decrypt so the file is migrated to v3.
  static String decrypt(String encryptedText) {
    if (encryptedText.startsWith('v3:')) {
      final parts = encryptedText.split(':');
      if (parts.length == 3) {
        final iv = IV.fromBase64(parts[1]);
        final encrypted = Encrypted.fromBase64(parts[2]);
        try {
          return _getEncrypter().decrypt(encrypted, iv: iv);
        } catch (_) {
          if (_fallbackKey == null) rethrow;
          return Encrypter(AES(_fallbackKey!, mode: AESMode.gcm)).decrypt(encrypted, iv: iv);
        }
      }
    }

    // Legacy v2 format: "v2:<iv_base64>:<ciphertext_base64>", derived key.
    if (encryptedText.startsWith('v2:')) {
      final parts = encryptedText.split(':');
      if (parts.length == 3) {
        final iv = IV.fromBase64(parts[1]);
        final encrypted = Encrypted.fromBase64(parts[2]);
        final encrypter = _getLegacyEncrypter('pala-tui-secret-salt-v1');
        return encrypter.decrypt(encrypted, iv: iv);
      }
    }

    // Fallback: Legacy v1 format (try Pala salt first, then legacy Folio salt)
    final encrypted = Encrypted.fromBase64(encryptedText);
    try {
      final encrypter = _getLegacyEncrypter('pala-tui-secret-salt-v1');
      final iv = _getLegacyIV('pala-tui-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    try {
      final encrypter = _getLegacyEncrypter('folio-cli-secret-salt-v1');
      final iv = _getLegacyIV('folio-cli-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    throw FormatException('Decryption failed');
  }
}
