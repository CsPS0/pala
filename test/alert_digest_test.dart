import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/utils/alert_digest.dart';
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/discord_notifier.dart';
import 'package:pala/utils/gemini_summarizer.dart';
import 'package:pala/utils/slack_notifier.dart';
import 'package:test/test.dart';

class _FakeSink implements AlertSink {
  final String name;
  final bool throws;
  final sent = <({String title, String message})>[];

  _FakeSink(this.name, {this.throws = false});

  @override
  bool get isEnabled => true;

  @override
  String bold(String text) => '<$name>$text</$name>';

  @override
  Future<bool> send(String title, String message) async {
    if (throws) throw StateError('boom');
    sent.add((title: title, message: message));
    return true;
  }
}

void main() {
  const geminiReply = '{"candidates":[{"content":{"parts":[{"text":"Holnap dolgozat van."}]}}]}';

  // A summarizer whose requests are recorded, so a test can read the prompt.
  ({GeminiSummarizer summarizer, List<String> prompts}) gemini({String? key = 'fake-key', int status = 200}) {
    final prompts = <String>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map;
      prompts.add(body['contents'][0]['parts'][0]['text'] as String);
      return http.Response(geminiReply, status);
    });
    return (summarizer: GeminiSummarizer(key, client: client), prompts: prompts);
  }

  group('sendAlertDigest', () {
    test('sends one message per sink with its own bold summary label', () async {
      final slack = _FakeSink('s');
      final discord = _FakeSink('d');
      final g = gemini();
      await sendAlertDigest(
        [(text: 'Új jegy: Matek 5', gemini: 'Új jegy: Matek 5'), (text: 'Holnap dolgozat: Töri', gemini: 'Holnap dolgozat: Töri')],
        [slack, discord],
        g.summarizer,
      );
      expect(slack.sent.length, 1);
      expect(discord.sent.length, 1);
      expect(slack.sent.single.title, 'Pala');
      expect(slack.sent.single.message, startsWith('• Új jegy: Matek 5\n• Holnap dolgozat: Töri\n\n<s>Összefoglaló:</s> Holnap dolgozat van.'));
      expect(discord.sent.single.message, contains('<d>Összefoglaló:</d> Holnap dolgozat van.'));
      expect(g.prompts.length, 1, reason: 'one Gemini call for all sinks');
    });

    test('the Gemini prompt holds the gemini form, never the chat text', () async {
      final sink = _FakeSink('s');
      final g = gemini();
      await sendAlertDigest(
        [
          (text: 'Holnap helyettesítés: Matek — Kovács Anna', gemini: 'Holnap helyettesítés: Matek'),
          (text: 'Moodle: Szabó Béla írt a fórumba', gemini: 'Új Moodle értesítés'),
        ],
        [sink],
        g.summarizer,
      );
      expect(g.prompts.single, 'Holnap helyettesítés: Matek\nÚj Moodle értesítés');
      expect(g.prompts.single, isNot(contains('Kovács')));
      expect(g.prompts.single, isNot(contains('Szabó')));
      // The chat message still has the full text.
      expect(sink.sent.single.message, contains('Kovács Anna'));
      expect(sink.sent.single.message, contains('Szabó Béla'));
    });

    test('makes no Gemini call and posts nothing without alerts', () async {
      final sink = _FakeSink('s');
      final g = gemini();
      await sendAlertDigest([], [sink], g.summarizer);
      expect(sink.sent, isEmpty);
      expect(g.prompts, isEmpty);
    });

    test('makes no Gemini call when no sink is configured', () async {
      final g = gemini();
      await sendAlertDigest([(text: 'a', gemini: 'a')], [], g.summarizer);
      expect(g.prompts, isEmpty);
    });

    test('still posts the alerts when Gemini fails or is off', () async {
      final failing = _FakeSink('s');
      await sendAlertDigest([(text: 'Új jegy', gemini: 'Új jegy')], [failing], gemini(status: 500).summarizer);
      expect(failing.sent.single.message, '• Új jegy');

      final off = _FakeSink('s');
      await sendAlertDigest([(text: 'Új jegy', gemini: 'Új jegy')], [off], gemini(key: null).summarizer);
      expect(off.sent.single.message, '• Új jegy');
    });

    test('a failing sink does not stop the next one', () async {
      final broken = _FakeSink('b', throws: true);
      final ok = _FakeSink('o');
      await sendAlertDigest([(text: 'x', gemini: 'x')], [broken, ok], gemini(key: null).summarizer);
      expect(ok.sent.single.message, '• x');
    });
  });

  test('sendToAllSinks reaches every sink', () async {
    final a = _FakeSink('a');
    final b = _FakeSink('b');
    await sendToAllSinks([a, b], 'Pala (hiba)', 'bejelentkezés');
    expect(a.sent.single.title, 'Pala (hiba)');
    expect(b.sent.single.message, 'bejelentkezés');
  });

  group('real sinks side by side', () {
    test('Slack and Discord both get the digest, each in its own markup', () async {
      const slackHook = 'https://hooks.slack.com/services/T000/B000/XXXX';
      const discordHook = 'https://discord.com/api/webhooks/123456789012345678/FAKE-test_token';
      final posts = <String, String>{};
      final client = MockClient((req) async {
        posts[req.url.host] = req.body;
        return req.url.host == 'discord.com' ? http.Response('', 204) : http.Response('ok', 200);
      });
      await sendAlertDigest(
        [(text: 'Új jegy: Matek 5', gemini: 'Új jegy: Matek 5')],
        [SlackNotifier(slackHook, client: client), DiscordNotifier(discordHook, client: client)],
        gemini().summarizer,
      );
      expect((jsonDecode(posts['hooks.slack.com']!) as Map)['text'], startsWith('*Pala*\n'));
      expect((jsonDecode(posts['hooks.slack.com']!) as Map)['text'], contains('*Összefoglaló:*'));
      final discord = jsonDecode(posts['discord.com']!) as Map;
      expect(discord['content'], startsWith('**Pala**\n'));
      expect(discord['content'], contains('**Összefoglaló:**'));
      expect(discord['allowed_mentions'], {'parse': []});
    });
  });
}
