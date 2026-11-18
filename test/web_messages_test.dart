import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pala/api/client.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/web/pala_web_server.dart';
import 'package:test/test.dart';

/// A reply from the local web server: status, headers and raw body.
class _Reply {
  final int status;
  final HttpHeaders headers;
  final List<int> body;
  _Reply(this.status, this.headers, this.body);
  dynamic get json => jsonDecode(utf8.decode(body));
}

void main() {
  late Directory config;
  late Directory cache;
  late HttpClient browser;

  setUpAll(() {
    config = Directory.systemTemp.createTempSync('pala_webmsg_config');
    cache = Directory.systemTemp.createTempSync('pala_webmsg_cache');
    AppState.configDirOverride = config.path;
    AppState.cacheDirOverride = cache.path;
  });

  tearDownAll(() {
    config.deleteSync(recursive: true);
    cache.deleteSync(recursive: true);
  });

  setUp(() => browser = HttpClient());
  tearDown(() => browser.close(force: true));

  Future<_Reply> get(PalaWebServer server, int port, String path) async {
    final req = await browser.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
    req.headers.set('x-pala-token', server.sessionToken);
    final res = await req.close();
    final body = await res.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    return _Reply(res.statusCode, res.headers, body);
  }

  group('web UI messages (demo account)', () {
    late PalaWebServer server;
    late int port;

    setUp(() async {
      server = PalaWebServer(client: DemoKretaClient());
      port = (await server.start())!;
    });
    tearDown(() => server.stop());

    test('the list carries the id the page needs to open a message', () async {
      final list = (await get(server, port, '/api/messages')).json as List;
      expect(list, isNotEmpty);
      expect(list.first['id'], isA<int>());
      expect(list.first['attachments'], isA<List>());
    });

    test('opening a message returns its full text and attachments', () async {
      final list = (await get(server, port, '/api/messages')).json as List;
      final withFile = list.firstWhere((m) => (m['attachments'] as List).isNotEmpty);
      final reply = await get(server, port, '/api/message?id=${withFile['id']}');
      expect(reply.status, HttpStatus.ok);
      expect(reply.json['text'], isNotEmpty);
      expect((reply.json['attachments'] as List).first['name'], isNotEmpty);
    });

    test('a message that cannot be loaded gives a Hungarian error, not an empty body', () async {
      final reply = await get(server, port, '/api/message?id=987654');
      expect(reply.status, HttpStatus.badGateway);
      expect(reply.json['error'], contains('nem tölthető be'));
    });

    test('demo attachments say that they cannot be downloaded', () async {
      final reply = await get(server, port, '/api/attachment?id=1');
      expect(reply.status, HttpStatus.notFound);
      expect(reply.json['error'], contains('Demó módban'));
    });
  });

  group('web UI messages (live account)', () {
    test('the full text is cleaned from HTML and the attachment bytes pass through', () async {
      final fileBytes = [0x25, 0x50, 0x44, 0x46, 0x0a, 0xff, 0x00];
      await http.runWithClient(() async {
        final server = PalaWebServer(client: KretaClient(instituteCode: 'teszt')..accessToken = 'token-1');
        final port = (await server.start())!;
        try {
          final message = await get(server, port, '/api/message?id=42');
          expect(message.json['text'], 'Kedves Szülők!\nIndulás 7:30-kor.');
          expect(message.json['attachments'], [
            {'id': 7, 'name': 'program.pdf'}
          ]);

          final file = await get(server, port, '/api/attachment?id=7');
          expect(file.status, HttpStatus.ok);
          expect(file.body, fileBytes);
          expect(file.headers.value('content-disposition'), 'attachment');
          expect(file.headers.value('x-content-type-options'), 'nosniff');

          final missing = await get(server, port, '/api/attachment?id=8');
          expect(missing.status, HttpStatus.badGateway);
          expect(missing.json['error'], contains('nem tölthető le'));
        } finally {
          await server.stop();
        }
      }, () => MockClient((req) async {
            final url = req.url.toString();
            if (url == 'https://eugyintezes.e-kreta.hu/api/v1/kommunikacio/postaladaelemek/42') {
              return http.Response.bytes(
                utf8.encode(jsonEncode({
                  'azonosito': 42,
                  'isElolvasva': true,
                  'uzenet': {
                    'feladoNev': 'Kiss Anna',
                    'targy': 'Kirándulás',
                    'kuldesDatum': '2026-11-10T08:15:00',
                    'szoveg': '<p>Kedves Szülők!</p><p><strong>Indulás</strong> 7:30-kor.</p>',
                    'csatolmanyok': [
                      {'azonosito': 7, 'fajlNev': 'program.pdf'}
                    ],
                  },
                })),
                200,
              );
            }
            if (url == 'https://eugyintezes.e-kreta.hu/api/v1/dokumentumok/uzenetek/7') {
              return http.Response.bytes(fileBytes, 200);
            }
            return http.Response('', 404);
          }));
    });
  });
}
