import 'dart:ffi';
import 'dart:io';

import 'package:dart_console/dart_console.dart';

typedef _PollNative = Int32 Function(Pointer<Void> fds, UnsignedLong nfds, Int32 timeout);
typedef _PollDart = int Function(Pointer<Void> fds, int nfds, int timeout);
typedef _MallocNative = Pointer<Void> Function(Size size);
typedef _MallocDart = Pointer<Void> Function(int size);
typedef _GetStdHandleNative = Pointer<Void> Function(Int32 nStdHandle);
typedef _GetStdHandleDart = Pointer<Void> Function(int nStdHandle);
typedef _LocalAllocNative = Pointer<Void> Function(Uint32 flags, Size bytes);
typedef _LocalAllocDart = Pointer<Void> Function(int flags, int bytes);
typedef _ConsoleInputNative = Int32 Function(
    Pointer<Void> handle, Pointer<Void> buffer, Uint32 length, Pointer<Uint32> read);
typedef _ConsoleInputDart = int Function(
    Pointer<Void> handle, Pointer<Void> buffer, int length, Pointer<Uint32> read);

const int _winRecords = 16;
const int _winRecordSize = 20; // sizeof(INPUT_RECORD)
// Shift, Ctrl, Alt, Caps Lock, Win, Num Lock, Scroll Lock and their left/right variants.
const Set<int> _modifierKeys = {0x10, 0x11, 0x12, 0x14, 0x5B, 0x5C, 0x90, 0x91, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5};

// Bound once and kept for the process lifetime: a few bytes, reused on every poll.
final _PollDart? _poll = Platform.isWindows
    ? null
    : DynamicLibrary.process().lookupFunction<_PollNative, _PollDart>('poll');
final Pointer<Void> _pollFd = Platform.isWindows
    ? nullptr
    : DynamicLibrary.process().lookupFunction<_MallocNative, _MallocDart>('malloc')(8);

final DynamicLibrary? _kernel32 = Platform.isWindows ? DynamicLibrary.open('kernel32.dll') : null;
final Pointer<Void> _winStdin = _kernel32 == null
    ? nullptr
    : _kernel32!.lookupFunction<_GetStdHandleNative, _GetStdHandleDart>('GetStdHandle')(-10);
final Pointer<Void> _winBuffer = _kernel32 == null
    ? nullptr
    : _kernel32!.lookupFunction<_LocalAllocNative, _LocalAllocDart>('LocalAlloc')(
        0x40, _winRecords * _winRecordSize + 4);
final _ConsoleInputDart? _peekConsoleInput =
    _kernel32?.lookupFunction<_ConsoleInputNative, _ConsoleInputDart>('PeekConsoleInputW');
final _ConsoleInputDart? _readConsoleInput =
    _kernel32?.lookupFunction<_ConsoleInputNative, _ConsoleInputDart>('ReadConsoleInputW');

/// True when a byte can be read from the terminal without blocking, waiting
/// up to [timeoutMs]. Only meaningful while `stdin.hasTerminal`.
bool stdinHasInput(int timeoutMs) {
  if (!Platform.isWindows) {
    final fd = _pollFd.cast<Int32>();
    fd[0] = 0; // stdin
    final flags = _pollFd.cast<Int16>();
    flags[2] = 1; // events = POLLIN
    flags[3] = 0; // revents
    return _poll!(_pollFd, 1, timeoutMs) > 0;
  }
  if (_windowsKeyQueued()) return true;
  if (timeoutMs <= 0) return false;
  sleep(Duration(milliseconds: timeoutMs));
  return _windowsKeyQueued();
}

/// Windows queues key-up, focus, mouse and bare modifier records too; ReadFile
/// skips those and would block, so only other key-downs count as input.
bool _windowsKeyQueued() {
  final count = Pointer<Uint32>.fromAddress(_winBuffer.address + _winRecords * _winRecordSize);
  if (_peekConsoleInput!(_winStdin, _winBuffer, _winRecords, count) == 0) return false;
  final n = count.value;
  final words = _winBuffer.cast<Uint16>();
  final dwords = _winBuffer.cast<Int32>();
  for (var i = 0; i < n; i++) {
    final isKey = words[i * 10] == 1; // EventType == KEY_EVENT
    final keyDown = dwords[i * 5 + 1] != 0; // KeyEvent.bKeyDown
    final vk = words[i * 10 + 5]; // KeyEvent.wVirtualKeyCode
    final char = words[i * 10 + 7]; // KeyEvent.uChar
    if (isKey && keyDown && (char != 0 || !_modifierKeys.contains(vk))) return true;
  }
  // Only non-character records are queued: drop them so they don't pile up.
  if (n > 0) _readConsoleInput!(_winStdin, _winBuffer, n, count);
  return false;
}

/// Reads one keystroke if one is waiting, otherwise returns null right away.
/// The terminal must be in raw mode. Unlike `Console.readKey`, a lone Esc
/// does not block waiting for the rest of an escape sequence.
Key? readKeyNonBlocking({
  bool Function(int timeoutMs) hasInput = stdinHasInput,
  int Function() readByte = _readByte,
}) {
  if (!hasInput(0)) return null;
  final b = readByte();
  if (b < 0) return null;
  if (b == 0x1b) return _readEscape(hasInput, readByte);
  if (b >= 0x01 && b <= 0x1a) return Key.control(ControlCharacter.values[b]);
  if (b == 0x7f) return Key.control(ControlCharacter.backspace);
  if (b < 0x20) return Key.control(ControlCharacter.unknown);
  // shortcut: one byte per key, so non-ASCII letters come out garbled; the dashboard only binds ASCII keys.
  return Key.printable(String.fromCharCode(b));
}

int _readByte() => stdin.readByteSync();

Key _readEscape(bool Function(int) hasInput, int Function() readByte) {
  // The rest of an escape sequence arrives together with the Esc byte.
  if (!hasInput(25)) return Key.control(ControlCharacter.escape);
  final intro = readByte();
  if (intro != 0x5b && intro != 0x4f) return Key.control(ControlCharacter.unknown); // Alt+key
  final seq = StringBuffer();
  while (seq.length < 8 && hasInput(25)) {
    final c = readByte();
    if (c < 0) break;
    seq.writeCharCode(c);
    if (c >= 0x40 && c <= 0x7e) break; // final byte of the sequence
  }
  return Key.control(switch (seq.toString()) {
    'A' => ControlCharacter.arrowUp,
    'B' => ControlCharacter.arrowDown,
    'C' => ControlCharacter.arrowRight,
    'D' => ControlCharacter.arrowLeft,
    'H' || '1~' || '7~' => ControlCharacter.home,
    'F' || '4~' || '8~' => ControlCharacter.end,
    '3~' => ControlCharacter.delete,
    '5~' => ControlCharacter.pageUp,
    '6~' => ControlCharacter.pageDown,
    _ => ControlCharacter.unknown,
  });
}
