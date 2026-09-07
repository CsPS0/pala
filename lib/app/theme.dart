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

  // Custom prefix for menu and prompts
  static String get promptPrefix => '$primary?$reset';
  static String get arrowPrefix => '$primary>$reset';

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
