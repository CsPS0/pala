import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/api/client.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/models/message.dart';
import 'package:test/test.dart';

/// The inbox list as e-Ügyintézés sends it: the body is cut short (at 100
/// characters on the live service), even in the middle of a tag.
Map<String, dynamic> listItem() => {
      'azonosito': 42,
      'isElolvasva': false,
      'isToroltElem': false,
      'tipus': {'azonosito': 1, 'kod': 'BEERKEZETT'},
      'uzenet': {
        'azonosito': 9001,
        'kuldesDatum': '2026-11-10T08:15:00',
        'feladoNev': 'Kiss Anna',
        'feladoTitulus': 'osztályfőnök',
        'szoveg': '<p style="margin:0">Kedves Szülők!</p><p>A jövő heti kirándulás részletei a csatolt fájlban <stro',
        'targy': 'Kirándulás',
        'cimzettLista': [],
        'csatolmanyok': [
          {'azonosito': 7, 'fajlNev': 'program terv.pdf'},
        ],
      },
    };

Map<String, dynamic> detailItem() {
  final item = listItem();
  (item['uzenet'] as Map<String, dynamic>)['szoveg'] =
      '<p style="margin:0">Kedves Szülők!</p><p>A jövő heti kirándulás részletei a csatolt fájlban '
      '<strong>olvashatók</strong>. Indulás 7:30-kor az iskola elől.</p><p>Üdvözlettel:<br>Kiss Anna</p>';
  return item;
}

void main() {
  late Directory config;
  late Directory cache;
  late Directory downloads;

  setUpAll(() {
    config = Directory.systemTemp.createTempSync('pala_msg_config');
    cache = Directory.systemTemp.createTempSync('pala_msg_cache');
    AppState.configDirOverride = config.path;
    AppState.cacheDirOverride = cache.path;
  });

  setUp(() => downloads = Directory.systemTemp.createTempSync('pala_msg_downloads'));
  tearDown(() => downloads.deleteSync(recursive: true));

  tearDownAll(() {
    config.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  KretaClient client() => KretaClient(instituteCode: 'teszt')..accessToken = 'token-1';

  group('message detail', () {
    test('the list only carries a cut preview of the body', () {
      final preview = Message.fromJson(listItem());
      expect(preview.text, endsWith('<stro'));
      expect(preview.text, isNot(contains('Indulás')));
    });

    test('getMessage reads the full text and the attachments from the detail endpoint', () async {
      final requested = <Uri>[];
      final message = await http.runWithClient(
        () => client().getMessage(42),
        () => MockClient((req) async {
          requested.add(req.url);
          return http.Response.bytes(utf8.encode(jsonEncode(detailItem())), 200);
        }),
      );

      expect(requested.single.toString(), 'https://eugyintezes.e-kreta.hu/api/v1/kommunikacio/postaladaelemek/42');
      expect(message, isNotNull);
      expect(message!.text, contains('Indulás 7:30-kor az iskola elől.'));
      expect(message.attachments.single.id, 7);
      expect(message.attachments.single.name, 'program terv.pdf');
      expect(message.senderName, 'Kiss Anna');
    });

    test('getMessage is null when e-Ügyintézés answers with an error', () async {
      final message = await http.runWithClient(
        () => client().getMessage(43),
        () => MockClient((_) async => http.Response('Not found', 404)),
      );
      expect(message, isNull);
    });

    test('the demo client serves the full text without any request', () async {
      final demo = DemoKretaClient();
      final first = (await demo.getMessages())!.first;
      final message = await http.runWithClient(
        () => demo.getMessage(first.id),
        () => MockClient((req) async => fail('demo mode must not reach the network: ${req.url}')),
      );
      expect(message!.text, first.text);
      expect(message.attachments.length, first.attachments.length);
    });
  });

  group('attachments', () {
    test('saveAttachment downloads from e-Ügyintézés and writes the bytes', () async {
      final bytes = [0x25, 0x50, 0x44, 0x46, 0x00, 0xff];
      final requests = <http.Request>[];
      final file = await http.runWithClient(
        () => client().saveAttachment(7, 'program terv.pdf', directory: downloads.path),
        () => MockClient((req) async {
          requests.add(req);
          return http.Response.bytes(bytes, 200);
        }),
      );

      expect(requests.single.url.toString(), 'https://eugyintezes.e-kreta.hu/api/v1/dokumentumok/uzenetek/7');
      expect(requests.single.headers['authorization'], 'Bearer token-1');
      expect(file, isNotNull);
      expect(file!.parent.path, downloads.path);
      expect(file.uri.pathSegments.last, 'program_terv.pdf');
      expect(file.readAsBytesSync(), bytes);
    });

    test('saveAttachment is null and writes nothing when the download fails', () async {
      final file = await http.runWithClient(
        () => client().saveAttachment(7, 'program.pdf', directory: downloads.path),
        () => MockClient((_) async => http.Response('', 404)),
      );
      expect(file, isNull);
      expect(downloads.listSync(), isEmpty);
    });

    test('an expired access token is refreshed once and the download retried', () async {
      final seenTokens = <String?>[];
      final c = client()..refreshToken = 'refresh-1';
      final file = await http.runWithClient(
        () => c.saveAttachment(7, 'program.pdf', directory: downloads.path),
        () => MockClient((req) async {
          if (req.method == 'POST') {
            return http.Response(jsonEncode({'access_token': 'token-2', 'refresh_token': 'refresh-2'}), 200);
          }
          seenTokens.add(req.headers['authorization']);
          return seenTokens.length == 1 ? http.Response('', 401) : http.Response.bytes([1, 2, 3], 200);
        }),
      );
      expect(seenTokens, ['Bearer token-1', 'Bearer token-2']);
      expect(file!.readAsBytesSync(), [1, 2, 3]);
    });

    test('a second download of the same name does not overwrite the first', () async {
      Future<File?> save(List<int> bytes) => http.runWithClient(
            () => client().saveAttachment(7, 'program.pdf', directory: downloads.path),
            () => MockClient((_) async => http.Response.bytes(bytes, 200)),
          );
      final first = await save([1]);
      final second = await save([2]);
      expect(first!.path, isNot(second!.path));
      expect(first.readAsBytesSync(), [1]);
      expect(second.readAsBytesSync(), [2]);
      expect(second.uri.pathSegments.last, 'program_1.pdf');
    });

    test('the demo client has no downloadable attachment and makes no request', () async {
      final file = await http.runWithClient(
        () => DemoKretaClient().saveAttachment(1, 'Visegrad_programterv.pdf', directory: downloads.path),
        () => MockClient((req) async => fail('demo mode must not reach the network: ${req.url}')),
      );
      expect(file, isNull);
    });

    test('safeAttachmentFileName never leaves the download folder', () {
      expect(safeAttachmentFileName('program terv.pdf'), 'program_terv.pdf');
      expect(safeAttachmentFileName(r'..\..\Startup\evil.bat'), 'evil.bat');
      expect(safeAttachmentFileName('../../.bashrc'), 'bashrc');
      expect(safeAttachmentFileName('a<b>:c|d?.txt'), 'a_b__c_d_.txt');
      expect(safeAttachmentFileName('  '), 'csatolmany');
      expect(safeAttachmentFileName('..'), 'csatolmany');
    });
  });
}
