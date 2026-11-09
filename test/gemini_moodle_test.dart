import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/api/moodle_client.dart';
import 'package:pala/utils/gemini_summarizer.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiSummarizer', () {
    test('is disabled without a key and makes no request', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final summarizer = GeminiSummarizer(null, client: client);
      expect(summarizer.isEnabled, isFalse);
      expect(await summarizer.summarize(['Új jegy']), isNull);
      expect(called, isFalse);
    });

    test('makes no request for an empty alert list', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      expect(await GeminiSummarizer('k', client: client).summarize([]), isNull);
      expect(called, isFalse);
    });

    test('sends the key in a header, not in the URL, and parses the text', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Holnap dolgozat van. Tanulj matekot.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final result = await GeminiSummarizer('secret-key', client: client).summarize(['Holnap dolgozat: Matek']);
      expect(result, 'Holnap dolgozat van. Tanulj matekot.');
      expect(captured.url.host, 'generativelanguage.googleapis.com');
      expect(captured.url.toString(), isNot(contains('secret-key')));
      expect(captured.headers['x-goog-api-key'], 'secret-key');
      expect(captured.url.path, contains(GeminiSummarizer.defaultModel));
    });

    test('returns null on HTTP errors and malformed bodies', () async {
      final error = MockClient((_) async => http.Response('nope', 429));
      expect(await GeminiSummarizer('k', client: error).summarize(['x']), isNull);
      expect(GeminiSummarizer.parseResponse('not json'), isNull);
      expect(GeminiSummarizer.parseResponse('{"candidates":[]}'), isNull);
    });

    test('rejects a model name that could alter the URL path', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final summarizer = GeminiSummarizer('k', model: '../evil', client: client);
      expect(await summarizer.summarize(['x']), isNull);
      expect(called, isFalse);
    });

    test('truncates very long input', () {
      final request = GeminiSummarizer.buildRequest(List.filled(2000, 'sor'));
      final text = request['contents'][0]['parts'][0]['text'] as String;
      expect(text.length, lessThanOrEqualTo(4000));
    });
  });

  group('MoodleClient', () {
    test('only accepts https base urls', () {
      expect(MoodleClient.isValidBaseUrl('https://moodle.iskolam.hu'), isTrue);
      expect(MoodleClient.isValidBaseUrl('http://moodle.iskolam.hu'), isFalse);
      expect(MoodleClient.isValidBaseUrl('moodle.iskolam.hu'), isFalse);
      expect(MoodleClient.isValidBaseUrl(null), isFalse);
    });

    test('login posts the password in the body and keeps the token', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('{"token":"abc123"}', 200);
      });
      final moodle = MoodleClient('https://moodle.iskolam.hu', client: client);
      await moodle.login('diak', 'titok');
      expect(moodle.token, 'abc123');
      expect(captured.url.toString(), 'https://moodle.iskolam.hu/login/token.php');
      expect(captured.url.query, isEmpty);
      expect(captured.body, contains('service=moodle_mobile_app'));
    });

    test('login throws with the server reason on a bad login', () async {
      final client = MockClient((_) async => http.Response('{"error":"Invalid login","errorcode":"invalidlogin"}', 200));
      final moodle = MoodleClient('https://moodle.iskolam.hu', client: client);
      expect(() => moodle.login('diak', 'rossz'), throwsA(isA<MoodleLoginException>()));
      expect(moodle.token, isNull);
    });

    test('an invalid token raises MoodleLoginException so the caller logs in again', () async {
      final client = MockClient((_) async =>
          http.Response('{"exception":"moodle_exception","errorcode":"invalidtoken"}', 200));
      final moodle = MoodleClient('https://moodle.iskolam.hu', token: 'old', client: client);
      expect(() => moodle.getNotifications(), throwsA(isA<MoodleLoginException>()));
    });

    test('parseNotifications keeps only unread items', () {
      final result = MoodleClient.parseNotifications({
        'notifications': [
          {'id': 1, 'subject': 'Új jegy', 'read': false, 'timecreated': 1700000000},
          {'id': 2, 'subject': 'Régi', 'read': true},
          {'subject': 'Azonosító nélkül'},
        ]
      });
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.id, 1);
      expect(result.first.subject, 'Új jegy');
    });

    test('parseEvents sorts by due time and reads the course name', () {
      final result = MoodleClient.parseEvents({
        'events': [
          {'id': 2, 'name': 'B', 'timesort': 1700100000, 'course': {'fullname': 'Matek'}},
          {'id': 1, 'name': 'A', 'timesort': 1700000000},
        ]
      });
      expect(result!.map((e) => e.name).toList(), ['A', 'B']);
      expect(result.last.course, 'Matek');
      expect(MoodleClient.parseEvents('x'), isNull);
    });
  });
}
