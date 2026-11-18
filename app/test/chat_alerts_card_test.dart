import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/chat_webhooks.dart';
import 'package:pala_app/notifications/chat_alerts_card.dart';

const discordUrl = 'https://discord.com/api/webhooks/123456/abc-DEF_ghi';

class _FakeSink implements AlertSink {
  final bool result;
  final sent = <String>[];

  _FakeSink(this.result);

  @override
  bool get isEnabled => true;

  @override
  String bold(String text) => text;

  @override
  Future<bool> send(String title, String message) async {
    sent.add(message);
    return result;
  }
}

void main() {
  late Directory dir;
  late ChatWebhookStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pala_card');
    store = ChatWebhookStore(dir.path, environment: const {});
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, {ChatWebhookStore? withStore, _FakeSink? sink}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatAlertsCard(store: withStore ?? store, sinkFor: sink == null ? null : (_) => sink),
          ),
        ),
      ),
    );
  }

  testWidgets('starts with both services off and no test or remove button', (tester) async {
    await pump(tester);

    expect(find.text('Nincs beállítva'), findsNWidgets(2));
    expect(find.text('Teszt üzenet'), findsNothing);
    expect(find.text('Törlés'), findsNothing);
  });

  testWidgets('a wrong address shows an error and saves nothing', (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const ValueKey('webhook-discord')), 'https://example.com/hook');
    await tester.tap(find.byKey(const ValueKey('save-discord')));
    await tester.pump();

    expect(find.textContaining('Ez nem Discord webhook cím'), findsOneWidget);
    expect(store.hasSaved(ChatService.discord), isFalse);
  });

  testWidgets('a valid address is saved, cleared from the field and never shown again', (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const ValueKey('webhook-discord')), discordUrl);
    await tester.tap(find.byKey(const ValueKey('save-discord')));
    await tester.pump();

    expect(store.hasSaved(ChatService.discord), isTrue);
    expect(find.text('Beállítva'), findsOneWidget);
    expect(find.textContaining('abc-DEF_ghi'), findsNothing);
    expect(find.byKey(const ValueKey('test-discord')), findsOneWidget);
  });

  testWidgets('the test button sends one message and reports the result', (tester) async {
    store.save(ChatService.discord, discordUrl);
    final sink = _FakeSink(true);
    await pump(tester, sink: sink);

    await tester.tap(find.byKey(const ValueKey('test-discord')));
    await tester.pump();
    await tester.pump();

    expect(sink.sent, hasLength(1));
    expect(find.textContaining('Teszt üzenet elküldve'), findsOneWidget);
  });

  testWidgets('a failed test message says so', (tester) async {
    store.save(ChatService.discord, discordUrl);
    await pump(tester, sink: _FakeSink(false));

    await tester.tap(find.byKey(const ValueKey('test-discord')));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Nem sikerült elküldeni'), findsOneWidget);
  });

  testWidgets('remove turns the service off again', (tester) async {
    store.save(ChatService.discord, discordUrl);
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('remove-discord')));
    await tester.pump();

    expect(store.hasSaved(ChatService.discord), isFalse);
    expect(find.text('Nincs beállítva'), findsNWidgets(2));
  });

  testWidgets('a webhook from the environment is shown as set and cannot be edited', (tester) async {
    final fromEnv = ChatWebhookStore(dir.path, environment: const {'PALA_SLACK_WEBHOOK': 'x'});
    await pump(tester, withStore: fromEnv, sink: _FakeSink(true));

    expect(find.byKey(const ValueKey('webhook-slack')), findsNothing);
    expect(find.textContaining('PALA_SLACK_WEBHOOK'), findsOneWidget);
    expect(find.byKey(const ValueKey('test-slack')), findsOneWidget);
    expect(find.byKey(const ValueKey('remove-slack')), findsNothing);
  });
}
