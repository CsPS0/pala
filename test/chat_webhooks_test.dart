import 'dart:io';

import 'package:pala/utils/chat_webhooks.dart';
import 'package:test/test.dart';

const slackUrl = 'https://hooks.slack.com/services/T000/B000/abcdef';
const discordUrl = 'https://discord.com/api/webhooks/123456/abc-DEF_ghi';

void main() {
  late Directory dir;
  late ChatWebhookStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pala_webhooks');
    store = ChatWebhookStore(dir.path, environment: const {});
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('nothing is saved at first', () {
    for (final service in ChatService.values) {
      expect(store.hasSaved(service), isFalse);
      expect(store.sink(service).isEnabled, isFalse);
    }
  });

  test('a valid webhook is saved trimmed, into the file the notifier reads', () {
    expect(store.save(ChatService.slack, '  $slackUrl\n'), isTrue);
    expect(store.save(ChatService.discord, discordUrl), isTrue);

    expect(File('${dir.path}/slack_webhook').readAsStringSync(), slackUrl);
    expect(File('${dir.path}/discord_webhook').readAsStringSync(), discordUrl);
    for (final service in ChatService.values) {
      expect(store.hasSaved(service), isTrue);
      expect(store.sink(service).isEnabled, isTrue);
    }
  });

  test('an address of another host is refused and leaves no file', () {
    expect(store.save(ChatService.slack, discordUrl), isFalse);
    expect(store.save(ChatService.discord, slackUrl), isFalse);
    expect(store.save(ChatService.discord, 'https://example.com/api/webhooks/1/abc'), isFalse);
    expect(store.save(ChatService.slack, ''), isFalse);

    expect(dir.listSync(), isEmpty);
  });

  test('a refused address keeps the webhook that was saved before', () {
    store.save(ChatService.discord, discordUrl);

    expect(store.save(ChatService.discord, 'http://discord.com/api/webhooks/1/abc'), isFalse);
    expect(File('${dir.path}/discord_webhook').readAsStringSync(), discordUrl);
  });

  test('a saved file with a tampered address does not count as saved', () {
    File('${dir.path}/slack_webhook').writeAsStringSync('https://evil.example/services/x');

    expect(store.hasSaved(ChatService.slack), isFalse);
  });

  test('remove deletes the file and is safe when there is none', () {
    store.save(ChatService.slack, slackUrl);

    store.remove(ChatService.slack);
    store.remove(ChatService.slack);

    expect(store.hasSaved(ChatService.slack), isFalse);
    expect(File('${dir.path}/slack_webhook').existsSync(), isFalse);
  });

  test('the environment variable is reported, blank values are not', () {
    final withEnv = ChatWebhookStore(dir.path, environment: const {
      'PALA_SLACK_WEBHOOK': slackUrl,
      'PALA_DISCORD_WEBHOOK': '   ',
    });

    expect(withEnv.isSetByEnvironment(ChatService.slack), isTrue);
    expect(withEnv.isSetByEnvironment(ChatService.discord), isFalse);
    expect(store.isSetByEnvironment(ChatService.slack), isFalse);
  });
}
