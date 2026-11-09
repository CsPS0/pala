import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/utils/slack_notifier.dart';
import 'package:test/test.dart';

void main() {
  const hook = 'https://hooks.slack.com/services/T000/B000/XXXX';

  group('isValidWebhook', () {
    test('accepts a Slack incoming webhook', () {
      expect(SlackNotifier.isValidWebhook(hook), isTrue);
    });

    test('rejects other hosts, plain http and empty values', () {
      expect(SlackNotifier.isValidWebhook(null), isFalse);
      expect(SlackNotifier.isValidWebhook(''), isFalse);
      expect(SlackNotifier.isValidWebhook('http://hooks.slack.com/services/x'), isFalse);
      expect(SlackNotifier.isValidWebhook('https://evil.example/services/x'), isFalse);
      expect(SlackNotifier.isValidWebhook('https://hooks.slack.com.evil.example/services/x'), isFalse);
    });
  });

  test('payload escapes Slack control characters from Kréta text', () {
    final payload = SlackNotifier.buildPayload('Pala', 'Matek <!channel> & <https://x|y>');
    expect(payload['text'], '*Pala*\nMatek &lt;!channel&gt; &amp; &lt;https://x|y&gt;');
  });

  test('send posts JSON to the webhook', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('ok', 200);
    });
    final ok = await SlackNotifier(hook, client: client).send('Pala (Kréta)', 'Holnap dolgozat: Történelem');
    expect(ok, isTrue);
    expect(captured.url.toString(), hook);
    expect(jsonDecode(captured.body)['text'], contains('Történelem'));
  });

  test('send returns false and does not throw on Slack errors', () async {
    final client = MockClient((_) async => http.Response('invalid_token', 403));
    expect(await SlackNotifier(hook, client: client).send('a', 'b'), isFalse);

    final failing = MockClient((_) async => throw const SocketException('offline'));
    expect(await SlackNotifier(hook, client: failing).send('a', 'b'), isFalse);
  });

  test('disabled notifier sends nothing', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('ok', 200);
    });
    expect(await SlackNotifier(null, client: client).send('a', 'b'), isFalse);
    expect(called, isFalse);
  });

  test('fromConfig reads the owner-only file', () {
    final dir = Directory.systemTemp.createTempSync('pala_slack');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/slack_webhook').writeAsStringSync('$hook\n');
    // The environment variable wins when set, so only check the file path
    // when the test runner does not have one.
    if ((Platform.environment['PALA_SLACK_WEBHOOK'] ?? '').isEmpty) {
      expect(SlackNotifier.fromConfig(dir.path).webhookUrl, hook);
    }
  });
}
