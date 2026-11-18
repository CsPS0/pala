import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pala/models/message.dart';
import 'package:pala_app/state/app_model.dart';
import 'package:pala_app/views/messages_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An [AppModel] with a fixed inbox whose message detail and attachment
/// download are scripted, so the sheet can be driven without Kréta.
class _FakeModel extends AppModel {
  _FakeModel({this.fullText, this.savedFile, this.demo = false});

  /// The full body the detail call returns; null makes the call fail.
  String? fullText;

  /// The file a download produces; null makes the download fail.
  File? savedFile;
  final bool demo;
  int downloads = 0;

  @override
  List<Message> get messages => [
        Message(
          id: 42,
          senderName: 'Kiss Anna',
          subject: 'Kirándulás',
          sentDate: DateTime(2026, 11, 10, 8, 15),
          // What the inbox list carries: a preview cut in the middle of a tag.
          text: '<p>Kedves Szülők!</p><p>A jövő heti kirándulás részletei <stro',
          attachments: [MessageAttachment(id: 7, name: 'program.pdf')],
        ),
      ];

  @override
  bool get isDemo => demo;

  @override
  Future<String> messageText(Message m) async {
    if (fullText == null) throw Exception('unreachable');
    return fullText!;
  }

  @override
  Future<File?> saveAttachment(MessageAttachment a) async {
    downloads++;
    return savedFile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('hu_HU', null);
    SharedPreferences.setMockInitialValues({});
  });

  final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}program.pdf');

  /// Opens the only message of [model] and returns the files handed to the
  /// attachment presenter.
  Future<List<File>> openMessage(WidgetTester tester, _FakeModel model, {bool presentOk = true}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final presented = <File>[];
    await tester.pumpWidget(MaterialApp(
      home: MessagesView(
        appModel: model,
        presentAttachment: (f) async {
          presented.add(f);
          return presentOk;
        },
      ),
    ));
    await tester.tap(find.text('Kirándulás'));
    await tester.pumpAndSettle();
    return presented;
  }

  testWidgets('opening a message shows its full text, not the cut preview', (tester) async {
    await openMessage(tester, _FakeModel(fullText: 'Kedves Szülők!\nIndulás 7:30-kor az iskola elől.'));

    expect(find.textContaining('Indulás 7:30-kor az iskola elől.'), findsOneWidget);
    expect(find.text('program.pdf'), findsOneWidget);
    expect(find.text('Csatolmányok'), findsOneWidget);
  });

  testWidgets('a failed load says so in Hungarian, keeps the preview and can be retried', (tester) async {
    final model = _FakeModel();
    await openMessage(tester, model);

    expect(find.text('Az üzenet teljes szövege most nem tölthető be.'), findsOneWidget);
    expect(find.textContaining('A jövő heti kirándulás részletei'), findsOneWidget);
    expect(find.textContaining('<stro'), findsNothing);

    model.fullText = 'A teljes szöveg megérkezett.';
    await tester.tap(find.text('Újrapróbálás'));
    await tester.pumpAndSettle();

    expect(find.text('A teljes szöveg megérkezett.'), findsOneWidget);
    expect(find.text('Az üzenet teljes szövege most nem tölthető be.'), findsNothing);
  });

  testWidgets('on a phone the attachment is downloaded and opened', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final model = _FakeModel(fullText: 'Szöveg', savedFile: file);
    final presented = await openMessage(tester, model);

    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();

    expect(model.downloads, 1);
    expect(presented.single.path, file.path);
    expect(find.text('program.pdf megnyitva.'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a phone without a viewer for the file says so', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await openMessage(tester, _FakeModel(fullText: 'Szöveg', savedFile: file), presentOk: false);

    await tester.tap(find.text('Megnyitás'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nincs olyan alkalmazás'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on a desktop the attachment is saved and its folder can be opened', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final presented = await openMessage(tester, _FakeModel(fullText: 'Szöveg', savedFile: file));

    await tester.tap(find.text('Letöltés'));
    await tester.pumpAndSettle();

    expect(find.textContaining('program.pdf mentve ide:'), findsOneWidget);
    expect(presented, isEmpty, reason: 'a desktop never opens the downloaded file by itself');

    await tester.tap(find.text('Mappa megnyitása'));
    await tester.pumpAndSettle();
    expect(presented.single.path, file.path);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a failed download shows a Hungarian error', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await openMessage(tester, _FakeModel(fullText: 'Szöveg'));

    await tester.tap(find.text('Letöltés'));
    await tester.pumpAndSettle();

    expect(find.textContaining('A csatolmány most nem tölthető le.'), findsOneWidget);
    expect(find.text('Mappa megnyitása'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('demo mode explains that attachments cannot be downloaded', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final model = _FakeModel(fullText: 'Szöveg', savedFile: file, demo: true);
    await openMessage(tester, model);

    await tester.tap(find.text('Letöltés'));
    await tester.pumpAndSettle();

    expect(find.text('Demó módban a csatolmányok nem tölthetők le.'), findsOneWidget);
    expect(model.downloads, 0);
    debugDefaultTargetPlatformOverride = null;
  });
}
