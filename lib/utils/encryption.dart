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
      final raw = keyFile.readAsStringSync().trim();
      final bytes = base64.decode(raw);
      if (bytes.length == 32) {
        return Key(Uint8List.fromList(bytes));
      }
      // Corrupt/unexpected keyfile: fall through and regenerate below.
    }

    final random = Random.secure();
    final keyBytes = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
    keyFile.writeAsStringSync(base64.encode(keyBytes));
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        Process.runSync('chmod', ['600', keyFile.path]);
      } catch (_) {}
    }
    return Key(keyBytes);
  }

  static Encrypter _getEncrypter() {
    return Encrypter(AES(_getMachineKey(), mode: AESMode.gcm));
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
        return _getEncrypter().decrypt(encrypted, iv: iv);
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
