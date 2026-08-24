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

  static IV _getIV(String salt) {
    final bytes = _getKeyBytes(salt);
    return IV(Uint8List.fromList(bytes.sublist(0, 16)));
  }

  static String encrypt(String plainText) {
    try {
      final encrypter = _getEncrypter('pala-tui-secret-salt-v1');
      final iv = _getIV('pala-tui-secret-salt-v1');
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('Hiba a titkosítás során: $e');
      return '';
    }
  }

  static String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    
    // Try current Pala salt first
    try {
      final encrypter = _getEncrypter('pala-tui-secret-salt-v1');
      final iv = _getIV('pala-tui-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    // Fallback to legacy Folio salt for seamless migration
    try {
      final encrypter = _getEncrypter('folio-cli-secret-salt-v1');
      final iv = _getIV('folio-cli-secret-salt-v1');
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {}

    throw FormatException('Decryption failed');
  }
}
