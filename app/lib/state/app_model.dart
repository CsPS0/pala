import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pala/api/api.dart';
import 'package:pala/api/client.dart';
import 'package:pala/rules/absence_rules.dart';
import 'package:pala/rules/grade_rules.dart';
import 'package:pala/utils/csv.dart';
import 'package:pala/utils/html_text.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/models/absence.dart';
import 'package:pala/models/class_average.dart';
import 'package:pala/models/exam.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/models/homework.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/note.dart';
import 'package:pala/models/student.dart';
import 'package:pala/models/timetable_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../notifications/background_check.dart';
import '../notifications/notification_service.dart';
import '../theme/pala_theme.dart';
import 'session_store.dart';
import 'package:pala/utils/pala_clock.dart';

class AppModel extends ChangeNotifier {
  KretaClient? _client;
  bool _isDemo = false;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = true;

  Student? _student;
  List<Grade> _grades = [];
  List<TimetableEntry> _timetable = [];
  List<Homework> _homework = [];
  List<Exam> _exams = [];
  List<Message> _messages = [];
  List<Absence> _absences = [];
  List<Note> _notes = [];
  List<dynamic> _groupAverages = [];
  List<Map<String, dynamic>> _teachers = [];

  int _parentalQuota = 5;
  Map<String, String> _aliases = {};
  Set<String> _completedHomework = {};
  int _weekOffset = 0;
  bool? _overrideAWeek;
  String? _weekType;
  bool _showWeekType = true;

  // Getters
  KretaClient? get client => _client;
  bool get isDemo => _isDemo;
  bool get isMaintenanceMode => _client?.isMaintenanceMode ?? false;
  int? get maintenanceStatusCode => _client?.maintenanceStatusCode;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDarkMode => _isDarkMode;

  Student? get student => _student;
  List<Grade> get grades => _grades;
  List<TimetableEntry> get timetable => _timetable;
  List<Homework> get homework => _homework;
  List<Exam> get exams => _exams;
  List<Message> get messages => _messages;
  List<Absence> get absences => _absences;
  List<Note> get notes => _notes;
  List<dynamic> get groupAverages => _groupAverages;
  List<Map<String, dynamic>> get teachers => _teachers;

  int get parentalQuota => _parentalQuota;
  Map<String, String> get aliases => _aliases;
  Set<String> get completedHomework => _completedHomework;
  int get weekOffset => _weekOffset;
  bool? get overrideAWeek => _overrideAWeek;

  /// The school's name for the shown week ("A hét", "C hét", ...), or null when
  /// the school has no rotation or Kréta didn't say. Only then show a badge.
  /// Kréta labels weeks per school, not per class, so a class without a
  /// rotation at an A/B school can turn the badge off.
  String? get weekType => _showWeekType ? _weekType : null;
  bool get showWeekType => _showWeekType;

