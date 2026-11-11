import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/api/moodle_client.dart';
import 'package:pala/api/moodle_tracking.dart';
import 'package:test/test.dart';

void main() {
  const badLogin = '{"error":"Invalid login, please try again","errorcode":"invalidlogin"}';

  // A client whose login endpoint answers [body] with [status], counting the
  // requests so a test can prove that a skipped login makes none.
  ({MoodleClient client, List<http.Request> requests}) moodle(String body, {int status = 200}) {
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response(body, status);
    });
    return (client: MoodleClient('https://moodle.example.test', client: client), requests: requests);
  }

  group('MoodleLoginGuard', () {
    test('skips only when the flag is set and the credentials are the same', () {
      final auth = <String, dynamic>{};
      expect(MoodleLoginGuard.shouldSkip(auth, 'diak', 'rossz'), isFalse);
      MoodleLoginGuard.recordFailure(auth, 'diak', 'rossz');
      expect(auth[MoodleLoginGuard.flagKey], isTrue);
      expect(MoodleLoginGuard.shouldSkip(auth, 'diak', 'rossz'), isTrue);
      expect(MoodleLoginGuard.shouldSkip(auth, 'diak', 'masik'), isFalse, reason: 'password changed');
      expect(MoodleLoginGuard.shouldSkip(auth, 'masik', 'rossz'), isFalse, reason: 'username changed');
    });

    test('stores no password, only a salted hash', () {
      final auth = <String, dynamic>{};
      MoodleLoginGuard.recordFailure(auth, 'diak', 'titok-jelszo');
      final stored = jsonEncode(auth);
      expect(stored, isNot(contains('titok-jelszo')));
      expect(stored, isNot(contains('diak')));
      // The same credentials get a different hash with another salt.
      final other = <String, dynamic>{};
      MoodleLoginGuard.recordFailure(other, 'diak', 'titok-jelszo');
      expect(other[MoodleLoginGuard.hashKey], isNot(auth[MoodleLoginGuard.hashKey]));
      expect(MoodleLoginGuard.shouldSkip(other, 'diak', 'titok-jelszo'), isTrue);
    });

    test('a flag without a usable hash never blocks a login', () {
      for (final hash in [null, 5, '', 'nincs-kettospont', ':abc']) {
        final auth = <String, dynamic>{MoodleLoginGuard.flagKey: true, MoodleLoginGuard.hashKey: hash};
        expect(MoodleLoginGuard.shouldSkip(auth, 'diak', 'rossz'), isFalse, reason: '$hash');
      }
    });

    test('clear removes both keys', () {
      final auth = <String, dynamic>{'moodleToken': 't'};
      MoodleLoginGuard.recordFailure(auth, 'diak', 'rossz');
      MoodleLoginGuard.clear(auth);
      expect(auth, {'moodleToken': 't'});
    });
  });

  group('moodleLoginWithGuard', () {
    test('a wrong password reports once, then the next runs make no request', () async {
      final auth = <String, dynamic>{};
      final m = moodle(badLogin);

      // Run 1: the server refuses, the failure is recorded and rethrown.
      await expectLater(
        moodleLoginWithGuard(m.client, auth, 'diak', 'rossz'),
        throwsA(isA<MoodleLoginException>().having((e) => e.isBadCredentials, 'isBadCredentials', isTrue)),
      );
      expect(m.requests.length, 1);
      expect(auth[MoodleLoginGuard.flagKey], isTrue);
      expect(auth.containsKey('moodleToken'), isFalse);

      // Runs 2 and 3 with the same credentials: skipped, no request, no throw.
      expect(await moodleLoginWithGuard(m.client, auth, 'diak', 'rossz'), isFalse);
      expect(await moodleLoginWithGuard(m.client, auth, 'diak', 'rossz'), isFalse);
      expect(m.requests.length, 1);
    });

    test('a changed password is tried again, and success clears the flag and keeps the token', () async {
      final auth = <String, dynamic>{};
      MoodleLoginGuard.recordFailure(auth, 'diak', 'rossz');
      final m = moodle('{"token":"fake-token"}');

      expect(await moodleLoginWithGuard(m.client, auth, 'diak', 'jo'), isTrue);
      expect(m.requests.length, 1);
      expect(auth['moodleToken'], 'fake-token');
      expect(auth.containsKey(MoodleLoginGuard.flagKey), isFalse);
      expect(auth.containsKey(MoodleLoginGuard.hashKey), isFalse);
    });

    test('the password is posted in the body and never kept in the auth data', () async {
      final auth = <String, dynamic>{};
      final m = moodle('{"token":"fake-token"}');
      await moodleLoginWithGuard(m.client, auth, 'diak', 'titok-jelszo');
      expect(m.requests.single.body, contains('password=titok-jelszo'));
      expect(m.requests.single.url.toString(), isNot(contains('titok-jelszo')));
      expect(jsonEncode(auth), isNot(contains('titok-jelszo')));
    });

    test('an HTTP error or a network failure does not lock the login', () async {
      final auth = <String, dynamic>{};
      final server = moodle('oops', status: 503);
      await expectLater(moodleLoginWithGuard(server.client, auth, 'diak', 'jo'), throwsA(isA<MoodleLoginException>()));
      expect(auth.containsKey(MoodleLoginGuard.flagKey), isFalse);

      final offline = MoodleClient('https://moodle.example.test', client: MockClient((_) async => throw http.ClientException('offline')));
      await expectLater(moodleLoginWithGuard(offline, auth, 'diak', 'jo'), throwsA(isA<http.ClientException>()));
      expect(auth.containsKey(MoodleLoginGuard.flagKey), isFalse);
    });

    test('another server error is reported but does not lock the login', () async {
      final auth = <String, dynamic>{};
      final m = moodle('{"error":"Web services are not enabled","errorcode":"enablewsdescription"}');
      await expectLater(
        moodleLoginWithGuard(m.client, auth, 'diak', 'jo'),
        throwsA(isA<MoodleLoginException>().having((e) => e.isBadCredentials, 'isBadCredentials', isFalse)),
      );
      expect(auth.containsKey(MoodleLoginGuard.flagKey), isFalse);
    });
  });

  group('MoodleSeenIds', () {
    String id(int n) => '$n';

    test('a failed fetch records nothing, so the list is still unrecorded', () {
      final r = MoodleSeenIds.update<int>(null, id, null);
      expect(r.fresh, isEmpty);
      expect(r.next, isNull);
    });

    test('the first successful fetch records the items and announces none', () {
      final r = MoodleSeenIds.update<int>([1, 2, 3], id, null);
      expect(r.fresh, isEmpty);
      expect(r.next, ['1', '2', '3']);
    });

    test('an empty first list still counts as recorded', () {
      final r = MoodleSeenIds.update<int>([], id, null);
      expect(r.fresh, isEmpty);
      expect(r.next, <String>[]);
    });

    test('a failed first fetch followed by a good one does not announce the backlog', () {
      var stored = null as Object?;
      final failed = MoodleSeenIds.update<int>(null, id, stored);
      if (failed.next != null) stored = failed.next;
      expect(stored, isNull, reason: 'nothing saved after the failed run');

      final second = MoodleSeenIds.update<int>([1, 2, 3], id, stored);
      expect(second.fresh, isEmpty, reason: 'first successful fetch is silent');
      stored = second.next;

      final third = MoodleSeenIds.update<int>([1, 2, 3, 4], id, stored);
      expect(third.fresh, [4]);
    });

    test('later runs announce only new ids and drop ids that went away', () {
      final r = MoodleSeenIds.update<int>([2, 3, 4], id, ['1', '2', '3']);
      expect(r.fresh, [4]);
      expect(r.next, ['2', '3', '4']);
    });

    test('a failed fetch after a recorded list leaves the saved ids alone', () {
      final r = MoodleSeenIds.update<int>(null, id, ['1', '2']);
      expect(r.fresh, isEmpty);
      expect(r.next, isNull);
    });

    test('numbers in the saved list are read as ids', () {
      final r = MoodleSeenIds.update<int>([1, 2], id, [1, 2]);
      expect(r.fresh, isEmpty);
    });

    test('duplicate ids in one fetch are announced once', () {
      final r = MoodleSeenIds.update<int>([5, 5, 6], id, ['1']);
      expect(r.fresh, [5, 6]);
      expect(r.next, ['5', '6']);
    });

    test('notifications and events are tracked separately', () {
      // Notifications were recorded, events were not (their fetch failed).
      final events = MoodleSeenIds.update<int>([10, 11], id, null);
      expect(events.fresh, isEmpty, reason: 'events are still on their first run');
      final notifications = MoodleSeenIds.update<int>([1, 2], id, ['1']);
      expect(notifications.fresh, [2]);
    });
  });
}
