import 'dart:convert';
import 'dart:io';
import 'package:pala/api/client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';

/// Persists the single active login (access/refresh token) to an encrypted
/// file, the same way the CLI's auth.json does but for one profile — the
/// app only ever has one active account. Needed so the Android background
/// notification worker can restore a session without the app being open.
class SessionStore {
  static String get _path => '${AppState.instance.configDir}/mobile_session.dat';

  static Future<void> save(KretaClient client) async {
    if (client.accessToken == null) return;
    final data = {
      'instituteCode': client.instituteCode,
      'accessToken': client.accessToken,
      'refreshToken': client.refreshToken,
    };
    final encrypted = EncryptionUtil.encrypt(jsonEncode(data));
    // encrypt() returns '' on failure; never replace a good session with that.
    if (encrypted.isEmpty) return;
    final file = File(_path);
    await file.parent.create(recursive: true);
    // Write-then-rename, so Android killing the background worker mid-write
    // can't leave a half-written (undecryptable) session behind.
    final tmp = File('$_path.tmp');
    await tmp.writeAsString(encrypted, flush: true);
    await tmp.rename(_path);
  }

  /// Wires [client] to this store: rotated tokens are saved, and before a
  /// refresh the client first picks up tokens the other process (app or
  /// background worker) may have rotated in the meantime.
  static void attach(KretaClient client) {
    client.onTokenRefreshed = () => save(client);
    client.reloadTokens = () async {
      final saved = await load();
      if (saved == null || saved['refreshToken'] == client.refreshToken) return false;
      client.accessToken = saved['accessToken'];
      client.refreshToken = saved['refreshToken'];
      return true;
    };
  }

  static Future<Map<String, String>?> load() async {
    final file = File(_path);
    if (!await file.exists()) return null;
    try {
      final decrypted = EncryptionUtil.decrypt(await file.readAsString());
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      final instituteCode = data['instituteCode'] as String?;
      final accessToken = data['accessToken'] as String?;
      if (instituteCode == null || accessToken == null) return null;
      return {
        'instituteCode': instituteCode,
        'accessToken': accessToken,
        'refreshToken': (data['refreshToken'] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final file = File(_path);
    if (await file.exists()) await file.delete();
  }
}
