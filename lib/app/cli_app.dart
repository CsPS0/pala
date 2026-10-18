import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:http/http.dart' as http;
import 'package:interact/interact.dart';
import 'package:pala/api/api.dart';
import 'package:pala/api/client.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/models/models.dart';
import 'package:pala/utils/chart_generator.dart';
import 'package:pala/utils/ics_exporter.dart';
import 'package:pala/utils/encryption.dart';
import 'package:pala/utils/web_composer.dart';
import 'package:pala/web/pala_web_server.dart';
import 'package:pala/app/components/custom_menu.dart';
import 'package:pala/app/components/utf8_input.dart';
import 'package:pala/app/theme.dart';
import 'package:pala/app/tui/key_input.dart';
import 'package:pala/app/tui/screen_buffer.dart';
import 'package:pala/app/tui/tui_state.dart';
import 'package:pala/app/tui/tui_views.dart';
import 'package:pala/utils/logger.dart';
import 'package:pala/utils/win32_console.dart';
import 'package:pala/version.dart';
import 'package:path/path.dart' as p;
import 'state/app_state.dart';

part 'login/auth_manager.dart';
part 'login/login_flow.dart';
part 'daemon/daemon_logic.dart';

part 'views/settings_view.dart';
part 'views/student_data_view.dart';
part 'views/grades_view.dart';
part 'views/timetable_view.dart';
part 'views/absences_view.dart';
part 'views/homework_messages_view.dart';
part 'views/export_view.dart';
part 'views/dashboard_view.dart';
part 'views/wrapped_view.dart';

class PalaApp {
  bool isDemo = false;

  Future<bool> _ensureClientReady() async {
    if (_client == null) {
      print('Hiba: Kliens nincs inicializálva. Próbálj újra bejelentkezni!');
      return false;
    }
    return true;
  }

  void _clearScreen() {
    stdout.write('\x1B[2J\x1B[3J\x1B[H');
  }

  KretaClient? _client;
  String? studentUid;

  File _getAuthFile() {
    return AppState.instance.authFile;
  }

  Future<bool> _tryAutoLogin() async {
    final authFile = _getAuthFile();
    if (!authFile.existsSync()) return false;

    try {
      final content = await authFile.readAsString();
      dynamic data;
      // Handle plain-text vs encrypted
      if (content.trim().startsWith('{')) {
        data = jsonDecode(content);
        // We let auth_manager.dart handle the actual encryption/migration upon first successful login/save.
      } else {
        final decrypted = EncryptionUtil.decrypt(content);
        data = jsonDecode(decrypted);
      }
      
      Map<String, dynamic>? activeProfile;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('profiles')) {
          final profiles = data['profiles'] as List;
          final idx = data['activeProfileIndex'] ?? 0;
          if (profiles.isNotEmpty && idx >= 0 && idx < profiles.length) {
            activeProfile = profiles[idx];
          }
        } else if (data.containsKey('accessToken')) {
          activeProfile = data;
        }
      }

