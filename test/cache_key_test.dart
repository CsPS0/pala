import 'package:test/test.dart';
import 'package:pala/api/api.dart';
import 'package:pala/api/client.dart';

void main() {
  const base = 'https://klik000000.e-kreta.hu';

  group('KretaClient.cacheKeyForUrl', () {
    test('grades get the grades key', () {
      expect(KretaClient.cacheKeyForUrl('$base${KretaApiEndpoints.grades}'), 'grades');
    });

    test('subject averages do not overwrite grades', () {
      expect(
        KretaClient.cacheKeyForUrl('$base${KretaApiEndpoints.averages}?oktatasiNevelesiFeladatUid=1'),
        'averages',
      );
    });

    test('group averages are kept per URL, not under grades', () {
      final url = '$base${KretaApiEndpoints.groupAverages}?oktatasiNevelesiFeladatUid=42';
      expect(KretaClient.cacheKeyForUrl(url), url);
    });
  });
}
