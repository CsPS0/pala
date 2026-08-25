import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:pala/app/cli_app.dart';
import 'package:pala/utils/logger.dart';
import 'package:pala/utils/win32_console.dart';
import 'package:pala/version.dart';

void main(List<String> arguments) async {
  enableUtf8Console();

  try {
    stdout.encoding = utf8;
    stderr.encoding = utf8;
  } catch (_) {}

  final parser = ArgParser()
    ..addOption('institute', abbr: 'i', help: 'Az intézmény kódja (pl. intezmeny123)')
    ..addOption('username', abbr: 'u', help: 'Felhasználónév (oktatási azonosító)')
    ..addOption('password', abbr: 'p', help: 'Jelszó')
    ..addFlag('web', abbr: 'w', negatable: false, help: 'Pala grafikus Webes Felület (Web UI) indítása a böngészőben')
    ..addFlag('desktop', abbr: 'g', negatable: false, help: 'Pala grafikus Asztali Alkalmazás (Desktop UI) indítása')
    ..addFlag('install-shortcut', negatable: false, help: 'Windows Start menü parancsikon létrehozása a Pala Desktophoz')
    ..addFlag('daemon', abbr: 'd', negatable: false, help: 'Háttérfolyamatként futtatás értesítésekhez')
    ..addFlag('demo', abbr: 'm', negatable: false, help: 'Indítás beépített demó profillal (Teszt Elek - Offline tesztadatok)')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Verzióinformáció megjelenítése')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Megjeleníti ezt a súgót')
    ..addFlag('debug', negatable: false, help: 'Debug mód: részletes hibaüzenetek a stderr-en')
    ..addOption('completions', help: 'Shell automatikus kiegészítés szkript generálása (bash, zsh, fish, powershell)');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    exit(1);
  }

  if (argResults['completions'] != null) {
    final shell = argResults['completions'].toString().toLowerCase();
    if (shell == 'bash') {
      print('complete -W "-i -u -p -d -m -v -h --institute --username --password --daemon --demo --version --help --completions" pala');
    } else if (shell == 'zsh') {
      print('compdef _pala pala\n_pala() { _arguments "-i" "-u" "-p" "-d" "-m" "-v" "-h" "--institute" "--username" "--password" "--daemon" "--demo" "--version" "--help" "--completions" }');
    } else if (shell == 'fish') {
      print('complete -c pala -s i -l institute\ncomplete -c pala -s u -l username\ncomplete -c pala -s p -l password\ncomplete -c pala -s d -l daemon\ncomplete -c pala -s m -l demo\ncomplete -c pala -s v -l version\ncomplete -c pala -s h -l help\ncomplete -c pala -l completions');
    } else if (shell == 'powershell') {
      print('Register-ArgumentCompleter -Native -CommandName pala -ScriptBlock { param(\$commandName, \$parameterName, \$wordToComplete, \$commandAst, \$fakeBoundParameters); @("-i", "-u", "-p", "-d", "-m", "-v", "-h", "--institute", "--username", "--password", "--daemon", "--demo", "--version", "--help", "--completions") | Where-Object { \$_ -like "\$wordToComplete*" } }');
    } else {
      print('Ismeretlen shell. Támogatott: bash, zsh, fish, powershell');
    }
    exit(0);
  }

  PalaLogger.init(enabled: argResults['debug']);

  if (argResults['version']) {
    print('Pala (Kréta TUI) $appVersion');
    exit(0);
  }

  if (argResults['help']) {
    print('Pala (Kréta TUI)');
    print('Használat: pala [opciók]');
    print(parser.usage);
    exit(0);
  }

  final app = PalaApp();

  if (argResults['web']) {
    if (argResults['demo']) {
      await app.runDemoWeb();
    } else {
      await app.runWeb();
    }
    exit(0);
  }

  if (argResults['desktop']) {
    await app.runDesktop();
    exit(0);
  }

  if (argResults['install-shortcut']) {
    await app.installStartMenuShortcut();
    exit(0);
  }

  if (argResults['daemon']) {
    await app.runDaemon();
    exit(0);
  }

  if (argResults['demo']) {
    await app.runDemo(startInDashboard: argResults.rest.contains('dash'));
    exit(0);
  }

  final institute = argResults['institute'];
  final username = argResults['username'];
  final password = argResults['password'];

  if (institute != null && username != null && password != null) {
    await app.runWithCredentials(institute, username, password, startInDashboard: argResults.rest.contains('dash'));
  } else {
    if (arguments.isNotEmpty && !argResults.rest.contains('dash')) {
      print('Figyelem: A parancssoros bejelentkezéshez az intézmény, felhasználónév és jelszó is szükséges.');
      print('Indítás interaktív módban...\n');
    }
    await app.runInteractive(startInDashboard: argResults.rest.contains('dash'));
  }
}
