import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interact/interact.dart';
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
    if (isDemo) {
      print('\x1B[1;33m  >>> DEMÓ ÜZEMMÓD: Teszt Elek (Offline) <<<\x1B[0m\n');
    }
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
    if (await _client!.login(username, password)) {
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
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 10, 'label': 'Pala Wrapped (Év végi összefoglaló)', 'key': 'w'},
        {'type': 'action', 'id': 0, 'label': 'Tanulói adatlap'},
        {'type': 'action', 'id': 2, 'label': 'Órarend', 'key': 'o'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 1, 'label': 'Legutóbbi jegyek', 'key': 'g'},
        {'type': 'action', 'id': 4, 'label': 'Tantárgyi átlagok', 'key': 'a'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 3, 'label': 'Mulasztások', 'key': 'm'},
        {'type': 'action', 'id': 5, 'label': 'Számonkérések'},
        {'type': 'action', 'id': 6, 'label': 'Házi feladatok'},
        {'type': 'action', 'id': 7, 'label': 'Üzenetek'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 8, 'label': 'Keresés', 'key': '/'},
        {'type': 'action', 'id': -2, 'label': 'Dashboard (Élő nézet)', 'key': 'd'},
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
        if (displayOptions[i] == '------------------') {
          unselectable.add(i);
        }
      }

      final promptText = isDemo 
          ? 'Pala Főmenü \x1B[1;33m[DEMÓ: Teszt Elek]\x1B[0m \x1B[90m(↑/↓ vagy j/k, [1-9], q: kilépés)\x1B[0m' 
          : (AppState.instance.isOffline 
              ? 'Pala Főmenü \x1B[1;31m[OFFLINE MÓD]\x1B[0m \x1B[90m(↑/↓ vagy j/k, [1-9], q: kilépés)\x1B[0m' 
              : 'Pala Főmenü \x1B[90m(↑/↓ vagy j/k, [1-9], q: kilépés)\x1B[0m');

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
          _clearScreen();
          final List<String> args;
          final String exe;
          if (Platform.resolvedExecutable.endsWith('dart') || Platform.resolvedExecutable.endsWith('dart.exe')) {
            exe = Platform.resolvedExecutable;
            args = [Platform.script.toFilePath(), 'dash'];
          } else {
            exe = Platform.resolvedExecutable;
            args = ['dash'];
          }
          final process = await Process.start(
            exe,
            args,
            mode: ProcessStartMode.inheritStdio,
          );
          await process.exitCode;
          try {
            if (stdin.hasTerminal) {
              stdin.echoMode = true;
              stdin.lineMode = true;
            }
          } catch (_) {}
          forceRestoreConsoleMode();
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

  Future<void> runDesktop() async {
    print('Pala Asztali Alkalmazás indítása...');

    String repoRoot = Directory.current.path;
    if (!Directory('$repoRoot/app').existsSync() && !Directory('$repoRoot/mobile').existsSync()) {
      final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
      if (Directory('$scriptDir/app').existsSync() || Directory('$scriptDir/mobile').existsSync()) {
        repoRoot = scriptDir;
      }
    }

    final appFolder = Directory('$repoRoot/app').existsSync() ? 'app' : 'mobile';

    if (Platform.isWindows) {
      // palapp is the current name; pala_app/pala_mobile are kept as
      // fallbacks so an already-built binary from before the rename still launches.
      for (final buildType in ['Release', 'Debug']) {
        for (final exeName in ['palapp.exe', 'pala_app.exe', 'pala_mobile.exe']) {
          final exe = File('$repoRoot/$appFolder/build/windows/x64/runner/$buildType/$exeName');
          if (exe.existsSync()) {
            print('Asztali alkalmazás indítása: ${exe.path}');
            await Process.start(exe.path, [], mode: ProcessStartMode.detached);
            return;
          }
        }
      }
    } else if (Platform.isLinux) {
      for (final binName in ['palapp', 'pala_app', 'pala_mobile']) {
        final exe = File('$repoRoot/$appFolder/build/linux/x64/release/bundle/$binName');
        if (exe.existsSync()) {
          print('Asztali alkalmazás indítása: ${exe.path}');
          await Process.start(exe.path, [], mode: ProcessStartMode.detached);
          return;
        }
      }
    } else if (Platform.isMacOS) {
      for (final appName in ['palapp.app', 'pala_app.app', 'pala_mobile.app']) {
        final macApp = Directory('$repoRoot/$appFolder/build/macos/Build/Products/Release/$appName');
        if (macApp.existsSync()) {
          print('Asztali alkalmazás indítása: ${macApp.path}');
          await Process.start('open', [macApp.path], mode: ProcessStartMode.detached);
          return;
        }
      }
    }

    final flutterAppDir = Directory('$repoRoot/$appFolder');
    if (flutterAppDir.existsSync()) {
      final target = Platform.isMacOS ? 'macos' : (Platform.isLinux ? 'linux' : 'windows');
      print('Asztali alkalmazás indítása (flutter run -d $target)...');
      await Process.start('flutter', ['run', '-d', target], workingDirectory: flutterAppDir.path, mode: ProcessStartMode.detached);
      return;
    }

    print('Nem található a Pala Desktop futtatható állománya.');
    print('Kérjük, fordítsd le a Flutter asztali alkalmazást az app/ mappában.');
  }

  Future<void> installStartMenuShortcut() async {
    if (Platform.isWindows) {
      String repoRoot = Directory.current.path;
      if (!Directory('$repoRoot/app').existsSync() && !Directory('$repoRoot/mobile').existsSync()) {
        final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
        if (Directory('$scriptDir/app').existsSync() || Directory('$scriptDir/mobile').existsSync()) {
          repoRoot = scriptDir;
        }
      }
      final script = File('$repoRoot/scripts/install_start_menu_shortcut.ps1');
      if (script.existsSync()) {
        final result = await Process.run('pwsh', ['-ExecutionPolicy', 'Bypass', '-File', script.path]);
        if (result.exitCode != 0) {
          final res2 = await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', script.path]);
          stdout.write(res2.stdout);
        } else {
          stdout.write(result.stdout);
        }
      } else {
        print('Nem található a shortcut telepítő parancsfájl.');
      }
    } else if (Platform.isLinux) {
      final appDir = Directory('${Platform.environment['HOME']}/.local/share/applications');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      final desktopFile = File('${appDir.path}/pala.desktop');
      desktopFile.writeAsStringSync('''[Desktop Entry]
Name=Pala Desktop
Comment=Modern, nyílt forráskódú Kréta kliens
Exec=pala --desktop
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Education;Utility;
StartupNotify=true
''');
      print('\x1B[32m[OK] Linux .desktop alkalmazásindító létrehozva: ${desktopFile.path}\x1B[0m');
    } else {
      print('A Start menü / asztali parancsikon létrehozása Windows és Linux rendszereken támogatott.');
    }
  }

  Future<void> removeStartMenuShortcut() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      final programs = '$appData\\Microsoft\\Windows\\Start Menu\\Programs';
      final startLink = File('$programs\\Pala Desktop.lnk');
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      final deskLink = File('$userProfile\\Desktop\\Pala Desktop.lnk');

      bool removed = false;
      if (startLink.existsSync()) {
        startLink.deleteSync();
        print('\x1B[32m[OK] Start menü parancsikon törölve.\x1B[0m');
        removed = true;
      }
      if (deskLink.existsSync()) {
        deskLink.deleteSync();
        print('\x1B[32m[OK] Asztali parancsikon törölve.\x1B[0m');
        removed = true;
      }
      if (!removed) {
        print('Nem található eltávolítandó Pala parancsikon a Start menüben.');
      }
    } else if (Platform.isLinux) {
      final desktopFile = File('${Platform.environment['HOME']}/.local/share/applications/pala.desktop');
      if (desktopFile.existsSync()) {
        desktopFile.deleteSync();
        print('\x1B[32m[OK] Linux .desktop bejegyzés törölve.\x1B[0m');
      } else {
        print('Nem található eltávolítandó pala.desktop bejegyzés.');
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
