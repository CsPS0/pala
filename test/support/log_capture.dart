import 'dart:io';

import 'package:pala/utils/logger.dart';

class _CapturingStdout implements Stdout {
  final lines = <String>[];

  @override
  void writeln([Object? object = '']) => lines.add('$object');

  @override
  void write(Object? object) => lines.add('$object');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Runs [body] with debug logging on and returns everything written to stderr.
/// Lets a test check that a log line never holds a webhook URL or token.
Future<String> captureDebugLog(Future<void> Function() body) async {
  final capture = _CapturingStdout();
  await IOOverrides.runZoned(
    () async {
      PalaLogger.init(enabled: true);
      try {
        await body();
      } finally {
        PalaLogger.init(enabled: false);
      }
    },
    stderr: () => capture,
  );
  return capture.lines.join('\n');
}