      if (activeProfile != null) {
        final instituteCode = activeProfile['instituteCode'];
        final accessToken = activeProfile['accessToken'];
        final refreshToken = activeProfile['refreshToken'];

        if (instituteCode != null && accessToken != null) {
          _client = KretaClient(instituteCode: instituteCode);
          _client!.accessToken = accessToken;
          _client!.refreshToken = refreshToken;
          _client!.onTokenRefreshed = () async {
            await _saveAuth();
          };

          var studentData = await _client!.getStudentData(silent: true);
          
          if (studentData == null && refreshToken != null) {
            // Token might be expired, let's try to refresh
            if (await _client!.refreshAccessToken()) {
              studentData = await _client!.getStudentData();
              if (studentData != null) {
                // Save the new tokens silently
                await _saveAuth();
              }
            }
          }

          if (studentData != null) {
            studentUid = studentData.uid;
            return true;
          }
        }
      }
    } on FormatException catch (_) {
      print('\x1B[1;31mA titkosítási kulcs érvénytelen (valószínűleg megváltozott a számítógép neve). Kérlek, jelentkezz be újra!\x1B[0m\n');
      if (authFile.existsSync()) authFile.deleteSync();
      return false;
    } catch (e) {
      // Ignore other errors like network timeouts on refresh
    }
    
    return false;
  }

  Future<void> runDaemon() async {
    if (!await _tryAutoLogin()) {
      return;
    }
    await _checkNewItems();
  }

  void _showBanner() {
    print(PalaTheme.primary);
    print(r'''
    ____        __       
   / __ \____ _/ /___ _  
  / /_/ / __ `/ / __ `/  
 / ____/ /_/ / / /_/ /   
/_/    \__,_/_/\__,_/  TUI '''
    '$appVersion\n');
    print(PalaTheme.reset);
  }

  void _showMainMenuBanner() {
    if (_client != null && _client!.isMaintenanceMode) {
      print('\x1B[1;33m  [!] KARBANTARTÁS: A Kréta szervere jelenleg nem elérhető (HTTP ${_client!.maintenanceStatusCode}). A korábban mentett (gyorsítótárazott) adatokat látod.\x1B[0m\n');
    }
    if (!AppState.instance.showAsciiBanner) return;

    final color = PalaTheme.primary;
    print(color);
    print(r'''
██████╗  █████╗ ██╗      █████╗ 
██╔══██╗██╔══██╗██║     ██╔══██╗
██████╔╝███████║██║     ███████║
██╔═══╝ ██╔══██║██║     ██╔══██║
██║     ██║  ██║███████╗██║  ██║
╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝''');
    print(PalaTheme.reset);
    final statusBadge = isDemo
        ? '${PalaTheme.primaryBold}● DEMÓ: Teszt Elek${PalaTheme.reset}'
        : (AppState.instance.isOffline
            ? '${PalaTheme.grade1Fg}● OFFLINE${PalaTheme.reset}'
            : '${PalaTheme.grade5Fg}● ONLINE${PalaTheme.reset}');
    final boxLines = TuiScreenBuffer.drawRoundedBox(
      width: 56,
      lines: [
        '${PalaTheme.textBright}Pala Kréta TUI v$appVersion${PalaTheme.reset}  │  $statusBadge  │  ${PalaTheme.muted}[d] Élő TUI${PalaTheme.reset}',
      ],
    );
    for (final line in boxLines) {
      print(line);
    }
    print('');
  }

  Future<void> runDemo({bool startInDashboard = false}) async {
    AppState.instance.migrateOldFiles();
    PalaTheme.configureInteractTheme();
    _showBanner();
    isDemo = true;
    _client = DemoKretaClient();
    print('\x1B[1;32m[+] Demó profil betöltve: Teszt Elek (Pala Minta Gimnázium)\x1B[0m\n');
    if (startInDashboard) {
      await _showDashboard();
    } else {
      await _mainMenu();
    }
  }

  Future<void> runDemoWeb() async {
    AppState.instance.migrateOldFiles();
    isDemo = true;
    _client = DemoKretaClient();
    await PalaWebServer.runInteractive(client: _client!);
  }

  Future<void> runWeb() async {
    AppState.instance.migrateOldFiles();
    PalaTheme.configureInteractTheme();

    await _tryAutoLogin();
    await PalaWebServer.runInteractive(client: _client);
  }

  Future<void> runInteractive({bool startInDashboard = false}) async {
    AppState.instance.migrateOldFiles();
    PalaTheme.configureInteractTheme();
    _showBanner();

    if (!AppState.instance.isSetupCompleted &&
        !AppState.instance.hasAuth() &&
        stdin.hasTerminal &&
        stdout.hasTerminal) {
      await runSetupWizard(isFirstRun: true);
    }

    print('Keresem a mentett bejelentkezést...');
    if (await _tryAutoLogin()) {
      print('Sikeres automatikus bejelentkezés!\n');
      await _checkForUpdates();
      if (startInDashboard) {
        await _showDashboard();
      } else {
        await _mainMenu();
      }
      return;
    }

    print('\x1B[38;5;208m=============================================================');
    print(' FIGYELEM! Kérjük, kapcsold ki a böngészős kiegészítőket');
    print(' a bejelentkezés idejére, mert megzavarhatják a hitelesítést!');
    print('=============================================================\x1B[0m\n');

    await _performLoginFlow();
    await _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/CsPS0/pala/releases/latest'),
      ).timeout(Duration(seconds: 2));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final latestVersion = data['tag_name'] as String?;
        final currentVersion = appVersion;
        
        if (latestVersion != null && latestVersion != currentVersion && latestVersion.startsWith('v')) {
          print('\x1B[33m\n=============================================================');
          print('[!] Új Pala verzió érhető el: $latestVersion (Jelenlegi: $currentVersion)');
          print('Kérjük, frissíts a legújabb verzióra a következő parancsok egyikével:');
          print('  - Windows (Scoop):     scoop update pala');
          print('  - Linux (APT):         sudo apt update && sudo apt install pala');
          print('  - macOS (Homebrew):    brew upgrade pala');
          print('  - Manuális szkript:    curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash');
          print('=============================================================\x1B[0m\n');
        }
      }
    } catch (e) {
      PalaLogger.debug('Update check failed: $e');
    }
  }

  Future<void> runWithCredentials(String instituteCode, String username, String password, {bool startInDashboard = false}) async {
    AppState.instance.migrateOldFiles();
    PalaTheme.configureInteractTheme();
    _client = KretaClient(instituteCode: instituteCode);
    _client!.onTokenRefreshed = () async {
      await _saveAuth();
    };
    bool loggedIn;
    try {
      loggedIn = await _client!.login(username, password);
    } on InteractiveLoginRequired catch (e) {
      print('$e');
      print('Indítsd a Pala-t paraméterek nélkül, és válaszd a webes bejelentkezést.');
      exit(1);
    }
    if (loggedIn) {
      await _saveAuth();
      await _checkForUpdates();
      if (startInDashboard) {
        await _showDashboard();
      } else {
        await _mainMenu();
      }
    } else {
      print('Bejelentkezés sikertelen!');
      exit(1);
    }
  }

  Future<void> _mainMenu() async {
    int _lastMainMenuIndex = 0;
    while (true) {
      _clearScreen();
      _showMainMenuBanner();
      final stateFile = AppState.instance.stateFile;
      List<dynamic> hiddenItems = [];
      if (stateFile.existsSync()) {
        try {
          final state = jsonDecode(stateFile.readAsStringSync());
          if (state['hiddenMenuItems'] != null) {
            hiddenItems = state['hiddenMenuItems'];
          }
        } catch (e) {
          PalaLogger.debug('Failed to parse state file: $e');
        }
      }

      final layout = [
        {'type': 'separator', 'label': '──────────────────────'},
        {'type': 'action', 'id': -2, 'label': 'Dashboard (Élő nézet)', 'key': 'd'},
        {'type': 'action', 'id': 10, 'label': 'Pala Wrapped (Év végi összefoglaló)', 'key': 'w'},
        {'type': 'action', 'id': 0, 'label': 'Tanulói adatlap'},
        {'type': 'action', 'id': 2, 'label': 'Órarend', 'key': 'o'},
        {'type': 'separator', 'label': '──────────────────────'},
        {'type': 'action', 'id': 1, 'label': 'Legutóbbi jegyek', 'key': 'g'},
        {'type': 'action', 'id': 4, 'label': 'Tantárgyi átlagok', 'key': 'a'},
        {'type': 'separator', 'label': '──────────────────────'},
        {'type': 'action', 'id': 3, 'label': 'Mulasztások', 'key': 'm'},
        {'type': 'action', 'id': 5, 'label': 'Számonkérések'},
        {'type': 'action', 'id': 6, 'label': 'Házi feladatok'},
        {'type': 'action', 'id': 7, 'label': 'Üzenetek'},
        {'type': 'separator', 'label': '──────────────────────'},
        {'type': 'action', 'id': 8, 'label': 'Keresés', 'key': '/'},
        {'type': 'action', 'id': -3, 'label': 'Pala Webes felület (Web UI)'},
        {'type': 'action', 'id': -4, 'label': 'Pala Asztali Alkalmazás (Desktop UI)'},
        {'type': 'action', 'id': 9, 'label': 'Beállítások', 'key': 'b'},
        {'type': 'action', 'id': 100, 'label': 'Kilépés', 'key': 'q'},
      ];

      List<String> displayOptions = [];
      List<int> actionIds = [];
      Map<String, int> menuShortcuts = {};

      for (var item in layout) {
        if (item['type'] == 'separator') {
          displayOptions.add(item['label'] as String);
          actionIds.add(-1);
        } else {
          final id = item['id'] as int;
          if (!hiddenItems.contains(id) || id == 9 || id == 100) {
            final optIndex = displayOptions.length;
            displayOptions.add(item['label'] as String);
            actionIds.add(id);

            if (item.containsKey('key')) {
              menuShortcuts[(item['key'] as String).toLowerCase()] = optIndex;
            }
          }
        }
      }

      List<int> unselectable = [];
      for (int i = 0; i < displayOptions.length; i++) {
        if (displayOptions[i].startsWith('──')) {
          unselectable.add(i);
        }
      }

      final promptText = isDemo 
          ? 'Pala Főmenü \x1B[1;33m[DEMÓ: Teszt Elek]\x1B[0m \x1B[90m(↑/↓ vagy j/k, [1-9], d: Élő TUI, q: kilépés)\x1B[0m' 
          : (AppState.instance.isOffline 
              ? 'Pala Főmenü \x1B[1;31m[OFFLINE MÓD]\x1B[0m \x1B[90m(↑/↓ vagy j/k, [1-9], d: Élő TUI, q: kilépés)\x1B[0m' 
              : 'Pala Főmenü \x1B[90m(↑/↓ vagy j/k, [1-9], d: Élő TUI, q: kilépés)\x1B[0m');

      if (_lastMainMenuIndex >= displayOptions.length) {
        _lastMainMenuIndex = 0;
      }

      final selection = CustomMenu(
        prompt: promptText,
        options: displayOptions,
        unselectableIndices: unselectable,
        initialIndex: _lastMainMenuIndex,
        shortcuts: menuShortcuts,
      ).interact();

      _lastMainMenuIndex = selection;

      final action = actionIds[selection];

      switch (action) {
        case 0:
          _clearScreen();
          await _showStudentData();
          _clearScreen();
          break;
        case 1:
          _clearScreen();
          await _showGrades();
          _clearScreen();
          break;
        case 2:
          _clearScreen();
          await _showTimetable();
          _clearScreen();
          break;
        case 3:
          _clearScreen();
          await _showAbsences();
          _clearScreen();
          break;
        case 4:
          _clearScreen();
          await _showAverages();
          _clearScreen();
          break;
        case 5:
          _clearScreen();
          await _showExams();
          _clearScreen();
          break;
        case 6:
          _clearScreen();
          await _showHomework();
          _clearScreen();
          break;
        case 7:
          _clearScreen();
          await _showMessages();
          _clearScreen();
          break;
        case 8:
          _clearScreen();
          await _globalSearch();
          _clearScreen();
          break;
        case 9:
          _clearScreen();
          await _showSettings();
          _clearScreen();
          break;
        case 10:
          _clearScreen();
          await _showPalaWrapped();
          _clearScreen();
          break;
        case -2:
          await _showDashboard();
          _clearScreen();
          break;
        case -3:
          _clearScreen();
          await PalaWebServer.runInteractive(client: _client!);
          _clearScreen();
          break;
        case -4:
          _clearScreen();
          await runDesktop();
          _clearScreen();
          break;
        case 100:
          final confirm = Confirm(
            prompt: 'Biztos ki akarsz lépni?',
            defaultValue: false,
          ).interact();
          if (confirm) {
            print('Viszlát!');
            exit(0);
          }
          break;
      }
    }
  }

  String? _findInstalledDesktopExe() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final candidates = [
        '$localAppData\\Programs\\Pala\\desktop\\palapp.exe',
        '$localAppData\\Programs\\Pala\\desktop\\pala.exe',
        '$localAppData\\Programs\\Pala\\palapp.exe',
        '$localAppData\\Programs\\Pala\\pala.exe',
        '$localAppData\\Pala\\desktop\\palapp.exe',
        '$localAppData\\Pala\\desktop\\pala.exe',
        'app\\build\\windows\\x64\\runner\\Release\\palapp.exe',
        'app\\build\\windows\\x64\\runner\\Release\\pala.exe',
        '$userProfile\\scoop\\apps\\pala\\current\\pala.exe',
      ];
      for (final c in candidates) {
        if (File(c).existsSync()) return c;
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      final candidates = [
        '$home/.local/share/pala/Pala.AppImage',
        '$home/.local/bin/pala-desktop',
      ];
      for (final c in candidates) {
        if (File(c).existsSync()) return c;
      }
    } else if (Platform.isMacOS) {
      if (Directory('/Applications/Pala.app').existsSync()) {
        return '/Applications/Pala.app';
      }
    }
    return null;
  }

  Future<bool> _downloadFile(String url, File destination) async {
    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.followRedirects = true;
        request.maxRedirects = 10;
        final response = await client.send(request);
        if (response.statusCode == 200) {
          final sink = destination.openWrite();
          await response.stream.pipe(sink);
          await sink.close();
          if (destination.existsSync() && destination.lengthSync() > 1000) {
            return true;
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      PalaLogger.debug('Download error via http: $e');
    }

    try {
      if (Platform.isWindows) {
        final res = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Invoke-WebRequest -Uri "$url" -OutFile "${destination.path}" -MaximumRedirection 10'
        ]);
        if (res.exitCode == 0 && destination.existsSync() && destination.lengthSync() > 1000) {
          return true;
        }
      } else {
        final res = await Process.run('curl', ['-fsSL', '-o', destination.path, url]);
        if (res.exitCode == 0 && destination.existsSync() && destination.lengthSync() > 1000) {
          return true;
        }
      }
    } catch (e) {
      PalaLogger.debug('Download fallback error: $e');
    }
    return false;
  }

  Future<bool> installDesktopApp() async {
    print('\x1B[33m[+] Pala Desktop letöltése és telepítése...\x1B[0m');
    if (Platform.isWindows) {
      final tempDir = Directory.systemTemp.path;
      final tempSetup = File('$tempDir\\Pala-Setup.exe');
      const setupUrl = 'https://github.com/CsPS0/pala/releases/latest/download/Pala-Setup.exe';
      print('    Letöltés: $setupUrl');
      final success = await _downloadFile(setupUrl, tempSetup);
      if (success) {
        print('    [+] Háttérbeli telepítés indítása...');
        final res = await Process.run(tempSetup.path, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART']);
        if (res.exitCode == 0) {
          print('\x1B[32m    [OK] Pala Desktop sikeresen telepítve!\x1B[0m');
          try { if (tempSetup.existsSync()) tempSetup.deleteSync(); } catch (_) {}
          return true;
        } else {
          print('\x1B[33m    [!] A telepítő kilépési kódja: ${res.exitCode}\x1B[0m');
        }
        try { if (tempSetup.existsSync()) tempSetup.deleteSync(); } catch (_) {}
      } else {
        print('\x1B[31m    [!] A Pala-Setup.exe letöltése sikertelen.\x1B[0m');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      final appDir = Directory('$home/.local/share/pala');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final appImageFile = File('${appDir.path}/Pala.AppImage');
      const url = 'https://github.com/CsPS0/pala/releases/latest/download/Pala-x86_64.AppImage';
      print('    Letöltés: $url');
      final success = await _downloadFile(url, appImageFile);
      if (success) {
        Process.runSync('chmod', ['+x', appImageFile.path]);
        final binDir = Directory('$home/.local/bin');
        if (!binDir.existsSync()) binDir.createSync(recursive: true);
        Process.runSync('ln', ['-sf', appImageFile.path, '${binDir.path}/pala-desktop']);
        print('\x1B[32m    [OK] Pala AppImage sikeresen telepítve: ${appImageFile.path}\x1B[0m');
        return true;
      } else {
        print('\x1B[31m    [!] Az AppImage letöltése sikertelen.\x1B[0m');
      }
    } else if (Platform.isMacOS) {
      const url = 'https://github.com/CsPS0/pala/releases/latest/download/Pala-macOS.dmg';
      final tempDmg = File('/tmp/Pala-macOS.dmg');
      print('    Letöltés: $url');
      final success = await _downloadFile(url, tempDmg);
      if (success) {
        final mountRes = Process.runSync('hdiutil', ['attach', tempDmg.path, '-nobrowse']);
        if (mountRes.exitCode == 0) {
          Process.runSync('cp', ['-R', '/Volumes/Pala/Pala.app', '/Applications/']);
          Process.runSync('hdiutil', ['detach', '/Volumes/Pala']);
          Process.runSync('xattr', ['-rd', 'com.apple.quarantine', '/Applications/Pala.app']);
          print('\x1B[32m    [OK] Pala.app sikeresen telepítve az /Applications mappába!\x1B[0m');
          try { if (tempDmg.existsSync()) tempDmg.deleteSync(); } catch (_) {}
          return true;
        }
        try { if (tempDmg.existsSync()) tempDmg.deleteSync(); } catch (_) {}
      } else {
        print('\x1B[31m    [!] A Pala DMG letöltése sikertelen.\x1B[0m');
      }
    }
    return false;
  }

  Future<void> _createWindowsShortcut({
    required String target,
    required String shortcutPath,
    required String description,
    String? workingDirectory,
  }) async {
    final workingDir = workingDirectory ?? File(target).parent.path;
    final psCmd = '''
\$ws = New-Object -ComObject WScript.Shell
\$s = \$ws.CreateShortcut('$shortcutPath')
\$s.TargetPath = '$target'
\$s.WorkingDirectory = '$workingDir'
\$s.Description = '$description'
\$s.Save()
''';
    await Process.run('powershell', ['-NoProfile', '-Command', psCmd]);
  }

  Future<void> installStartMenuShortcut() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      final programs = '$appData\\Microsoft\\Windows\\Start Menu\\Programs';
      final progDir = Directory(programs);
      if (!progDir.existsSync()) progDir.createSync(recursive: true);

      final desktopExe = _findInstalledDesktopExe();
      if (desktopExe != null) {
        await _createWindowsShortcut(
          target: desktopExe,
          shortcutPath: '$programs\\Pala Desktop.lnk',
          description: 'Pala Desktop - Modern Kréta Kliens',
        );
        print('\x1B[32m    [OK] Start menü parancsikon létrehozva: Pala Desktop\x1B[0m');
      }

      final currentExe = Platform.resolvedExecutable;
      await _createWindowsShortcut(
        target: currentExe,
        shortcutPath: '$programs\\Pala CLI (Terminál).lnk',
        description: 'Pala CLI & TUI - Kréta Kliens',
      );
      print('\x1B[32m    [OK] Start menü parancsikon létrehozva: Pala CLI (Terminál)\x1B[0m');
    } else if (Platform.isLinux) {
      final appDir = Directory('${Platform.environment['HOME']}/.local/share/applications');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final desktopFile = File('${appDir.path}/pala.desktop');
      final appImagePath = '${Platform.environment['HOME']}/.local/share/pala/Pala.AppImage';
      final execTarget = File(appImagePath).existsSync() ? appImagePath : Platform.resolvedExecutable;
      desktopFile.writeAsStringSync('''[Desktop Entry]
Name=Pala Desktop
Comment=Modern, nyílt forráskódú Kréta kliens
Exec=$execTarget
Icon=pala
Terminal=false
Type=Application
Categories=Education;Utility;
StartupNotify=true
''');
      Process.runSync('chmod', ['+x', desktopFile.path]);
      print('\x1B[32m    [OK] Linux .desktop alkalmazásindító létrehozva: ${desktopFile.path}\x1B[0m');
    } else {
      print('A Start menü / alkalmazásindító parancsikon létrehozása Windows és Linux rendszereken támogatott.');
    }
  }

  Future<void> installDesktopShortcut() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final desktopDir = Directory('$userProfile\\Desktop');
      if (desktopDir.existsSync()) {
        final targetExe = _findInstalledDesktopExe() ?? Platform.resolvedExecutable;
        await _createWindowsShortcut(
          target: targetExe,
          shortcutPath: '${desktopDir.path}\\Pala.lnk',
          description: 'Pala - Modern Kréta Kliens',
        );
        print('\x1B[32m    [OK] Asztali parancsikon létrehozva a munkaasztalon.\x1B[0m');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      final desktopDir = Directory('$home/Desktop');
      if (desktopDir.existsSync()) {
        final appDir = Directory('$home/.local/share/applications');
        final desktopFile = File('${appDir.path}/pala.desktop');
        if (desktopFile.existsSync()) {
          desktopFile.copySync('${desktopDir.path}/pala.desktop');
          Process.runSync('chmod', ['+x', '${desktopDir.path}/pala.desktop']);
          print('\x1B[32m    [OK] Asztali parancsikon létrehozva a munkaasztalon.\x1B[0m');
        }
      }
    }
  }

  Future<void> removeStartMenuShortcut() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      final programs = '$appData\\Microsoft\\Windows\\Start Menu\\Programs';
      final startDeskLink = File('$programs\\Pala Desktop.lnk');
      final startCliLink = File('$programs\\Pala CLI (Terminál).lnk');
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final deskLink = File('$userProfile\\Desktop\\Pala.lnk');
      final deskDeskLink = File('$userProfile\\Desktop\\Pala Desktop.lnk');

      bool removed = false;
      for (final link in [startDeskLink, startCliLink, deskLink, deskDeskLink]) {
        if (link.existsSync()) {
          try {
            link.deleteSync();
            print('\x1B[32m[OK] Parancsikon törölve: ${link.path}\x1B[0m');
            removed = true;
          } catch (_) {}
        }
      }
      if (!removed) {
        print('Nem található eltávolítandó Pala parancsikon a rendszerben.');
      }
    } else if (Platform.isLinux) {
      final desktopFile = File('${Platform.environment['HOME']}/.local/share/applications/pala.desktop');
      final deskLink = File('${Platform.environment['HOME']}/Desktop/pala.desktop');
      bool removed = false;
      if (desktopFile.existsSync()) {
        desktopFile.deleteSync();
        print('\x1B[32m[OK] Linux .desktop bejegyzés törölve.\x1B[0m');
        removed = true;
      }
      if (deskLink.existsSync()) {
        deskLink.deleteSync();
        print('\x1B[32m[OK] Asztali parancsikon törölve.\x1B[0m');
        removed = true;
      }
      if (!removed) {
        print('Nem található eltávolítandó pala.desktop bejegyzés.');
      }
    }
  }

  Future<void> runSetupWizard({bool isFirstRun = false}) async {
    print(PalaTheme.primary);
    print(r'''
=============================================================
 Pala — Telepítő és Beállító Varázsló
=============================================================
''');
    print(PalaTheme.reset);
    print('Használat: Nyilak [Fel/Le], [Szóköz] kijelölés, [Enter] megerősítés\n');

    final desktopInstalled = _findInstalledDesktopExe() != null;
    final desktopLabel = desktopInstalled
        ? 'Pala Desktop (Grafikus Flutter asztali alkalmazás — újratelepítés)'
        : 'Pala Desktop (Grafikus Flutter asztali alkalmazás)';

    final options = [
      desktopLabel,
      'Hozzáadás a felhasználói PATH környezeti változóhoz',
      'Start menü / alkalmazásindító parancsikon létrehozása',
      'Asztali parancsikon létrehozása',
    ];

    final defaults = [
      !desktopInstalled,
      true,
      true,
      false,
    ];

    List<int> selections = [];
    try {
      selections = MultiSelect(
        prompt: 'Válaszd ki a telepítendő / konfigurálandó komponenseket',
        options: options,
        defaults: defaults,
      ).interact();
    } catch (_) {
      print('Válaszd ki a telepítendő komponenseket (I/n):');
      for (int i = 0; i < options.length; i++) {
        final def = defaults[i] ? 'I' : 'n';
        stdout.write('${options[i]} (I/n) [$def]: ');
        final line = stdin.readLineSync()?.trim().toLowerCase();
        if (line == 'i' || line == 'y' || (line == '' && defaults[i])) {
          selections.add(i);
        }
      }
    }

    if (selections.isEmpty) {
      print('\x1B[33mNem választottál ki egyetlen komponenst sem.\x1B[0m\n');
    } else {
      print('\n\x1B[36mBeállítások alkalmazása...\x1B[0m');

      if (selections.contains(0)) {
        await installDesktopApp();
      }
      if (selections.contains(1)) {
        await addToUserPath();
      }
      if (selections.contains(2)) {
        await installStartMenuShortcut();
      }
      if (selections.contains(3)) {
        await installDesktopShortcut();
      }

      print('\x1B[32m\n[OK] A kiválasztott komponensek sikeresen beállítva!\x1B[0m\n');
    }

    AppState.instance.markSetupCompleted();

    if (!isFirstRun) {
      _pause('Nyomj Enter-t a kilépéshez...');
    } else {
      print('\x1B[90mFolytatás az alkalmazás indításához...\x1B[0m\n');
    }
  }

  Future<void> runDesktop() async {
    print('Pala Asztali Alkalmazás indítása...');

    final installedExe = _findInstalledDesktopExe();
    if (installedExe != null) {
      if (Platform.isMacOS && installedExe.endsWith('.app')) {
        print('Asztali alkalmazás indítása: $installedExe');
        await Process.start('open', [installedExe], mode: ProcessStartMode.detached);
      } else {
        print('Asztali alkalmazás indítása: $installedExe');
        await Process.start(installedExe, [], mode: ProcessStartMode.detached);
      }
      return;
    }

    String repoRoot = Directory.current.path;
    String appFolder = 'app';
    if (!Directory('$repoRoot/app').existsSync() && !Directory('$repoRoot/mobile').existsSync()) {
      final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
      if (Directory('$scriptDir/app').existsSync() || Directory('$scriptDir/mobile').existsSync()) {
        repoRoot = scriptDir;
      }
    }
    if (!Directory('$repoRoot/app').existsSync() && Directory('$repoRoot/mobile').existsSync()) {
      appFolder = 'mobile';
    }

    final flutterAppDir = Directory('$repoRoot/$appFolder');
    if (flutterAppDir.existsSync()) {
      final target = Platform.isMacOS ? 'macos' : (Platform.isLinux ? 'linux' : 'windows');
      print('Asztali alkalmazás indítása (flutter run -d $target)...');
      await Process.start('flutter', ['run', '-d', target], workingDirectory: flutterAppDir.path, mode: ProcessStartMode.detached);
      return;
    }

    print('A Pala Desktop még nincs telepítve a gépedre.');
    stdout.write('Szeretnéd most letölteni és telepíteni? (I/n) [I]: ');
    final ans = stdin.readLineSync()?.trim().toLowerCase();
    if (ans == 'i' || ans == 'y' || ans == '') {
      final ok = await installDesktopApp();
      if (ok) {
        final newExe = _findInstalledDesktopExe();
        if (newExe != null) {
          print('Pala Desktop indítása...');
          await Process.start(newExe, [], mode: ProcessStartMode.detached);
          return;
        }
      }
    }
  }

  Future<void> addToUserPath() async {
    final currentExeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      final cmd = '[Environment]::SetEnvironmentVariable("Path", ([Environment]::GetEnvironmentVariable("Path", "User") + ";$currentExeDir"), "User")';
      final res = await Process.run('powershell', ['-Command', cmd]);
      if (res.exitCode == 0) {
        print('\x1B[32m[OK] Sikeresen hozzáadva a felhasználói PATH-hoz: $currentExeDir\x1B[0m');
      } else {
        print('Hiba történt a PATH frissítésekor: ${res.stderr}');
      }
    } else {
      print('A PATH beállításához add hozzá a következőt a ~/.bashrc vagy ~/.zshrc fájlodhoz:');
      print('export PATH="\$PATH:$currentExeDir"');
    }
  }

  Future<void> removeFromUserPath() async {
    final currentExeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      final cmd = '''
\$current = [Environment]::GetEnvironmentVariable("Path", "User");
\$parts = \$current.Split(';') | Where-Object { \$_ -ne "" -and \$_ -ne "$currentExeDir" };
[Environment]::SetEnvironmentVariable("Path", (\$parts -join ';'), "User");
''';
      final res = await Process.run('powershell', ['-Command', cmd]);
      if (res.exitCode == 0) {
        print('\x1B[32m[OK] Sikeresen eltávolítva a felhasználói PATH-ból: $currentExeDir\x1B[0m');
      }
    }
  }

  Future<void> clearCache() async {
    AppState.instance.clearAllData();
    print('\x1B[32m[OK] Helyi gyorsítótár, hitelesítési tokenek és offline adatok sikeresen törölve.\x1B[0m');
  }

  Future<void> uninstallInteractive() async {
    print('=============================================================');
    print(' Pala — Eltávolító és Karbantartó');
    print('=============================================================');
    print('1) Csak parancsikonok eltávolítása (Start menü, Asztal)');
    print('2) Csak a PATH környezeti változó tisztítása');
    print('3) Csak helyi gyorsítótár és bejelentkezések törlése');
    print('4) Teljes eltávolítás (Parancsikonok + PATH + Gyorsítótár)');
    print('5) Mégse');
    stdout.write('\nVálasztásod [1-5]: ');
    final input = stdin.readLineSync()?.trim();

    switch (input) {
      case '1':
        await removeStartMenuShortcut();
        break;
      case '2':
        await removeFromUserPath();
        break;
      case '3':
        await clearCache();
        break;
      case '4':
        await removeStartMenuShortcut();
        await removeFromUserPath();
        await clearCache();
        print('\x1B[32m\nA Pala komponensei sikeresen eltávolítva.\x1B[0m');
        break;
      default:
        print('Művelet megszakítva.');
    }
  }

  List<String> _wrapText(String text, int width) {
    if (text.isEmpty) return [''];
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if ((currentLine + word).length > width) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
          currentLine = '';
        }
        while (word.length > width) {
          lines.add(word.substring(0, width));
          word = word.substring(width);
        }
        currentLine = word + ' ';
      } else {
        currentLine += word + ' ';
      }
    }
    if (currentLine.trim().isNotEmpty) {
      lines.add(currentLine.trim());
    }
    return lines.isNotEmpty ? lines : [''];
  }

  void _pause([String message = 'Nyomj Enter-t a folytatáshoz...']) {
    print('\n\x1B[90m($message)\x1B[0m');
    stdin.readLineSync();
  }
}