  DateTime get currentWeekMonday {
    // Calendar arithmetic: a Duration step drifts an hour across DST changes.
    final now = PalaClock.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1) + _weekOffset * 7);
  }

  int get currentWeekNumber {
    final d = currentWeekMonday;
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstThursdayOfWeek1 = firstThursday.add(Duration(days: 4 - firstThursday.weekday));
    return 1 + ((thursday.difference(firstThursdayOfWeek1).inDays) / 7).round();
  }

  AppModel() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('pala_dark_mode') ?? true;
    PalaTheme.isLight = !_isDarkMode;
    _showWeekType = prefs.getBool('pala_show_week_type') ?? true;
    _parentalQuota = prefs.getInt('pala_parental_quota') ?? 5;
    
    final aliasStr = prefs.getString('pala_aliases');
    if (aliasStr != null) {
      try {
        final decoded = jsonDecode(aliasStr) as Map<String, dynamic>;
        _aliases = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    final hwList = prefs.getStringList('pala_completed_hw') ?? [];
    _completedHomework = hwList.toSet();

    // Restore cached student info if available
    final cachedStudent = prefs.getString('pala_cached_student');
    if (cachedStudent != null) {
      try {
        _student = Student.fromJson(jsonDecode(cachedStudent));
      } catch (_) {}
    }

    notifyListeners();

    await _tryRestoreSession();
  }

  /// Restores a previously saved login (see [SessionStore]) so the user
  /// isn't dropped back to the login screen on every cold start. Tokens are
  /// trusted optimistically — if they turned out to be dead, individual
  /// [refreshAll] fetches just come back empty/null the same way they
  /// already do for any other request failure, instead of forcing a logout
  /// on what might just be a network blip.
  Future<void> _tryRestoreSession() async {
    final session = await SessionStore.load();
    if (session == null) return;

    final kClient = KretaClient(instituteCode: session['instituteCode']!);
    kClient.accessToken = session['accessToken'];
    kClient.refreshToken = session['refreshToken'];
    SessionStore.attach(kClient);

    _client = kClient;
    _isDemo = false;
    _isAuthenticated = true;
    notifyListeners();

    await refreshAll();
    unawaited(_enableBackgroundNotifications());
  }

  /// Registers the Android background sync (see notifications/background_check.dart)
  /// and asks for the notification permission. Android-only: iOS background
  /// execution is too unreliable to promise "even when closed" notifications,
  /// and desktop already gets them from the CLI daemon.
  Future<void> _enableBackgroundNotifications() async {
    if (!Platform.isAndroid) return;
    await NotificationService.instance.requestPermission();
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      backgroundTaskUniqueName,
      backgroundTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Password login. Throws [InteractiveLoginRequired] when the account has
  /// captcha or two-factor login; the view then sends the user to Kréta's
  /// own page and finishes with [loginWithCode].
  Future<bool> login({
    required String instituteCode,
    required String username,
    required String password,
  }) =>
      _loginWith(instituteCode, (c) => c.login(username, password),
          'Nem sikerült bejelentkezni. Ellenőrizd az adataidat!');

  /// Finishes a login done on Kréta's own page (redirect URL or bare code).
  Future<bool> loginWithCode({
    required String instituteCode,
    required String code,
  }) =>
      _loginWith(instituteCode, (c) => c.webLogin(code),
          'A kód érvénytelen vagy lejárt. Jelentkezz be újra a Kréta oldalán!');

  Future<bool> _loginWith(
    String instituteCode,
    Future<bool> Function(KretaClient client) authenticate,
    String failureMessage,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final code = instituteCode.trim().toLowerCase();
      if (!BaseKreta.isValidInstituteCode(code)) {
        throw Exception('Érvénytelen intézménykód. Csak kisbetű, szám és kötőjel lehet benne.');
      }
      final kClient = KretaClient(instituteCode: code);
      final loggedIn = await authenticate(kClient);
      if (!loggedIn) {
        throw Exception(failureMessage);
      }
      SessionStore.attach(kClient);
      _client = kClient;
      _isDemo = false;
      _isAuthenticated = true;
      _isLoading = false;
      await SessionStore.save(kClient);
      await refreshAll();
      unawaited(_enableBackgroundNotifications());
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      if (e is InteractiveLoginRequired) rethrow;
      return false;
    }
  }

  Future<void> loginDemo() async {
    _isLoading = true;
    _errorMessage = null;
    _student = null;
    _grades = [];
    _timetable = [];
    _homework = [];
    _exams = [];
    _messages = [];
    _absences = [];
    _notes = [];
    _groupAverages = [];
    _teachers = [];
    _completedHomework = {};
    _aliases = {};
    _weekOffset = 0;
    _overrideAWeek = null;
    _weekType = null;
    notifyListeners();

    try {
      _client = DemoKretaClient();
      _isDemo = true;
      _isAuthenticated = true;
      _isLoading = false;
      await refreshAll();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Best effort: a revoked refresh token cannot be reused from a copied session.
    await _client?.revokeToken().timeout(const Duration(seconds: 5), onTimeout: () => false);
    await SessionStore.clear();
    await clearLocalCache();
    _client = null;
    _isAuthenticated = false;
    _isDemo = false;
    _student = null;
    _grades = [];
    _timetable = [];
    _homework = [];
    _exams = [];
    _messages = [];
    _absences = [];
    _notes = [];
    _groupAverages = [];
    _teachers = [];
    _completedHomework = {};
    _aliases = {};
    _weekOffset = 0;
    _overrideAWeek = null;
    _weekType = null;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_client == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _client!.getStudentData(),
        _client!.getGrades(),
        _fetchTimetableForOffset(_weekOffset),
        _client!.getHomework(),
        _client!.getExams(),
        _client!.getMessages(),
        _client!.getAbsences(),
        _client!.getGroupAverages(),
        _client!.getTeachers(),
        _client!.getNotes(),
        _fetchWeekType(),
      ]);

      // TanuloAdatlap has no class name; the client learnt it from the class groups.
      _student = (futures[0] as Student?)?.withClassName(_client!.className);
      _grades = (futures[1] as List<Grade>?) ?? [];
      _timetable = (futures[2] as List<TimetableEntry>?) ?? [];
      _homework = (futures[3] as List<Homework>?) ?? [];
      _exams = (futures[4] as List<Exam>?) ?? [];
      _messages = (futures[5] as List<Message>?) ?? [];
      _absences = (futures[6] as List<Absence>?) ?? [];
      _groupAverages = (futures[7] as List<dynamic>?) ?? [];
      _teachers = (futures[8] as List<Map<String, dynamic>>?) ?? [];
      _notes = (futures[9] as List<Note>?) ?? [];
      _weekType = futures[10] as String?;
      // The client answers from its disk cache when Kréta is unreachable.
      _errorMessage = (!_isDemo && _client!.isNetworkDown)
          ? 'Nincs kapcsolat a Krétával, a legutóbb mentett adatokat látod.'
          : null;
    } catch (e) {
      _errorMessage = 'Hiba az adatok lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Kréta rejected the saved login itself (not a network error): say so on
    // the login screen instead of silently showing empty data.
    if (!_isDemo && (_client?.sessionExpired ?? false)) {
      _errorMessage = 'A Kréta bejelentkezés lejárt, kérlek jelentkezz be újra.';
      await logout();
    }
  }

  /// Kréta ID of the teacher named [name], or null when the name does not
  /// match an addressable teacher. Never guess an ID: a wrong one sends the
  /// message to someone else.
  int? teacherIdFor(String name) {
    for (final t in _teachers) {
      final tName = (t['Nev'] ?? t['nev'] ?? t['name'])?.toString();
      if (tName == name) {
        final id = t['Azonosito'] ?? t['azonosito'] ?? t['id'] ?? t['Id'];
        if (id is int) return id;
        return id == null ? null : int.tryParse(id.toString());
      }
    }
    return null;
  }

  Future<bool> sendMessage({
    required String recipientName,
    required String subject,
    required String messageText,
  }) async {
    if (_client == null) return false;
    try {
      final teacherId = teacherIdFor(recipientName);
      if (teacherId == null) {
        _errorMessage = 'Ismeretlen címzett: válassz egy tanárt a listából.';
        notifyListeners();
        return false;
      }

      return await _client!.sendMessage(
        subject: subject,
        text: messageText,
        recipientIds: [teacherId],
      );
    } catch (e) {
      _errorMessage = 'Hiba az üzenetküldés során: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<TimetableEntry>> _fetchTimetableForOffset(int offset) async {
    if (_client == null) return [];
    final now = PalaClock.now();
    final start = DateTime(now.year, now.month, now.day - (now.weekday - 1) + offset * 7);
    final end = DateTime(start.year, start.month, start.day + 4, 23, 59, 59);

    final entries = await _client!.getTimetable(start, end, overrideAWeek: _overrideAWeek);
    return entries ?? [];
  }

  Future<String?> _fetchWeekType() async {
    final m = currentWeekMonday;
    return _client?.getWeekType(DateTime(m.year, m.month, m.day), overrideAWeek: _overrideAWeek);
  }

  Future<void> setWeekOffset(int offset) async {
    _weekOffset = offset;
    _overrideAWeek = null;
    _isLoading = true;
    notifyListeners();
    try {
      _timetable = await _fetchTimetableForOffset(offset);
      _weekType = await _fetchWeekType();
    } catch (e) {
      _errorMessage = 'Hiba az órarend betöltésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Demo only: flips the demo school's A/B week to preview both timetables.
  /// Real weeks come from Kréta, so there is nothing to toggle there.
  Future<void> toggleABWeek() async {
    if (!_isDemo) return;
    _overrideAWeek = _weekType != 'A hét';
    _timetable = await _fetchTimetableForOffset(_weekOffset);
    _weekType = await _fetchWeekType();
    notifyListeners();
  }

  void toggleHomework(String hwId) async {
    if (_completedHomework.contains(hwId)) {
      _completedHomework.remove(hwId);
    } else {
      _completedHomework.add(hwId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pala_completed_hw', _completedHomework.toList());
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    PalaTheme.isLight = !isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pala_dark_mode', isDark);
  }

  Future<void> setShowWeekType(bool show) async {
    _showWeekType = show;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pala_show_week_type', show);
  }

  Future<void> setParentalQuota(int quota) async {
    _parentalQuota = quota;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pala_parental_quota', quota);
  }

  Future<void> setAlias(String original, String custom) async {
    _aliases[original] = custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pala_aliases', jsonEncode(_aliases));
  }

  Future<void> removeAlias(String original) async {
    _aliases.remove(original);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pala_aliases', jsonEncode(_aliases));
  }

  String getDisplaySubject(String original) {
    return _aliases[original] ?? original;
  }

  /// A message's full text as plain text. The list may carry only part of
  /// it, so an empty body is fetched from e-Ügyintézés.
  Future<String> messageText(Message m) async {
    if (m.text.trim().isNotEmpty) return htmlToText(m.text);
    if (_isDemo || _client == null) return '';
    return htmlToText(await _client!.getMessageContent(m.id));
  }

  /// Saves an attachment into the user's Downloads folder (desktop only).
  Future<bool> downloadAttachment(MessageAttachment a) async {
    if (_isDemo || _client == null) return false;
    return _client!.downloadAttachment(a.id, a.name);
  }

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pala_cached_student');
    await prefs.remove('pala_completed_hw');
    _completedHomework = {};
    notifyListeners();
  }

  // --- Calculated Statistics ---

  // Averages and absence counts follow the shared rules in package:pala/rules
  // (docs/DEV.md, "Számítási szabályok"), the same as the TUI and the extension.

  /// The mean of the subject averages, as on a certificate.
  double get overallGpa => GradeRules.overallAverage(_grades, subjectOf: (g) => getDisplaySubject(g.subject)) ?? 0.0;

  Map<String, double> get subjectAverages =>
      GradeRules.subjectAverages(_grades, subjectOf: (g) => getDisplaySubject(g.subject));

  Map<String, double> get groupAveragesMap {
    final map = <String, double>{};
    for (final item in _groupAverages) {
      if (item is Map) {
        final sub = item['Tantargy']?['Nev']?.toString();
        final val = classAverageOf(item);
        if (sub != null && val != null) map[getDisplaySubject(sub)] = val;
      }
    }
    return map;
  }

  // Absence breakdown
  AbsenceSummary get _absenceSummary => AbsenceRules.summarize(_absences);

  int get totalMissedHours => _absenceSummary.missed;

  // Status classifiers shared by the counters and the absences list filter.
  // Late arrivals are not missed hours and match none of them.
  static bool isJustified(Absence a) => !AbsenceRules.isLateness(a) && AbsenceRules.status(a) == AbsenceStatus.excused;

  static bool isUnjustified(Absence a) => !AbsenceRules.isLateness(a) && AbsenceRules.status(a) == AbsenceStatus.unexcused;

  static bool isPending(Absence a) => !AbsenceRules.isLateness(a) && AbsenceRules.status(a) == AbsenceStatus.pending;

  int get justifiedHours => _absenceSummary.excused;

  int get unjustifiedHours => _absenceSummary.unexcused;

  int get pendingHours => _absenceSummary.pending;

  int get totalDelayMinutes => _absenceSummary.lateMinutes;

  int get usedParentalDays {
    final parentAbsences = _absences.where((a) {
      final t = a.type?.toLowerCase() ?? '';
      final s = a.status.toLowerCase();
      return t.contains('szuloi') || t.contains('szülői') || s.contains('szuloi') || s.contains('szülői');
    }).toList();
    final dates = parentAbsences.where((a) => a.date != null).map((a) => a.date!.toIso8601String().split('T')[0]).toSet();
    return dates.length;
  }

  // Absences by subject (for Danger Zone)
  Map<String, int> get absencesBySubject {
    final map = <String, int>{};
    for (final a in _absences) {
      if (a.type?.toLowerCase() != 'késés') {
        final sub = getDisplaySubject(a.subject);
        map[sub] = (map[sub] ?? 0) + 1;
      }
    }
    return map;
  }

  // Pala Wrapped Stats
  Map<String, dynamic> get wrappedStats {
    final subAvgs = subjectAverages;
    String bestSubj = '-';
    double bestSubjAvg = 0;
    String worstSubj = '-';
    double worstSubjAvg = 6;

    for (final e in subAvgs.entries) {
      if (e.value > bestSubjAvg) {
        bestSubjAvg = e.value;
        bestSubj = e.key;
      }
      if (e.value < worstSubjAvg) {
        worstSubjAvg = e.value;
        worstSubj = e.key;
      }
    }

    final fivesCount = _grades.where((g) => g.numericValue == 5).length;
    final onesCount = _grades.where((g) => g.numericValue == 1).length;

    // Monthly breakdown
    final Map<int, int> gradesByMonth = {};
    for (final g in _grades) {
      if (g.date != null) {
        gradesByMonth[g.date!.month] = (gradesByMonth[g.date!.month] ?? 0) + 1;
      }
    }
    int topMonth = 1;
    int topMonthCount = 0;
    for (final m in gradesByMonth.entries) {
      if (m.value > topMonthCount) {
        topMonthCount = m.value;
        topMonth = m.key;
      }
    }

    return {
      'totalGrades': _grades.length,
      'fivesCount': fivesCount,
      'onesCount': onesCount,
      'overallGpa': overallGpa,
      'bestSubject': bestSubj,
      'bestSubjectAvg': bestSubjAvg,
      'worstSubject': worstSubj,
      'worstSubjectAvg': worstSubjAvg < 6 ? worstSubjAvg : 0.0,
      'totalMissedHours': totalMissedHours,
      'topMonth': topMonth,
      'topMonthCount': topMonthCount,
    };
  }

  // CSV Exports
  // Both in the shared CSV format (package:pala/utils/csv.dart), with local dates.
  String exportGradesCsv() => toCsv(
        ['Tantárgy', 'Érték', 'Súly', 'Dátum', 'Téma', 'Tanár'],
        _grades.map((g) => [
              getDisplaySubject(g.subject),
              g.displayValue,
              '${g.weight.toInt()}%',
              csvDate(g.date),
              g.theme ?? '',
              g.teacherName ?? '',
            ]),
      );

  String exportAbsencesCsv() => toCsv(
        ['Tantárgy', 'Dátum', 'Állapot', 'Típus', 'Késés (perc)'],
        _absences.map((a) => [
              getDisplaySubject(a.subject),
              csvDate(a.date),
              a.status,
              a.type ?? '',
              a.delayMinutes ?? 0,
            ]),
      );
}

