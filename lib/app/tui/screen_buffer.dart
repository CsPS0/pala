import 'dart:io';
import 'dart:math';

import '../theme.dart';

/// Zero-flicker double-buffered terminal renderer and ANSI-aware layout engine.
///
/// Uses the terminal's alternate screen buffer (`\x1B[?1049h`), hides the
/// hardware cursor (`\x1B[?25l`), and diffs each frame line-by-line against
/// the previous frame before flushing a single atomic string to `stdout`.
class TuiScreenBuffer {
  static final RegExp _ansiRegex = RegExp(r'\x1B\[[0-9;?]*[a-zA-Z]');

  List<String> _previousFrame = const [];
  int _previousWidth = 0;
  int _previousHeight = 0;
  bool _isActive = false;

  /// Enters the alternate screen buffer and hides the cursor.
  void enter() {
    if (_isActive) return;
    _isActive = true;
    _previousFrame = const [];
    stdout.write('\x1B[?1049h\x1B[?25l\x1B[2J\x1B[H');
  }

  /// Restores the main screen buffer and shows the cursor.
  void exit() {
    if (!_isActive) return;
    _isActive = false;
    _previousFrame = const [];
    stdout.write('\x1B[0m\x1B[?25h\x1B[?1049l');
  }

  /// Renders [lines] into the terminal with zero flicker by diffing against
  /// the previously rendered frame and flushing a single atomic buffer.
  void render(List<String> lines, {int? width, int? height}) {
    final termCols = width ?? (stdout.hasTerminal ? stdout.terminalColumns : 100);
    final termRows = height ?? (stdout.hasTerminal ? stdout.terminalLines : 32);

    final dimensionsChanged =
        termCols != _previousWidth || termRows != _previousHeight;
    final maxRows = max(1, termRows);
    final nextFrame = <String>[];

    for (var r = 0; r < maxRows; r++) {
      final raw = r < lines.length ? lines[r] : '';
      final clamped = padRightAnsi(truncateAnsi(raw, termCols), termCols);
      nextFrame.add(clamped);
    }

    final out = StringBuffer();
    if (dimensionsChanged) {
      out.write('\x1B[2J\x1B[H');
    }

    for (var r = 0; r < maxRows; r++) {
      final line = nextFrame[r];
      if (dimensionsChanged ||
          r >= _previousFrame.length ||
          _previousFrame[r] != line) {
        // Rows are padded to the full width, so no erase-to-EOL: after a
        // full-width write the cursor sits on the last column and \x1B[K would
        // wipe the right border.
        out.write('\x1B[${r + 1};1H$line${PalaTheme.reset}');
      }
    }

    if (out.isNotEmpty) {
      stdout.write(out.toString());
    }

    _previousFrame = nextFrame;
    _previousWidth = termCols;
    _previousHeight = termRows;
  }

  /// Removes all ANSI escape codes from [text].
  static String stripAnsi(String text) {
    return text.replaceAll(_ansiRegex, '');
  }

  /// Returns the visible column width of [text], ignoring ANSI escape codes.
  static int visibleLength(String text) {
    return stripAnsi(text).runes.length;
  }

  /// Truncates [text] to [maxWidth] visible characters while preserving ANSI
  /// escape sequences and appending a reset code if truncated.
  static String truncateAnsi(
    String text,
    int maxWidth, {
    String ellipsis = '…',
  }) {
    if (maxWidth <= 0) return '';
    final visLen = visibleLength(text);
    if (visLen <= maxWidth) return text;

    final ellipsisLen = ellipsis.runes.length;
    final targetChars = maxWidth > ellipsisLen ? maxWidth - ellipsisLen : maxWidth;

    final buf = StringBuffer();
    var count = 0;
    var i = 0;
    var hadAnsi = false;

    while (i < text.length && count < targetChars) {
      if (text.codeUnitAt(i) == 0x1B) {
        final match = _ansiRegex.matchAsPrefix(text, i);
        if (match != null) {
          buf.write(match.group(0));
          i = match.end;
          hadAnsi = true;
          continue;
        }
      }
      final rune = text.runeAt(i);
      final charStr = String.fromCharCode(rune);
      buf.write(charStr);
      i += charStr.length;
      count++;
    }

    if (maxWidth > ellipsisLen) {
      buf.write(ellipsis);
    }
    if (hadAnsi) {
      buf.write(PalaTheme.reset);
    }
    return buf.toString();
  }

  /// Pads [text] on the right with spaces to reach [width] visible columns.
  static String padRightAnsi(String text, int width) {
    final len = visibleLength(text);
    if (len >= width) return text;
    return '$text${' ' * (width - len)}';
  }

  /// Centers [text] within [width] visible columns.
  static String padCenterAnsi(String text, int width) {
    final len = visibleLength(text);
    if (len >= width) return truncateAnsi(text, width);
    final totalPad = width - len;
    final leftPad = totalPad ~/ 2;
    final rightPad = totalPad - leftPad;
    return '${' ' * leftPad}$text${' ' * rightPad}';
  }

  /// Draws an internal horizontal pane divider (`├──────┤`) for a box of outer [width].
  static String horizontalDivider(
    int width, {
    String? label,
    String? borderColor,
  }) {
    final inner = max(0, width - 2);
    final bColor = borderColor ?? PalaTheme.borderMuted;
    if (label == null || label.isEmpty) {
      return '$bColor${PalaTheme.boxTeeRight}${PalaTheme.boxHorizontal * inner}${PalaTheme.boxTeeLeft}${PalaTheme.reset}';
    }
    final titleSegment = ' $label ';
    final titleVis = visibleLength(titleSegment);
    if (titleVis + 2 >= inner) {
      return '$bColor${PalaTheme.boxTeeRight}${PalaTheme.boxHorizontal * inner}${PalaTheme.boxTeeLeft}${PalaTheme.reset}';
    }
    final rem = inner - titleVis - 1;
    return '$bColor${PalaTheme.boxTeeRight}${PalaTheme.boxHorizontal}${PalaTheme.reset}$titleSegment$bColor${PalaTheme.boxHorizontal * rem}${PalaTheme.boxTeeLeft}${PalaTheme.reset}';
  }

