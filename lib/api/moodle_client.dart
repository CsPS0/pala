import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pala/utils/logger.dart';

/// One unread Moodle notification (grade posted, forum post, assignment
/// change, message).
class MoodleNotification {
  final int id;
  final String subject;
  final DateTime? time;

  const MoodleNotification({required this.id, required this.subject, this.time});
}

/// One upcoming Moodle deadline or calendar event.
class MoodleEvent {
  final int id;
  final String name;
  final String? course;
  final DateTime? due;

  const MoodleEvent({required this.id, required this.name, this.course, this.due});
}

class MoodleLoginException implements Exception {
  final String reason;
  const MoodleLoginException(this.reason);
  @override
  String toString() => 'Moodle bejelentkezés sikertelen: $reason';
}

/// Read-only client for the Moodle mobile web service.
///
/// Login uses `login/token.php` with the `moodle_mobile_app` service. The
/// password is only sent to that endpoint, once, and the returned token is
/// kept instead. The school site must keep the mobile service enabled and use
/// plain username and password login (no SSO), otherwise [login] throws.
class MoodleClient {
  final Uri baseUri;
  final http.Client _client;
  String? token;
  int? userId;

  MoodleClient(String baseUrl, {this.token, http.Client? client})
      : baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  /// The base url must be https and have a host, so a typo cannot send the
  /// password over plain http or to a path-less value.
  static bool isValidBaseUrl(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  Uri _endpoint(String path, [Map<String, String>? query]) {
    final basePath = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
    return baseUri.replace(path: '$basePath$path', queryParameters: query);
  }

  Future<void> login(String username, String password) async {
    // POST body, so the password never lands in a URL or in server logs.
    final response = await _client
        .post(
          _endpoint('login/token.php'),
          body: {'username': username, 'password': password, 'service': 'moodle_mobile_app'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw MoodleLoginException('HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is Map && data['token'] is String) {
      token = data['token'] as String;
      return;
    }
    final reason = data is Map ? (data['error'] ?? data['errorcode'] ?? 'ismeretlen hiba') : 'ismeretlen válasz';
    throw MoodleLoginException(reason.toString());
  }

  Future<dynamic> _call(String function, Map<String, String> params) async {
    final response = await _client
        .post(
          _endpoint('webservice/rest/server.php'),
          body: {
            'wstoken': token ?? '',
            'wsfunction': function,
            'moodlewsrestformat': 'json',
            ...params,
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      PalaLogger.debug('Moodle $function: HTTP ${response.statusCode}');
      return null;
    }
    final data = jsonDecode(response.body);
    if (data is Map && data.containsKey('exception')) {
      PalaLogger.debug('Moodle $function: ${data['errorcode']}');
      // An invalid token means the caller has to log in again.
      if (data['errorcode'] == 'invalidtoken') throw const MoodleLoginException('lejárt token');
      return null;
    }
    return data;
  }

  Future<int?> getUserId() async {
    if (userId != null) return userId;
    final data = await _call('core_webservice_get_site_info', {});
    if (data is Map && data['userid'] is int) {
      userId = data['userid'] as int;
    }
    return userId;
  }

  /// Unread notifications of the logged-in user, newest first.
  Future<List<MoodleNotification>?> getNotifications({int limit = 30}) async {
    final uid = await getUserId();
    if (uid == null) return null;
    final data = await _call('message_popup_get_popup_notifications', {
      'useridto': '$uid',
      'limit': '$limit',
      'offset': '0',
    });
    return parseNotifications(data);
  }

  static List<MoodleNotification>? parseNotifications(dynamic data) {
    if (data is! Map || data['notifications'] is! List) return null;
    final result = <MoodleNotification>[];
    for (final n in data['notifications'] as List) {
      if (n is! Map || n['id'] is! int) continue;
      final read = n['read'] == true;
      if (read) continue;
      final created = n['timecreated'];
      result.add(MoodleNotification(
        id: n['id'] as int,
        subject: (n['subject'] ?? n['shortenedsubject'] ?? '').toString(),
        time: created is int ? DateTime.fromMillisecondsSinceEpoch(created * 1000) : null,
      ));
    }
    return result;
  }

  /// Deadlines and action events from now to [days] days ahead.
  Future<List<MoodleEvent>?> getUpcomingEvents({int days = 14, DateTime? now}) async {
    final from = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final to = from + days * 86400;
    final data = await _call('core_calendar_get_action_events_by_timesort', {
      'timesortfrom': '$from',
      'timesortto': '$to',
      'limitnum': '50',
    });
    return parseEvents(data);
  }

  static List<MoodleEvent>? parseEvents(dynamic data) {
    if (data is! Map || data['events'] is! List) return null;
    final result = <MoodleEvent>[];
    for (final e in data['events'] as List) {
      if (e is! Map || e['id'] is! int) continue;
      final sort = e['timesort'];
      final course = e['course'];
      result.add(MoodleEvent(
        id: e['id'] as int,
        name: (e['name'] ?? '').toString(),
        course: course is Map ? course['fullname']?.toString() : null,
        due: sort is int ? DateTime.fromMillisecondsSinceEpoch(sort * 1000) : null,
      ));
    }
    result.sort((a, b) => (a.due ?? DateTime(9999)).compareTo(b.due ?? DateTime(9999)));
    return result;
  }
}
