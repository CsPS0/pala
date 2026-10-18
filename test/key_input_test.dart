import 'package:dart_console/dart_console.dart';
import 'package:pala/app/tui/key_input.dart';
import 'package:test/test.dart';

/// Feeds [bytes] to [readKeyNonBlocking] as if they were queued on stdin.
Key? parse(List<int> bytes) {
  var i = 0;
  return readKeyNonBlocking(
    hasInput: (_) => i < bytes.length,
    readByte: () => bytes[i++],
  );
}

void main() {
  test('returns null when nothing is queued', () {
    expect(parse([]), isNull);
  });

  test('reads printable keys and control characters', () {
    expect(parse([0x71])!.char, 'q');
    expect(parse([0x09])!.controlChar, ControlCharacter.tab);
    expect(parse([0x0d])!.controlChar, ControlCharacter.enter);
    expect(parse([0x03])!.controlChar, ControlCharacter.ctrlC);
  });

  test('a lone Esc does not wait for more bytes', () {
    expect(parse([0x1b])!.controlChar, ControlCharacter.escape);
  });

  test('decodes arrow and paging escape sequences', () {
    expect(parse('\x1b[A'.codeUnits)!.controlChar, ControlCharacter.arrowUp);
    expect(parse('\x1bOB'.codeUnits)!.controlChar, ControlCharacter.arrowDown);
    expect(parse('\x1b[5~'.codeUnits)!.controlChar, ControlCharacter.pageUp);
    expect(parse('\x1b[6~'.codeUnits)!.controlChar, ControlCharacter.pageDown);
    expect(parse('\x1b[1;5C'.codeUnits)!.controlChar, ControlCharacter.unknown);
  });

  test('Alt+key is not mistaken for Esc', () {
    expect(parse('\x1bq'.codeUnits)!.controlChar, ControlCharacter.unknown);
  });
}