  /// Builds a rounded Unicode frame (`╭─╮`, `│`, `╰─╯`) of exact outer [width]
  /// and optional fixed outer [height].
  static List<String> drawRoundedBox({
    required int width,
    int? height,
    String? title,
    String? rightBadge,
    required List<String> lines,
    bool focused = false,
    String? customBorderColor,
  }) {
    final safeWidth = max(4, width);
    final innerWidth = safeWidth - 2;
    final contentWidth = max(1, innerWidth - 2);
    final bColor = customBorderColor ??
        (focused ? PalaTheme.borderActive : PalaTheme.borderMuted);

    // Top border with optional title and right badge
    String topBorder;
    final leftTitle = (title != null && title.isNotEmpty) ? ' $title ' : '';
    final rightTag =
        (rightBadge != null && rightBadge.isNotEmpty) ? ' $rightBadge ' : '';
    final leftVis = visibleLength(leftTitle);
    final rightVis = visibleLength(rightTag);

    if (leftVis == 0 && rightVis == 0) {
      topBorder =
          '$bColor${PalaTheme.boxTopLeft}${PalaTheme.boxHorizontal * innerWidth}${PalaTheme.boxTopRight}${PalaTheme.reset}';
    } else if (leftVis + rightVis + 2 <= innerWidth) {
      final midDash = innerWidth - leftVis - rightVis - 2;
      topBorder =
          '$bColor${PalaTheme.boxTopLeft}${PalaTheme.boxHorizontal}${PalaTheme.reset}$leftTitle$bColor${PalaTheme.boxHorizontal * midDash}${PalaTheme.reset}$rightTag$bColor${PalaTheme.boxHorizontal}${PalaTheme.boxTopRight}${PalaTheme.reset}';
    } else {
      final trimmedTitle = truncateAnsi(leftTitle, max(1, innerWidth - 2));
      final tVis = visibleLength(trimmedTitle);
      final rem = max(0, innerWidth - tVis - 1);
      topBorder =
          '$bColor${PalaTheme.boxTopLeft}${PalaTheme.boxHorizontal}${PalaTheme.reset}$trimmedTitle$bColor${PalaTheme.boxHorizontal * rem}${PalaTheme.boxTopRight}${PalaTheme.reset}';
    }

    final targetBodyRows = height != null ? max(0, height - 2) : lines.length;
    final result = <String>[topBorder];

    for (var i = 0; i < targetBodyRows; i++) {
      final rawLine = i < lines.length ? lines[i] : '';
      // Allow raw full-width horizontal dividers inside the box
      if (rawLine.startsWith('__DIVIDER__')) {
        final label = rawLine.substring('__DIVIDER__'.length);
        result.add(horizontalDivider(
          safeWidth,
          label: label.isEmpty ? null : label,
          borderColor: bColor,
        ));
        continue;
      }
      final fitted =
          padRightAnsi(truncateAnsi(rawLine, contentWidth), contentWidth);
      result.add(
        '$bColor${PalaTheme.boxVertical}${PalaTheme.reset} $fitted $bColor${PalaTheme.boxVertical}${PalaTheme.reset}',
      );
    }

    final bottomBorder =
        '$bColor${PalaTheme.boxBottomLeft}${PalaTheme.boxHorizontal * innerWidth}${PalaTheme.boxBottomRight}${PalaTheme.reset}';
    result.add(bottomBorder);

    return result;
  }

  /// Combines two vertical blocks of lines side-by-side with exact column widths.
  static List<String> joinColumns(
    List<String> leftLines,
    int leftWidth,
    List<String> rightLines,
    int rightWidth, {
    String gap = ' ',
  }) {
    final totalRows = max(leftLines.length, rightLines.length);
    final combined = <String>[];
    for (var i = 0; i < totalRows; i++) {
      final l = i < leftLines.length ? leftLines[i] : '';
      final r = i < rightLines.length ? rightLines[i] : '';
      final lPadded = padRightAnsi(truncateAnsi(l, leftWidth), leftWidth);
      final rPadded = padRightAnsi(truncateAnsi(r, rightWidth), rightWidth);
      combined.add('$lPadded$gap$rPadded');
    }
    return combined;
  }

  /// Renders a smooth Unicode block progress bar (`━━━───` or `███░░░`).
  static String progressBar(
    double ratio,
    int width, {
    String? fillColor,
    bool useThinLine = false,
  }) {
    final safeWidth = max(4, width);
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * safeWidth).round();
    final empty = safeWidth - filled;
    final color = fillColor ?? PalaTheme.primary;
    final fillChar = useThinLine ? '━' : '█';
    final emptyChar = useThinLine ? '─' : '░';
    return '$color${fillChar * filled}${PalaTheme.muted}${emptyChar * empty}${PalaTheme.reset}';
  }
}

extension _StringRuneAt on String {
  int runeAt(int index) {
    final first = codeUnitAt(index);
    if ((first & 0xFC00) == 0xD800 && index + 1 < length) {
      final second = codeUnitAt(index + 1);
      if ((second & 0xFC00) == 0xDC00) {
        return 0x10000 + ((first & 0x3FF) << 10) + (second & 0x3FF);
      }
    }
    return first;
  }
}
