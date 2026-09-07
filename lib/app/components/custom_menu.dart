// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:math';
import 'package:dart_console/dart_console.dart';
import 'package:interact/src/framework/framework.dart';
import 'package:interact/src/theme/theme.dart';
import 'package:interact/src/utils/prompt.dart';

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  if (maxLength <= 3) return text.substring(0, max(0, maxLength));
  return '${text.substring(0, maxLength - 3)}...';
}

class CustomMenu extends Component<int> {
  CustomMenu({
    required this.prompt,
    required this.options,
    this.unselectableIndices = const [],
    this.initialIndex = 0,
    this.shortcuts,
  }) : theme = Theme.defaultTheme;

  final Theme theme;
  final String prompt;
  final int initialIndex;
  final List<String> options;
  final List<int> unselectableIndices;
  final Map<String, int>? shortcuts;

  @override
  _CustomMenuState createState() => _CustomMenuState();
}

class _CustomMenuState extends State<CustomMenu> {
  int index = 0;

  @override
  void init() {
    super.init();

    if (component.options.isEmpty) {
      throw Exception("Options can't be empty");
    }

    index = component.initialIndex;
    while (component.unselectableIndices.contains(index) && index < component.options.length - 1) {
      index++;
    }

    context.writeln(promptInput(
      theme: component.theme,
      message: component.prompt,
    ));
    context.hideCursor();
  }

  @override
  void dispose() {
    context.writeln(promptSuccess(
      theme: component.theme,
      message: component.prompt,
      value: component.options[index],
    ));
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final maxLen = max(10, width - 6);

    int selectableCount = 0;
    for (var i = 0; i < component.options.length; i++) {
      var option = component.options[i];
      if (!component.unselectableIndices.contains(i)) {
        option = _truncate(option, maxLen);
      }
      final line = StringBuffer();

      if (component.unselectableIndices.contains(i)) {
        // Dim the separator without prefix
        final sepMaxLen = max(10, width - 4);
        line.write('  \x1B[90m${_truncate(option, sepMaxLen)}\x1B[0m');
      } else {
        selectableCount++;
        String badge = '';
        if (component.shortcuts != null) {
          for (final entry in component.shortcuts!.entries) {
            if (entry.value == i) {
              badge = '\x1B[90m[${entry.key}]\x1B[0m ';
              break;
            }
          }
        }
        if (badge.isEmpty && selectableCount <= 9) {
          badge = '\x1B[90m[$selectableCount]\x1B[0m ';
        } else if (badge.isEmpty && selectableCount == 10) {
          badge = '\x1B[90m[0]\x1B[0m ';
        }

        if (i == index) {
          line.write(component.theme.activeItemPrefix);
          line.write(' ');
          if (badge.isNotEmpty) line.write(badge);
          line.write(component.theme.activeItemStyle(option));
        } else {
          line.write(component.theme.inactiveItemPrefix);
          line.write(' ');
          if (badge.isNotEmpty) line.write(badge);
          line.write(component.theme.inactiveItemStyle(option));
        }
      }
      context.writeln(line.toString());
    }
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      // Explicit custom shortcuts (e.g. 'd', 'w', '/', 'q')
      if (component.shortcuts != null && key.char.isNotEmpty) {
        final charLower = key.char.toLowerCase();
        if (component.shortcuts!.containsKey(charLower)) {
          final target = component.shortcuts![charLower]!;
          if (!component.unselectableIndices.contains(target)) {
            index = target;
            return target;
          }
        }
      }

      // Quick numbers: '1'-'9', '0'
      if (key.char.isNotEmpty && RegExp(r'^[0-9]$').hasMatch(key.char)) {
        final digit = int.parse(key.char);
        final targetSelectable = digit == 0 ? 9 : digit - 1;
        int currentSelectable = 0;
        for (int i = 0; i < component.options.length; i++) {
          if (!component.unselectableIndices.contains(i)) {
            if (currentSelectable == targetSelectable) {
              index = i;
              return i;
            }
            currentSelectable++;
          }
        }
      }

      // Vim navigation: 'k' or Up Arrow
      if (key.char == 'k' || key.controlChar == ControlCharacter.arrowUp) {
        setState(() {
          do {
            index = (index - 1) % component.options.length;
            if (index < 0) index += component.options.length;
          } while (component.unselectableIndices.contains(index));
        });
        continue;
      }

      // Vim navigation: 'j' or Down Arrow
      if (key.char == 'j' || key.controlChar == ControlCharacter.arrowDown) {
        setState(() {
          do {
            index = (index + 1) % component.options.length;
          } while (component.unselectableIndices.contains(index));
        });
        continue;
      }

      // 'q' or 'Q' or Esc: if not handled by explicit shortcuts, find 'Kilépés' or 'Vissza'
      if (key.char == 'q' || key.char == 'Q' || key.controlChar == ControlCharacter.escape) {
        for (int i = component.options.length - 1; i >= 0; i--) {
          final optLower = component.options[i].toLowerCase();
          if (optLower.contains('kilépés') || optLower.contains('vissza') || optLower == 'exit') {
            index = i;
            return i;
          }
        }
      }

      switch (key.controlChar) {
        case ControlCharacter.enter:
          if (!component.unselectableIndices.contains(index)) {
            return index;
          }
          break;
        default:
          break;
      }
    }
  }
}

