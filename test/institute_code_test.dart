import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:pala/api/api.dart';
import 'package:pala/api/client.dart';

void main() {
  group('BaseKreta.isValidInstituteCode', () {
    test('accepts real-looking codes', () {
      expect(BaseKreta.isValidInstituteCode('klik012345678'), isTrue);
      expect(BaseKreta.isValidInstituteCode('pala-minta-001'), isTrue);
    });

    test('rejects anything that could change the host', () {
      for (final code in ['evil.example#', 'a/b', 'klik 123', 'KLIK123', '', 'x']) {
        expect(BaseKreta.isValidInstituteCode(code), isFalse, reason: code);
      }
    });

    test('kreta() refuses to build a URL from an invalid code', () {
      expect(() => BaseKreta.kreta('evil.example#'), throwsFormatException);
      expect(BaseKreta.kreta('klik012345678'), 'https://klik012345678.e-kreta.hu');
    });
  });

  group('KretaClient.isNetworkError', () {
    test('only connection problems count as network errors', () {
      expect(KretaClient.isNetworkError(const SocketException('down')), isTrue);
      expect(KretaClient.isNetworkError(TimeoutException('slow')), isTrue);
      expect(KretaClient.isNetworkError(const FormatException('bad')), isFalse);
      expect(KretaClient.isNetworkError(StateError('bug')), isFalse);
    });
  });
}
