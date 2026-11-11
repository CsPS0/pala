import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:pala/api/moodle_client.dart';

/// Remembers a refused Moodle login, so a scheduled run does not retry (and
/// report) the same wrong password every time.
///
/// The auth data holds `moodleLoginFailed: true` and a salted SHA-256 of the
/// username and password that were refused. The login is skipped while the
/// credentials still produce that hash, and tried again as soon as either one
/// changes. Only an `invalidlogin` answer counts: a timeout or an HTTP error
/// is not a refusal and never locks anything.
class MoodleLoginGuard {
  static const flagKey = 'moodleLoginFailed';
  static const hashKey = 'moodleFailedHash';

  static String _digest(String salt, String user, String password) =>
      sha256.convert(utf8.encode('$salt\n$user\n$password')).toString();

  static String _newSalt() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// True when the last login with exactly these credentials was refused.
  static bool shouldSkip(Map<String, dynamic> auth, String user, String password) {
    if (auth[flagKey] != true) return false;
    final stored = auth[hashKey];
    if (stored is! String) return false;
    final split = stored.indexOf(':');
    if (split <= 0) return false;
    final salt = stored.substring(0, split);
    return stored.substring(split + 1) == _digest(salt, user, password);
  }

  static void recordFailure(Map<String, dynamic> auth, String user, String password, {String? salt}) {
    final s = salt ?? _newSalt();
    auth[flagKey] = true;
    auth[hashKey] = '$s:${_digest(s, user, password)}';
  }

  static void clear(Map<String, dynamic> auth) {
    auth.remove(flagKey);
    auth.remove(hashKey);
  }
}

/// Logs in with [user] and [password] unless the guard says the same
/// credentials were refused before. On success the token goes into [auth] and
/// the failure flag is cleared. A refused login is recorded in [auth] and then
/// rethrown, so the caller reports it once. [auth] is changed in place; the
/// caller saves it, also when this throws.
///
/// Returns false when the login was skipped, true after a successful login.
Future<bool> moodleLoginWithGuard(
  MoodleClient moodle,
  Map<String, dynamic> auth,
  String user,
  String password,
) async {
  if (MoodleLoginGuard.shouldSkip(auth, user, password)) return false;
  try {
    await moodle.login(user, password);
  } on MoodleLoginException catch (e) {
    if (e.isBadCredentials) MoodleLoginGuard.recordFailure(auth, user, password);
    rethrow;
  }
  MoodleLoginGuard.clear(auth);
  auth['moodleToken'] = moodle.token;
  return true;
}

/// Tells which Moodle items are new since the last run.
///
/// A list counts as seen only after the server returned it. A failed fetch
/// (null) changes nothing, so the next run still treats the list as not yet
/// recorded and does not announce every existing item. The first successful
/// fetch records the items silently.
class MoodleSeenIds {
  /// [stored] is the saved id list (null when nothing was recorded yet).
  /// Returns the items to announce and the id list to save, which is null when
  /// there is nothing new to save.
  static ({List<T> fresh, List<String>? next}) update<T>(
    List<T>? items,
    String Function(T) idOf,
    Object? stored,
  ) {
    if (items == null) return (fresh: <T>[], next: null);
    final ids = <String>[];
    final seenNow = <String>{};
    final unique = <T>[];
    for (final item in items) {
      final id = idOf(item);
      if (seenNow.add(id)) {
        ids.add(id);
        unique.add(item);
      }
    }
    if (stored is! List) return (fresh: <T>[], next: ids);
    final known = stored.map((e) => e.toString()).toSet();
    return (fresh: unique.where((i) => !known.contains(idOf(i))).toList(), next: ids);
  }
}
