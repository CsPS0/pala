import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pala/api/client.dart';
import 'package:pala/api/demo_client.dart';
import 'package:pala/models/absence.dart';
import 'package:pala/models/exam.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/models/homework.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/student.dart';
import 'package:pala/models/timetable_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModel extends ChangeNotifier {
  KretaClient? _client;
  bool _isDemo = false;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _themeAccent = 'orange';

  Student? _student;
  List<Grade> _grades = [];
  List<TimetableEntry> _timetable = [];
  List<Homework> _homework = [];
  List<Exam> _exams = [];
  List<Message> _messages = [];
  List<Absence> _absences = [];
  List<dynamic> _groupAverages = [];
  List<Map<String, dynamic>> _teachers = [];

  int _parentalQuota = 5;
  Map<String, String> _aliases = {};
  Set<String> _completedHomework = {};
  int _weekOffset = 0;

  // Getters
  KretaClient? get client => _client;
  bool get isDemo => _isDemo;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get themeAccent => _themeAccent;

  Student? get student => _student;
  List<Grade> get grades => _grades;
  List<TimetableEntry> get timetable => _timetable;
  List<Homework> get homework => _homework;
  List<Exam> get exams => _exams;
  List<Message> get messages => _messages;
  List<Absence> get absences => _absences;
  List<dynamic> get groupAverages => _groupAverages;
  List<Map<String, dynamic>> get teachers => _teachers;

  int get parentalQuota => _parentalQuota;
  Map<String, String> get aliases => _aliases;
  Set<String> get completedHomework => _completedHomework;
  int get weekOffset => _weekOffset;

  AppModel() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _themeAccent = prefs.getString('pala_mobile_accent') ?? 'orange';
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
  }

  Future<bool> login({
    required String instituteCode,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final kClient = KretaClient(instituteCode: instituteCode);
      final loggedIn = await kClient.login(username, password);
      if (!loggedIn) {
        throw Exception('Nem sikerült bejelentkezni. Ellenőrizd az adataidat!');
      }
      _client = kClient;
      _isDemo = false;
      _isAuthenticated = true;
      _isLoading = false;
      await refreshAll();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loginDemo() async {
    _isLoading = true;
    _errorMessage = null;
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
    _groupAverages = [];
    _teachers = [];
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
      ]);

      _student = futures[0] as Student?;
      _grades = (futures[1] as List<Grade>?) ?? [];
      _timetable = (futures[2] as List<TimetableEntry>?) ?? [];
      _homework = (futures[3] as List<Homework>?) ?? [];
      _exams = (futures[4] as List<Exam>?) ?? [];
      _messages = (futures[5] as List<Message>?) ?? [];
      _absences = (futures[6] as List<Absence>?) ?? [];
      _groupAverages = (futures[7] as List<dynamic>?) ?? [];
      _teachers = (futures[8] as List<Map<String, dynamic>>?) ?? [];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Hiba az adatok lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required String recipientName,
    required String subject,
    required String messageText,
  }) async {
    if (_client == null) return false;
    try {
      int teacherId = 1;
      for (final t in _teachers) {
        final name = (t['Nev'] ?? t['nev'] ?? t['name'])?.toString();
        if (name == recipientName) {
          final id = t['Azonosito'] ?? t['azonosito'] ?? t['id'] ?? t['Id'];
          if (id is int) {
            teacherId = id;
          } else if (id != null) {
            teacherId = int.tryParse(id.toString()) ?? 1;
          }
          break;
        }
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
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final targetMonday = currentMonday.add(Duration(days: offset * 7));
    final targetFriday = targetMonday.add(const Duration(days: 4));

    final start = DateTime(targetMonday.year, targetMonday.month, targetMonday.day, 0, 0, 0);
    final end = DateTime(targetFriday.year, targetFriday.month, targetFriday.day, 23, 59, 59);

    final entries = await _client!.getTimetable(start, end);
    return entries ?? [];
  }

  Future<void> setWeekOffset(int offset) async {
    _weekOffset = offset;
    _isLoading = true;
    notifyListeners();
    try {
      _timetable = await _fetchTimetableForOffset(offset);
    } catch (e) {
      _errorMessage = 'Hiba az órarend betöltésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> setThemeAccent(String accent) async {
    _themeAccent = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pala_mobile_accent', accent);
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

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pala_cached_student');
    await prefs.remove('pala_completed_hw');
    _completedHomework = {};
    notifyListeners();
  }

  // --- Calculated Statistics ---

  double get overallGpa {
    double sum = 0;
    double count = 0;
    for (final g in _grades) {
      if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final w = g.weight / 100.0;
        sum += g.numericValue! * w;
        count += w;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }

  Map<String, double> get subjectAverages {
    final sums = <String, double>{};
    final weights = <String, double>{};

    for (final g in _grades) {
      if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final sub = getDisplaySubject(g.subject);
        final w = g.weight / 100.0;
        sums[sub] = (sums[sub] ?? 0) + g.numericValue! * w;
        weights[sub] = (weights[sub] ?? 0) + w;
      }
    }

    final avgs = <String, double>{};
    for (final s in sums.keys) {
      final w = weights[s] ?? 0;
      if (w > 0) avgs[s] = sums[s]! / w;
    }
    return avgs;
  }

  Map<String, double> get groupAveragesMap {
    final map = <String, double>{};
    for (final item in _groupAverages) {
      if (item is Map) {
        final sub = item['Tantargy']?['Nev']?.toString();
        final rawVal = item['OsztalyCsoportAtlag'] ?? item['Atlag'] ?? item['Ertek'];
        if (sub != null && rawVal != null) {
          final val = double.tryParse(rawVal.toString().replaceAll(',', '.')) ?? 0.0;
          if (val > 0) map[getDisplaySubject(sub)] = val;
        }
      }
    }
    return map;
  }

  // Target Average Calculator
  int calculateRequiredFives(String subject, double targetAvg, {int weight = 100}) {
    double currentSum = 0;
    double currentWeight = 0;

    for (final g in _grades) {
      if (getDisplaySubject(g.subject) == subject && g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final w = g.weight / 100.0;
        currentSum += g.numericValue! * w;
        currentWeight += w;
      }
    }

    if (currentWeight == 0) return 1;
    final curAvg = currentSum / currentWeight;
    if (curAvg >= targetAvg) return 0;
    if (targetAvg >= 5.0) return 99; // impossible if there's any non-5

    final w5 = weight / 100.0;
    int needed = 0;
    double simSum = currentSum;
    double simWeight = currentWeight;

    while ((simSum / simWeight) < targetAvg && needed < 50) {
      needed++;
      simSum += 5.0 * w5;
      simWeight += w5;
    }
    return needed;
  }

  // Absence breakdown
  int get totalMissedHours => _absences.where((a) => a.type?.toLowerCase() != 'késés').length;
  
  int get justifiedHours => _absences.where((a) {
    final s = a.status.toLowerCase();
    return s.contains('igazolt') && !s.contains('igazolatlan') && a.type?.toLowerCase() != 'késés';
  }).length;

  int get unjustifiedHours => _absences.where((a) {
    final s = a.status.toLowerCase();
    return s.contains('igazolatlan') && a.type?.toLowerCase() != 'késés';
  }).length;

  int get pendingHours => _absences.where((a) {
    final s = a.status.toLowerCase();
    return (s.contains('igazolando') || s.contains('igazolandó') || s.contains('fuggoben') || s.contains('függőben')) && a.type?.toLowerCase() != 'késés';
  }).length;

  int get totalDelayMinutes {
    int sum = 0;
    for (final a in _absences) {
      if (a.delayMinutes != null && a.delayMinutes! > 0) {
        sum += a.delayMinutes!;
      }
    }
    return sum;
  }

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

  // Excuse note generator
  String generateExcuseText({required String studentName, required DateTime date, required String reason}) {
    final dateStr = '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
    return 'Tisztelt Osztályfőnök!\n\nAlulírott gondviselő igazolom, hogy $studentName nevű gyermekem $dateStr napon $reason miatt nem tudott megjelenni a tanítási órákon.\n\nKérem a hiányzás szülői igazolásként való elfogadását!\n\nKöszönettel,\nGondviselő';
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
  String exportGradesCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Tantargy;Ertek;Suly;Datum;Tema;Tanar');
    for (final g in _grades) {
      final sub = getDisplaySubject(g.subject);
      final val = g.numericValue?.toString() ?? g.textValue ?? '';
      final weight = g.weight.toInt();
      final date = g.date?.toIso8601String().split('T')[0] ?? '';
      final theme = (g.theme ?? '').replaceAll(';', ',');
      final teacher = (g.teacherName ?? '').replaceAll(';', ',');
      buffer.writeln('"$sub";"$val";"$weight%";"$date";"$theme";"$teacher"');
    }
    return buffer.toString();
  }

  String exportAbsencesCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Tantargy;Datum;Allapot;Tipus;KesesPerc');
    for (final a in _absences) {
      final sub = getDisplaySubject(a.subject);
      final date = a.date?.toIso8601String().split('T')[0] ?? '';
      final status = a.status;
      final type = a.type ?? '';
      final delay = a.delayMinutes ?? 0;
      buffer.writeln('"$sub";"$date";"$status";"$type";"$delay"');
    }
    return buffer.toString();
  }
}

