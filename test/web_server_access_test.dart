import 'dart:io';

import 'package:test/test.dart';
import 'package:pala/utils/loopback_host.dart';
import 'package:pala/web/pala_web_server.dart';

void main() {
  group('isLoopbackHost', () {
    test('accepts 127.0.0.1 and localhost on the server port', () {
      expect(isLoopbackHost('127.0.0.1:8080', 8080), isTrue);
      expect(isLoopbackHost('LOCALHOST:8080', 8080), isTrue);
    });

    test('rejects other hosts, other ports and a missing header', () {
      expect(isLoopbackHost('evil.example:8080', 8080), isFalse);
      expect(isLoopbackHost('127.0.0.1:9090', 8080), isFalse);
      expect(isLoopbackHost('127.0.0.1', 8080), isFalse);
      expect(isLoopbackHost(null, 8080), isFalse);
    });
  });

  group('PalaWebServer access', () {
    late PalaWebServer server;
    late int port;
    late HttpClient http;

    setUp(() async {
      server = PalaWebServer();
      port = (await server.start())!;
      http = HttpClient();
    });

    tearDown(() async {
      http.close(force: true);
      await server.stop();
    });

    Future<int> get(String pathAndQuery, {String? host}) async {
      final req = await http.getUrl(Uri.parse('http://127.0.0.1:$port$pathAndQuery'));
      if (host != null) req.headers.host = host;
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode;
    }

    test('the page is refused without the session token', () async {
      expect(await get('/'), HttpStatus.forbidden);
      expect(await get('/?token=wrong'), HttpStatus.forbidden);
    });

    test('the page is served with the session token', () async {
      expect(await get('/?token=${server.sessionToken}'), HttpStatus.ok);
    });

    test('a foreign Host header is refused even with the token', () async {
      expect(
        await get('/?token=${server.sessionToken}', host: 'evil.example'),
        HttpStatus.forbidden,
      );
    });
  });
}
