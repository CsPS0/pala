import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  static List<int> _getKeyBytes(String salt) {
    final hostname = Platform.localHostname;
    final os = Platform.operatingSystem;
    final user = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown_user';
    final seed = "$hostname-$os-$user-$salt";
    return sha256.convert(utf8.encode(seed)).bytes;
  }

  static Encrypter _getEncrypter(String salt) {
    final bytes = _getKeyBytes(salt);
    final key = Key(Uint8List.fromList(bytes));
    return Encrypter(AES(key, mode: AESMode.gcm));
  }

  static IV _getLegacyIV(String salt) {
    final bytes = _getKeyBytes(salt);
    return IV(Uint8List.fromList(bytes.sublist(0, 16)));
  }

  /// Encrypts plaintext using AES-GCM with a cryptographically secure random IV.
  /// Output format: "v2:<iv_base64>:<ciphertext_base64>"
  static String encrypt(String plainText) {
    try {
      final encrypter = _getEncrypter('pala-tui-secret-salt-v1');
      final iv = IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return 'v2:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Hiba a titkosítás során: $e');
      return '';
    }
  }

  /// Decrypts ciphertext, supporting both v2 randomized IV and v1 legacy static IV formats.
  static String decrypt(String encryptedText) {
    // Check for v2 format: "v2:<iv_base64>:<ciphertext_base64>"
    if (encryptedText.startsWith('v2:')) {
      final parts = encryptedText.split(':');
      if (parts.length == 3) {
        final iv = IV.fromBase64(parts[1]);
        final encrypted = Encrypted.fromBase64(parts[2]);
        final encrypter = _getEncrypter('pala-tui-secret-salt-v1');
        return encrypter.decrypt(encrypted, iv: iv);
      }
    }

    // Fallback: Legacy v1 format (try Pala salt first, then legacy Folio salt)
    final encrypted = Encrypted.fromBase64(encryptedText);
    try {
      final encrypter = _getEncrypter('pala-tui-secret-salt-v1');
      final iv = _getLegacyIV('pala-tui-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    try {
      final encrypter = _getEncrypter('folio-cli-secret-salt-v1');
      final iv = _getLegacyIV('folio-cli-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    throw FormatException('Decryption failed');
  }
}