class PaginatedMenu extends Component<int> {
  PaginatedMenu({
    required this.prompt,
    required this.allOptions,
    this.pageSize = 15,
    this.initialIndex = 0,
  }) : theme = Theme.defaultTheme;

  final Theme theme;
  final String prompt;
  final int initialIndex;
  final List<String> allOptions;
  final int pageSize;

  @override
  _PaginatedMenuState createState() => _PaginatedMenuState();
}

class _PaginatedMenuState extends State<PaginatedMenu> {
  int index = 0;
  int currentPage = 0;

  @override
  void init() {
    super.init();

    if (component.allOptions.isEmpty) {
      throw Exception("Options can't be empty");
    }

    index = component.initialIndex;
    currentPage = 0;

    context.writeln(promptInput(
      theme: component.theme,
      message: component.prompt,
    ));
    context.hideCursor();
  }

  @override
  void dispose() {
    final startIndex = currentPage * component.pageSize;
    final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
    final pageItemsCount = endIndex - startIndex;
    
    final value = (index == pageItemsCount) ? 'Vissza' : component.allOptions[currentPage * component.pageSize + index];
    context.writeln(promptSuccess(
      theme: component.theme,
      message: component.prompt,
      value: value,
    ));
    context.showCursor();
    super.dispose();
  }

