import 'state/app_state.dart';
import 'package:interact/interact.dart';

class PalaTheme {
  // Dark/light mode ('dark' is the default and the only mode Pala shipped
  // with before; 'light' swaps the muted/dim color for one that stays
  // legible on a light terminal background).
  static const String modeDark = 'dark';
  static const String modeLight = 'light';

  static String get _mode => AppState.instance.themeMode;
  static bool get isLight => _mode == modeLight;

  // Single fixed accent color (Pala Amber). Kept as a constant everywhere
  // rather than user-selectable, per platform-wide accent removal.
  static const String primary = '\x1B[38;5;208m';
  static const String primaryBold = '\x1B[1;38;5;208m';

  // Common colors
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String success = '\x1B[32m';
  static const String warning = '\x1B[33m';
  static const String error = '\x1B[31m';

  // Bright-black (\x1B[90m) is a dim gray that reads fine on a dark
  // terminal background but is nearly invisible on a light one; light mode
  // swaps it for a dim variant of the default foreground instead.
  static String get muted => isLight ? '\x1B[2;30m' : '\x1B[90m';

  // High-contrast pane border and divider colors
  static String get borderMuted => isLight ? '\x1B[38;5;244m' : '\x1B[38;5;240m';
  static String get borderActive => primary;
  static String get borderHighlight => isLight ? '\x1B[38;5;31m' : '\x1B[38;5;45m';
  static String get textBright => isLight ? '\x1B[1;30m' : '\x1B[1;97m';
  static String get surfaceBadge => isLight ? '\x1B[48;5;254m\x1B[38;5;235m' : '\x1B[48;5;236m\x1B[38;5;252m';

  // Rounded Unicode box-drawing characters
  static const String boxTopLeft = '╭';
  static const String boxTopRight = '╮';
  static const String boxBottomLeft = '╰';
  static const String boxBottomRight = '╯';
  static const String boxHorizontal = '─';
  static const String boxVertical = '│';
  static const String boxTeeRight = '├';
  static const String boxTeeLeft = '┤';

  // Grade Color Psychology (ANSI 256 / TrueColor compatible):
  // 5: Bright Green, 4: Light Green, 3: Yellow, 2: Orange, 1: Red
  static const String grade5Fg = '\x1B[1;38;5;46m';
  static const String grade4Fg = '\x1B[1;38;5;114m';
  static const String grade3Fg = '\x1B[1;38;5;220m';
  static const String grade2Fg = '\x1B[1;38;5;208m';
  static const String grade1Fg = '\x1B[1;38;5;196m';
  static const String gradeGhostFg = '\x1B[1;38;5;51m';

  static const String grade5Pill = '\x1B[48;5;22m\x1B[1;38;5;46m';
  static const String grade4Pill = '\x1B[48;5;23m\x1B[1;38;5;114m';
  static const String grade3Pill = '\x1B[48;5;58m\x1B[1;38;5;220m';
  static const String grade2Pill = '\x1B[48;5;94m\x1B[1;38;5;208m';
  static const String grade1Pill = '\x1B[48;5;52m\x1B[1;38;5;196m';
  static const String gradeGhostPill = '\x1B[48;5;24m\x1B[1;38;5;51m';

  // Absence Color Psychology:
  // Unexcused: Red highlight, Pending: Yellow, Excused: Grey, Delay: Orange
  static const String absenceUnexcusedFg = '\x1B[1;38;5;196m';
  static const String absenceUnexcusedBadge = '\x1B[48;5;52m\x1B[1;38;5;203m';
  static const String absencePendingFg = '\x1B[1;38;5;220m';
  static const String absencePendingBadge = '\x1B[48;5;58m\x1B[1;38;5;220m';
  static String get absenceExcusedFg => isLight ? '\x1B[38;5;242m' : '\x1B[38;5;245m';
  static String get absenceExcusedBadge =>
      isLight ? '\x1B[48;5;252m\x1B[38;5;240m' : '\x1B[48;5;237m\x1B[38;5;248m';
  static const String absenceDelayFg = '\x1B[1;38;5;208m';
  static const String absenceDelayBadge = '\x1B[48;5;94m\x1B[1;38;5;214m';

