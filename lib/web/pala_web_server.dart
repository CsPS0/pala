import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pala/api/client.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';
import 'package:pala/utils/logger.dart';
import 'pala_web_html.dart';

class PalaWebServer {
  KretaClient? client;
  HttpServer? _server;
  late final String sessionToken;

  PalaWebServer({this.client}) {
    sessionToken = base64Url.encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)));
  }

  Future<int?> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    } catch (e) {
      PalaLogger.debug('Failed to bind PalaWebServer: $e');
      return null;
    }

    final port = _server!.port;
    _server!.listen(_handleRequest);
    return port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String getUrl(int port) => 'http://127.0.0.1:$port/?token=$sessionToken';

  static void openBrowser(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('powershell', ['-NoProfile', '-Command', 'Start-Process', '"$url"']);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      }
    } catch (e) {
      PalaLogger.debug('Failed to open browser: $e');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // 1. Static HTML page (Allow initial page load, which embeds the session token into JS)
    if (request.method == 'GET' && (path == '/' || path == '/index.html')) {
      final student = await client?.getStudentData(silent: true);
      final isDemo = client is DemoKretaClient;
      final html = PalaWebHtml.render(
        studentName: student?.name ?? (client == null ? 'Nincs bejelentkezve' : 'Diák'),
        institutionName: student?.institutionName ?? (client == null ? 'Kérlek jelentkezz be' : 'Oktatási Intézmény'),
        sessionToken: sessionToken,
        port: _server!.port,
        isAuthenticated: client != null,
        isDemo: isDemo,
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set('X-Frame-Options', 'DENY')
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..write(html);
      await request.response.close();
      return;
    }

    // 2. Token check on all API routes (/api/*)
    final reqToken = request.headers.value('x-pala-token') ?? request.uri.queryParameters['token'];
    if (reqToken != sessionToken) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Invalid session token'}));
      await request.response.close();
      return;
    }

    // 3. API Routes
    if (request.method == 'GET' && path == '/api/student') {
      if (client == null) {
        _sendJson(request, {
          'authenticated': false,
          'name': 'Nincs bejelentkezve',
          'institutionName': 'Kérlek jelentkezz be a fiókodba',
        });
        return;
      }
      final student = await client!.getStudentData(silent: true);
      _sendJson(request, {
        'authenticated': true,
        'isDemo': client is DemoKretaClient,
        'name': student?.name ?? 'Diák',
        'institutionName': student?.institutionName ?? 'Oktatási Intézmény',
        'uid': student?.uid ?? '',
        'birthName': student?.birthName ?? '',
        'birthPlace': student?.birthPlace ?? '',
        'mothersName': student?.mothersName ?? '',
        'birthDate': student?.birthDate ?? '',
        'email': student?.email ?? '',
        'phone': student?.phone ?? '',
        'addresses': student?.addresses ?? [],
        'guardians': student?.guardians.map((g) => {
          'name': g['Nev'] ?? g['name'] ?? '',
          'email': g['EmailCim'] ?? g['email'] ?? '',
          'phone': g['Telefonszam'] ?? g['phone'] ?? '',
          'type': (g['Tipus'] is Map ? g['Tipus']['Nev'] : g['Tipus']) ?? g['type'] ?? 'Gondviselő',
        }).toList() ?? [],
        'nextDowntime': student?.nextDowntime?.toIso8601String(),
      });
    } else if (request.method == 'GET' && path == '/api/schools') {
      final query = request.uri.queryParameters['q'] ?? '';
      final schools = await KretaClient.searchSchools(query);
      _sendJson(request, schools);
    } else if (request.method == 'POST' && path == '/api/login') {
      try {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final isDemo = data['isDemo'] == true;

        if (isDemo) {
          client = DemoKretaClient();
          _sendJson(request, {'success': true, 'name': 'Teszt Elek (Demó)'});
          return;
        }

        final instituteCode = (data['instituteCode'] ?? '').toString().trim();
        final username = (data['username'] ?? '').toString().trim();
        final password = (data['password'] ?? '').toString().trim();

        if (instituteCode.isEmpty || username.isEmpty || password.isEmpty) {
          _sendError(request, HttpStatus.badRequest, 'Minden mező kitöltése kötelező!');
          return;
        }

        final newClient = KretaClient(instituteCode: instituteCode);
        final ok = await newClient.login(username, password);
        if (ok) {
          client = newClient;
          final student = await client!.getStudentData(silent: true);
          _saveWebAuth(student?.name ?? username, instituteCode, newClient.accessToken, newClient.refreshToken);
          _sendJson(request, {'success': true, 'name': student?.name ?? username});
        } else {
          _sendError(request, HttpStatus.unauthorized, 'Hibás felhasználónév vagy jelszó!');
        }
      } catch (e) {
        PalaLogger.debug('Web login error: $e');
        _sendError(request, HttpStatus.internalServerError, 'Hiba a bejelentkezés során: $e');
      }
    } else if (request.method == 'POST' && path == '/api/logout') {
      client = null;
      _sendJson(request, {'success': true});
    } else if (request.method == 'GET' && path == '/api/settings') {
      _sendJson(request, {
        'parentalQuota': AppState.instance.parentalQuota,
        'aliases': AppState.instance.getAliases(),
        'showAsciiBanner': AppState.instance.showAsciiBanner,
        'theme': AppState.instance.theme,
      });
    } else if (request.method == 'POST' && path == '/api/settings') {
      try {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (data.containsKey('parentalQuota')) {
          final q = int.tryParse(data['parentalQuota'].toString()) ?? 5;
          AppState.instance.setParentalQuota(q);
        }
        if (data.containsKey('showAsciiBanner')) {
          AppState.instance.setShowAsciiBanner(data['showAsciiBanner'] == true);
        }
        if (data.containsKey('theme')) {
          AppState.instance.setTheme(data['theme'].toString());
        }
        _sendJson(request, {'success': true});
      } catch (e) {
        _sendError(request, HttpStatus.internalServerError, e.toString());
      }
    } else if (request.method == 'POST' && path == '/api/aliases') {
      try {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final original = (data['original'] ?? '').toString().trim();
        final alias = (data['alias'] ?? '').toString().trim();
        if (original.isNotEmpty && alias.isNotEmpty) {
          AppState.instance.setAlias(original, alias);
          _sendJson(request, {'success': true, 'aliases': AppState.instance.getAliases()});
        } else {
          _sendError(request, HttpStatus.badRequest, 'Hiányzó mezők');
        }
      } catch (e) {
        _sendError(request, HttpStatus.internalServerError, e.toString());
      }
    } else if (request.method == 'POST' && path == '/api/delete-alias') {
      try {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final original = (data['original'] ?? '').toString().trim();
        if (original.isNotEmpty) {
          AppState.instance.removeAlias(original);
          _sendJson(request, {'success': true, 'aliases': AppState.instance.getAliases()});
        } else {
          _sendError(request, HttpStatus.badRequest, 'Hiányzó mező');
        }
      } catch (e) {
        _sendError(request, HttpStatus.internalServerError, e.toString());
      }
    } else if (request.method == 'GET' && path == '/api/grades') {
      final grades = await client?.getGrades() ?? [];
      final list = grades.map((g) => {
        'subject': AppState.instance.applyAlias(g.subject),
        'numericValue': g.numericValue,
        'textValue': g.textValue,
        'weight': g.weight,
        'date': g.date?.toIso8601String(),
        'type': g.type,
        'theme': g.theme,
        'teacherName': g.teacherName,
      }).toList();
      _sendJson(request, {'grades': list});
    } else if (request.method == 'GET' && path == '/api/timetable') {
      final weekOffsetStr = request.uri.queryParameters['weekOffset'] ?? '0';
      final weekOffset = int.tryParse(weekOffsetStr) ?? 0;

      final now = DateTime.now().add(Duration(days: weekOffset * 7));
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
      final friday = monday.add(const Duration(days: 4));
      final end = DateTime(friday.year, friday.month, friday.day, 23, 59, 59);

      final timetable = await client?.getTimetable(start, end) ?? [];
      final list = timetable.map((l) => {
        'subject': AppState.instance.applyAlias(l.subject),
        'lessonNumber': l.lessonNumber,
        'startTime': l.startTime?.toIso8601String(),
        'endTime': l.endTime?.toIso8601String(),
        'room': l.room,
        'teacherName': l.teacher ?? l.substituteTeacher ?? '',
        'isCancelled': l.isCancelled,
        'deputyTeacherName': l.substituteTeacher ?? '',
      }).toList();
      _sendJson(request, {'lessons': list, 'startDate': start.toIso8601String(), 'endDate': end.toIso8601String()});
    } else if (request.method == 'GET' && path == '/api/homework') {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final homework = await client?.getHomework(start: start) ?? [];
      final list = homework.map((h) => {
        'subject': AppState.instance.applyAlias(h.subject),
        'text': h.text,
        'deadline': h.deadline?.toIso8601String(),
        'date': h.assignedDate?.toIso8601String(),
        'uid': h.uid,
      }).toList();
      _sendJson(request, list);
    } else if (request.method == 'GET' && path == '/api/exams') {
      final exams = await client?.getExams() ?? [];
      final list = exams.map((e) => {
        'subject': AppState.instance.applyAlias(e.subject),
        'date': e.date?.toIso8601String(),
        'mode': e.mode,
        'theme': e.theme,
      }).toList();
      _sendJson(request, list);
    } else if (request.method == 'GET' && path == '/api/messages') {
      final messages = await client?.getMessages() ?? [];
      final list = messages.map((m) => {
        'sender': m.senderName,
        'subject': m.subject,
        'text': m.text,
        'date': m.sentDate?.toIso8601String(),
        'attachments': m.attachments.map((a) => {'id': a.id, 'name': a.name}).toList(),
      }).toList();
      _sendJson(request, list);
    } else if (request.method == 'GET' && path == '/api/absences') {
      final absences = await client?.getAbsences() ?? [];
      final quota = AppState.instance.parentalQuota;

      // Group parental excused days
      final Set<String> parentalDates = {};
      for (var a in absences) {
        final t = (a.type ?? '').toLowerCase();
        final s = a.status.toLowerCase();
        if (t.contains('szülő') || t.contains('gondviselő') || s.contains('szülő') || s.contains('gondviselő')) {
          final dateStr = a.date?.toString().split(' ').first.split('T').first ?? '';
          if (dateStr.isNotEmpty) parentalDates.add(dateStr);
        }
      }

      final list = absences.map((a) => {
        'subject': AppState.instance.applyAlias(a.subject),
        'date': a.date?.toIso8601String(),
        'status': a.status,
        'type': a.type,
        'delayMinutes': a.delayMinutes,
      }).toList();

      _sendJson(request, {
        'absences': list,
        'parentalQuota': quota,
        'usedParentalDays': parentalDates.length,
      });
    } else if (request.method == 'GET' && path == '/api/teachers') {
      final teachers = await client?.getTeachers() ?? [];
      _sendJson(request, teachers);
    } else if (request.method == 'POST' && path == '/api/send-message') {
      if (client == null) {
        _sendError(request, HttpStatus.unauthorized, 'Nincs bejelentkezett fiók');
        return;
      }
      try {
        final content = await utf8.decodeStream(request);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subject = (data['subject'] ?? '').toString().trim();
        final text = (data['text'] ?? '').toString().trim();
        final recipientIds = (data['recipientIds'] as List? ?? [])
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();

        if (subject.isNotEmpty && text.isNotEmpty && recipientIds.isNotEmpty) {
          final success = await client!.sendMessage(
            subject: subject,
            text: text,
            recipientIds: recipientIds,
          );
          _sendJson(request, {'success': success});
        } else {
          _sendError(request, HttpStatus.badRequest, 'Hiányzó mezők');
        }
      } catch (e) {
        _sendError(request, HttpStatus.internalServerError, e.toString());
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    }
  }

  void _saveWebAuth(String profileName, String instituteCode, String? accessToken, String? refreshToken) {
    if (accessToken == null) return;
    try {
      final authFile = AppState.instance.authFile;
      Map<String, dynamic> root = {'activeProfileIndex': 0, 'profiles': []};
      if (authFile.existsSync()) {
        try {
          final content = authFile.readAsStringSync();
          if (content.trim().startsWith('{')) {
            final data = jsonDecode(content);
            if (data is Map<String, dynamic> && data.containsKey('profiles')) root = data;
          } else {
            final decrypted = EncryptionUtil.decrypt(content);
            final data = jsonDecode(decrypted);
            if (data is Map<String, dynamic> && data.containsKey('profiles')) root = data;
          }
        } catch (_) {}
      }
      List profiles = root['profiles'];
      int existingIdx = -1;
      for (int i = 0; i < profiles.length; i++) {
        if (profiles[i]['name'] == profileName && profiles[i]['instituteCode'] == instituteCode) {
          existingIdx = i;
          break;
        }
      }
      final newProfile = {
        'name': profileName,
        'instituteCode': instituteCode,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
      if (existingIdx != -1) {
        profiles[existingIdx] = newProfile;
        root['activeProfileIndex'] = existingIdx;
      } else {
        profiles.add(newProfile);
        root['activeProfileIndex'] = profiles.length - 1;
      }
      authFile.writeAsStringSync(EncryptionUtil.encrypt(jsonEncode(root)));
    } catch (e) {
      PalaLogger.debug('Failed to save web auth: $e');
    }
  }

  Future<void> _sendJson(HttpRequest request, dynamic data) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..write(jsonEncode(data));
    await request.response.close();
  }

  Future<void> _sendError(HttpRequest request, int code, String message) async {
    request.response
      ..statusCode = code
      ..headers.contentType = ContentType.json
      ..headers.set('X-Content-Type-Options', 'nosniff')
      ..write(jsonEncode({'error': message}));
    await request.response.close();
  }

  static Future<void> runInteractive({
    KretaClient? client,
    bool openInBrowser = true,
  }) async {
    final server = PalaWebServer(client: client);
    final port = await server.start();
    if (port == null) {
      print('Hiba: Nem sikerült elindítani a helyi webszervert.');
      return;
    }

    final url = server.getUrl(port);
    if (openInBrowser) {
      openBrowser(url);
    }

    final student = await client?.getStudentData(silent: true);
    final studentName = student?.name ?? (client == null ? 'Nincs bejelentkezve' : 'Diák');
    final instName = student?.institutionName ?? (client == null ? 'Kérlek jelentkezz be a böngészőben' : 'Oktatási Intézmény');

    stdout.write('\x1B[2J\x1B[3J\x1B[H');
    print('================================================================================');
    print('                          PALA WEB DASHBOARD');
    print('================================================================================');
    print('Szerver állapota:   \x1B[1;32mFUT (127.0.0.1:$port)\x1B[0m');
    print('Böngésző URL:       \x1B[1;36m$url\x1B[0m');
    print('Aktív profil:       \x1B[1m$studentName\x1B[0m ($instName)');
    print('Biztonsági védelem: \x1B[1;32m[AKTÍV] (Egyedi session token)\x1B[0m\n');
    print('A grafikus felület megnyílt a böngésződben.');
    print('A szerver leállításához és a visszatéréshez nyomj \x1B[1m[Q]\x1B[0m billentyűt vagy \x1B[1m[Ctrl+C]\x1B[0m-t.');
    print('================================================================================\n');

    final completer = Completer<void>();

    StreamSubscription? stdinSub;
    try {
      if (stdin.hasTerminal) {
        stdin.lineMode = false;
        stdin.echoMode = false;
      }
      stdinSub = stdin.listen((List<int> bytes) {
        final char = String.fromCharCodes(bytes).toLowerCase();
        if (char.contains('q') || bytes.contains(3) /* Ctrl+C */ || bytes.contains(27) /* Esc */) {
          if (!completer.isCompleted) completer.complete();
        }
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete();
      }, onDone: () {
        if (!completer.isCompleted) completer.complete();
      });
    } catch (_) {
      stdinSub = stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        final l = line.trim().toLowerCase();
        if (l == 'q' || l == 'quit' || l == 'exit') {
          if (!completer.isCompleted) completer.complete();
        }
      });
    }

    StreamSubscription? sigSub;
    try {
      sigSub = ProcessSignal.sigint.watch().listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
    } catch (_) {}

    await completer.future;

    await stdinSub.cancel();
    if (sigSub != null) {
      await sigSub.cancel();
    }

    try {
      if (stdin.hasTerminal) {
        stdin.lineMode = true;
        stdin.echoMode = true;
      }
    } catch (_) {}

    print('\nWebszerver leállítása...');
    await server.stop();
    print('\x1B[1;32m[OK] Webszerver sikeresen leállítva.\x1B[0m\n');
  }
}
