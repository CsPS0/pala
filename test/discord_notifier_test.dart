import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/utils/discord_notifier.dart';
import 'package:test/test.dart';

import 'support/log_capture.dart';

void main() {
  // Obviously fake: the id and the token are made up for these tests.
  const hook = 'https://discord.com/api/webhooks/123456789012345678/FAKE-test_token';
  const token = 'FAKE-test_token';

  group('isValidWebhook', () {
    test('accepts every Discord host', () {
      for (final host in ['discord.com', 'discordapp.com', 'ptb.discord.com', 'canary.discord.com']) {
        expect(DiscordNotifier.isValidWebhook('https://$host/api/webhooks/123/FAKE-test_token'), isTrue, reason: host);
      }
    });

    test('rejects other hosts, plain http, odd paths and empty values', () {
      const bad = [
        '',
        'http://discord.com/api/webhooks/123/FAKE-test_token',
        'https://evil.example/api/webhooks/123/FAKE-test_token',
        'https://discord.com.evil.example/api/webhooks/123/FAKE-test_token',
        'https://evil.example/discord.com/api/webhooks/123/FAKE-test_token',
        'https://user@discord.com/api/webhooks/123/FAKE-test_token',
        'https://discord.com:8443/api/webhooks/123/FAKE-test_token',
        'https://discord.com/api/webhooks/123/FAKE-test_token?wait=true',
        'https://discord.com/api/webhooks/123/FAKE-test_token#x',
        'https://discord.com/api/webhooks/abc/FAKE-test_token',
        'https://discord.com/api/webhooks/123',
        'https://discord.com/api/webhooks/123/',
        'https://discord.com/api/webhooks/123/FAKE/test',
        'https://discord.com/api/v10/webhooks/123/FAKE-test_token',
        'https://hooks.slack.com/services/T000/B000/XXXX',
      ];
      expect(DiscordNotifier.isValidWebhook(null), isFalse);
      for (final url in bad) {
        expect(DiscordNotifier.isValidWebhook(url), isFalse, reason: url);
      }
    });
  });

  group('payload', () {
    test('blocks every kind of mention', () {
      final payload = DiscordNotifier.buildPayload('Matek @everyone <@123>');
      expect(payload['content'], 'Matek @everyone <@123>');
      expect(payload['allowed_mentions'], {'parse': <String>[]});
    });

    test('the posted body carries the mention block and bold title', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response('', 204);
      });
      final ok = await DiscordNotifier(hook, client: client).send('Pala', '@here Holnap dolgozat');
      expect(ok, isTrue);
      expect(captured.url.toString(), hook);
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(captured.body) as Map;
      expect(body['content'], '**Pala**\n@here Holnap dolgozat');
      expect(body['allowed_mentions'], {'parse': []});
    });

    test('bold uses Discord markup', () {
      expect(DiscordNotifier(null).bold('x'), '**x**');
    });
  });

  group('splitMessage', () {
    test('keeps a short message in one piece', () {
      expect(DiscordNotifier.splitMessage('a\nb'), ['a\nb']);
    });

    test('splits at line boundaries and no piece is over the limit', () {
      final lines = List.generate(100, (i) => 'sor ${i.toString().padLeft(3, '0')} ${'x' * 40}');
      final chunks = DiscordNotifier.splitMessage(lines.join('\n'), limit: 500);
      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(500));
        // Every line is whole: none starts or ends in the middle of a line.
        for (final line in chunk.split('\n')) {
          expect(lines, contains(line));
        }
      }
      expect(chunks.join('\n'), lines.join('\n'));
    });

    test('cuts a single over-long line at the limit', () {
      final chunks = DiscordNotifier.splitMessage('a\n${'b' * 25}\nc', limit: 10);
      expect(chunks.every((c) => c.length <= 10), isTrue);
      expect(chunks.join(), contains('b' * 25));
      expect(chunks.first, 'a');
    });

    test('does not split a surrogate pair', () {
      // The emoji is two UTF-16 units; a cut after the first would corrupt it.
      final text = '${'a' * 9}\u{1F600}${'b' * 5}';
      final chunks = DiscordNotifier.splitMessage(text, limit: 10);
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(10));
        for (var i = 0; i < chunk.length; i++) {
          final unit = chunk.codeUnitAt(i);
          if (unit >= 0xD800 && unit <= 0xDBFF) {
            expect(i + 1, lessThan(chunk.length), reason: 'high surrogate at the end');
          }
        }
      }
      expect(chunks.join(), text);
    });

    test('send posts each piece of a long message and all are within 2000', () async {
      final posted = <String>[];
      final client = MockClient((req) async {
        posted.add((jsonDecode(req.body) as Map)['content'] as String);
        return http.Response('', 204);
      });
      final message = List.generate(150, (i) => '• sor $i ${'y' * 30}').join('\n');
      expect(await DiscordNotifier(hook, client: client).send('Pala', message), isTrue);
      expect(posted.length, greaterThan(1));
      expect(posted.every((c) => c.length <= DiscordNotifier.maxContentLength), isTrue);
      expect(posted.first, startsWith('**Pala**\n'));
    });
  });

  group('send', () {
    test('disabled notifier sends nothing', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('', 204);
      });
      expect(await DiscordNotifier(null, client: client).send('a', 'b'), isFalse);
      expect(await DiscordNotifier('https://evil.example/x', client: client).send('a', 'b'), isFalse);
      expect(called, isFalse);
    });

    test('only 204 is success', () async {
      final client = MockClient((_) async => http.Response('{"id":"1"}', 200));
      expect(await DiscordNotifier(hook, client: client).send('a', 'b'), isFalse);
      final unauthorized = MockClient((_) async => http.Response('{"message":"Unknown Webhook"}', 404));
      expect(await DiscordNotifier(hook, client: unauthorized).send('a', 'b'), isFalse);
    });

    test('waits retry_after once after a 429, then retries and succeeds', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('{"retry_after": 1.5, "global": false}', 429) : http.Response('', 204);
      });
      final waits = <Duration>[];
      final notifier = DiscordNotifier(hook, client: client, delay: (d) async => waits.add(d));
      expect(await notifier.send('a', 'b'), isTrue);
      expect(calls, 2);
      expect(waits, [const Duration(milliseconds: 1500)]);
    });

    test('gives up after a second 429 and never waits twice', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{"retry_after": 1}', 429);
      });
      final waits = <Duration>[];
      final notifier = DiscordNotifier(hook, client: client, delay: (d) async => waits.add(d));
      expect(await notifier.send('a', 'b'), isFalse);
      expect(calls, 2);
      expect(waits.length, 1);
    });

    test('falls back to the Retry-After header and caps a huge wait', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('not json', 429, headers: {'retry-after': '3600'}) : http.Response('', 204);
      });
      final waits = <Duration>[];
      final notifier = DiscordNotifier(hook, client: client, delay: (d) async => waits.add(d));
      expect(await notifier.send('a', 'b'), isTrue);
      expect(waits, [const Duration(seconds: 30)]);
    });

    test('never throws on network errors', () async {
      final failing = MockClient((_) async => throw const SocketException('offline'));
      expect(await DiscordNotifier(hook, client: failing).send('a', 'b'), isFalse);
    });
  });

  group('logging', () {
    test('a failed send never logs the webhook URL or token', () async {
      // The http package puts the request URI into ClientException messages.
      final failing = MockClient((req) async => throw http.ClientException('connection closed', req.url));
      final log = await captureDebugLog(() async {
        expect(await DiscordNotifier(hook, client: failing).send('a', 'b'), isFalse);
      });
      expect(log, contains('Discord webhook failed: ClientException'));
      expect(log, isNot(contains(hook)));
      expect(log, isNot(contains(token)));
      expect(log, isNot(contains('123456789012345678')));
    });

    test('an error status and a rate limit log only the status', () async {
      final rejected = MockClient((_) async => http.Response('{"message":"$token"}', 401));
      final limited = MockClient((_) async => http.Response('{"retry_after": 0}', 429));
      final log = await captureDebugLog(() async {
        await DiscordNotifier(hook, client: rejected).send('a', 'b');
        await DiscordNotifier(hook, client: limited, delay: (_) async {}).send('a', 'b');
      });
      expect(log, contains('Discord webhook HTTP 401'));
      expect(log, contains('Discord webhook HTTP 429'));
      expect(log, isNot(contains(token)));
      expect(log, isNot(contains('discord.com')));
    });

    test('an exception with the URL in its message logs only its type', () async {
      final slow = MockClient((_) async => throw LeakyException(hook));
      final log = await captureDebugLog(() async {
        expect(await DiscordNotifier(hook, client: slow).send('a', 'b'), isFalse);
      });
      expect(log, contains('Discord webhook failed: LeakyException'));
      expect(log, isNot(contains(token)));
    });
  });

  test('fromConfig reads the owner-only file', () {
    final dir = Directory.systemTemp.createTempSync('pala_discord');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/discord_webhook').writeAsStringSync('$hook\n');
    // The environment variable wins when set, so only check the file path
    // when the test runner does not have one.
    if ((Platform.environment['PALA_DISCORD_WEBHOOK'] ?? '').isEmpty) {
      final notifier = DiscordNotifier.fromConfig(dir.path);
      expect(notifier.webhookUrl, hook);
      expect(notifier.isEnabled, isTrue);
    }
  });
}

/// An exception whose message holds the URL, to prove the message is not logged.
class LeakyException implements Exception {
  final String message;
  LeakyException(this.message);
  @override
  String toString() => 'LeakyException: $message';
}