  @override
  void render() {
    final hasPrev = currentPage > 0;
    final hasNext = (currentPage + 1) * component.pageSize < component.allOptions.length;
    final totalPages = ((component.allOptions.length - 1) / component.pageSize).floor() + 1;
    
    final prevColor = hasPrev ? '\x1B[94m' : '\x1B[90m';
    final nextColor = hasNext ? '\x1B[94m' : '\x1B[90m';
    
    final width = stdout.hasTerminal ? stdout.terminalColumns : 80;
    
    var header = '  ${prevColor}◀ Előző (h / Bal nyíl)${'\x1B[0m'}  |  ${nextColor}Következő (l / Jobb nyíl) ▶${'\x1B[0m'}  (Oldal: ${currentPage + 1} / $totalPages) \x1B[90m[q: Vissza]\x1B[0m';
    final headerClean = header.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    if (headerClean.length > width) {
      header = '  ${prevColor}◀ Előző${'\x1B[0m'} | ${nextColor}Következő ▶${'\x1B[0m'} (${currentPage + 1}/$totalPages) \x1B[90m[q]\x1B[0m';
    }
    context.writeln(header);
    
    final sepLength = min(width - 4, 66);
    final separator = '─' * sepLength;
    context.writeln('  \x1B[90m$separator\x1B[0m');

    final startIndex = currentPage * component.pageSize;
    final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
    final pageItemsCount = endIndex - startIndex;
    
    final maxLen = max(10, width - 6);
    
    for (var i = startIndex; i < endIndex; i++) {
      final option = _truncate(component.allOptions[i], maxLen);
      final localIndex = i - startIndex;
      final line = StringBuffer();
      final badge = localIndex < 9 ? '\x1B[90m[${localIndex + 1}]\x1B[0m ' : (localIndex == 9 ? '\x1B[90m[0]\x1B[0m ' : '    ');
      
      if (localIndex == index) {
        line.write(component.theme.activeItemPrefix);
        line.write(' ');
        line.write(badge);
        line.write(component.theme.activeItemStyle(option));
      } else {
        line.write(component.theme.inactiveItemPrefix);
        line.write(' ');
        line.write(badge);
        line.write(component.theme.inactiveItemStyle(option));
      }
      context.writeln(line.toString());
    }

    final line = StringBuffer();
    final backBadge = '\x1B[90m[q]\x1B[0m ';
    if (index == pageItemsCount) {
      line.write(component.theme.activeItemPrefix);
      line.write(' ');
      line.write(backBadge);
      line.write(component.theme.activeItemStyle('Vissza'));
    } else {
      line.write(component.theme.inactiveItemPrefix);
      line.write(' ');
      line.write(backBadge);
      line.write(component.theme.inactiveItemStyle('Vissza'));
    }
    context.writeln(line.toString());
  }

  @override
  int interact() {
    while (true) {
      final key = context.readKey();

      final startIndex = currentPage * component.pageSize;
      final endIndex = min(startIndex + component.pageSize, component.allOptions.length);
      final pageItemsCount = endIndex - startIndex;
      final totalSelectable = pageItemsCount + 1;

      // Vim movement: 'k' or Up Arrow
      if (key.char == 'k' || key.controlChar == ControlCharacter.arrowUp) {
        setState(() {
          index = (index - 1) % totalSelectable;
          if (index < 0) index += totalSelectable;
        });
        continue;
      }

      // Vim movement: 'j' or Down Arrow
      if (key.char == 'j' || key.controlChar == ControlCharacter.arrowDown) {
        setState(() {
          index = (index + 1) % totalSelectable;
        });
        continue;
      }

      // Left / Previous page: 'h' or '[' or Left Arrow
      if (key.char == 'h' || key.char == '[' || key.controlChar == ControlCharacter.arrowLeft) {
        if (currentPage > 0) {
          setState(() {
            currentPage--;
            index = 0;
          });
        }
        continue;
      }

      // Right / Next page: 'l' or ']' or Right Arrow
      if (key.char == 'l' || key.char == ']' || key.controlChar == ControlCharacter.arrowRight) {
        final nextStartIndex = (currentPage + 1) * component.pageSize;
        if (nextStartIndex < component.allOptions.length) {
          setState(() {
            currentPage++;
            index = 0;
          });
        }
        continue;
      }

      // 'q' or 'Q' or Esc -> return -1 (Back / Vissza)
      if (key.char == 'q' || key.char == 'Q' || key.controlChar == ControlCharacter.escape) {
        return -1;
      }

      // Quick numbers: '1'-'9', '0' selects item on current page
      if (key.char.isNotEmpty && RegExp(r'^[0-9]$').hasMatch(key.char)) {
        final digit = int.parse(key.char);
        final targetLocal = digit == 0 ? 9 : digit - 1;
        if (targetLocal < pageItemsCount) {
          return currentPage * component.pageSize + targetLocal;
        }
      }

      switch (key.controlChar) {
        case ControlCharacter.enter:
          if (index == pageItemsCount) {
            return -1;
          }
          return currentPage * component.pageSize + index;
        default:
          break;
      }
    }
  }
}