  static String gradeColor(num? value) {
    switch (value?.round()) {
      case 5:
        return grade5Fg;
      case 4:
        return grade4Fg;
      case 3:
        return grade3Fg;
      case 2:
        return grade2Fg;
      case 1:
        return grade1Fg;
      default:
        return reset;
    }
  }

  static String formatGradePill(num? value, {String? fallback, bool isGhost = false}) {
    final intVal = value?.round();
    if (isGhost && intVal != null) {
      return '$gradeGhostPill *$intVal* $reset';
    }
    switch (intVal) {
      case 5:
        return '$grade5Pill 5 $reset';
      case 4:
        return '$grade4Pill 4 $reset';
      case 3:
        return '$grade3Pill 3 $reset';
      case 2:
        return '$grade2Pill 2 $reset';
      case 1:
        return '$grade1Pill 1 $reset';
      default:
        final txt = fallback ?? '?';
        return '$surfaceBadge $txt $reset';
    }
  }

  static String averageColor(double avg) {
    if (avg >= 4.5) return grade5Fg;
    if (avg >= 3.5) return grade4Fg;
    if (avg >= 2.5) return grade3Fg;
    if (avg >= 1.75) return grade2Fg;
    if (avg > 0) return grade1Fg;
    return muted;
  }

  static String absenceColor(String status, {String? type}) {
    final sLower = status.toLowerCase();
    final tLower = (type ?? '').toLowerCase();
    if (tLower.contains('késés') || sLower.contains('késés')) {
      return absenceDelayFg;
    }
    if (sLower.contains('igazolatlan')) {
      return absenceUnexcusedFg;
    }
    if (sLower.contains('igazolando') || sLower.contains('igazolandó') || sLower.contains('függő')) {
      return absencePendingFg;
    }
    if (sLower.contains('igazolt')) {
      return absenceExcusedFg;
    }
    return absencePendingFg;
  }

  static String formatAbsenceBadge(String status, {String? type, int? delayMinutes}) {
    final sLower = status.toLowerCase();
    final tLower = (type ?? '').toLowerCase();
    if (tLower.contains('késés') || sLower.contains('késés')) {
      final minStr = (delayMinutes != null && delayMinutes > 0) ? ' ${delayMinutes}p' : '';
      return '$absenceDelayBadge KÉSÉS$minStr ($status) $reset';
    }
    if (sLower.contains('igazolatlan')) {
      return '$absenceUnexcusedBadge IGAZOLATLAN $reset';
    }
    if (sLower.contains('igazolando') || sLower.contains('igazolandó')) {
      return '$absencePendingBadge IGAZOLANDÓ $reset';
    }
    if (sLower.contains('igazolt')) {
      return '$absenceExcusedBadge IGAZOLT $reset';
    }
    return '$absencePendingBadge ${status.toUpperCase()} $reset';
  }

  static void configureInteractTheme() {
    Theme.defaultTheme = Theme(
      inputPrefix: '$primary?$reset ',
      inputSuffix: ' $muted>$reset',
      successPrefix: '\x1B[32m[OK]\x1B[0m ',
      successSuffix: ' $muted·$reset',
      errorPrefix: '\x1B[31m[HIBA]\x1B[0m ',
      hiddenPrefix: '****',
      messageStyle: (x) => '\x1B[1m$x\x1B[0m',
      errorStyle: (x) => '\x1B[31m$x\x1B[0m',
      hintStyle: (x) => '$muted($x)$reset',
      valueStyle: (x) => '$primary$x$reset',
      defaultStyle: (x) => '$primary$x$reset',
      activeItemPrefix: '$primary>$reset',
      inactiveItemPrefix: ' ',
      activeItemStyle: (x) => '$primaryBold$x$reset',
      inactiveItemStyle: (x) => x,
      checkedItemPrefix: '$primary[x]$reset',
      uncheckedItemPrefix: '[ ]',
      pickedItemPrefix: '$primary>$reset',
      unpickedItemPrefix: ' ',
      showActiveCursor: false,
      progressPrefix: '',
      progressSuffix: '',
      emptyProgress: '░',
      filledProgress: '█',
      leadingProgress: '█',
      emptyProgressStyle: (x) => x,
      filledProgressStyle: (x) => x,
      leadingProgressStyle: (x) => x,
      spinners: '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'.split(''),
      spinningInterval: 80,
    );
  }
}
