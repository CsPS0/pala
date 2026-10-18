import '../../models/models.dart';

enum TuiPane { left, right }

class TuiGhostGrade {
  final String subject;
  final int grade;
  final double weight;

  const TuiGhostGrade({
    required this.subject,
    required this.grade,
    required this.weight,
  });
}

/// Holds interactive state and cached Kréta data for the modernized multi-pane TUI.
class TuiWorkspaceState {
  static const List<String> tabTitles = [
    'Vezérlőpult',
    'Jegyek és Mátrix',
    'Órarend',
    'Mulasztások',
  ];

  static const List<double> weightPresets = [50.0, 100.0, 200.0, 300.0];

  static const List<String> absenceFilterLabels = [
    'Összes',
    'Igazolatlan',
    'Igazolandó',
    'Igazolt',
    'Késések',
  ];

  TuiPane activePane = TuiPane.right;
  int activeTab = 0;
  final List<int> scrollOffsets = [0, 0, 0, 0];

  // Tab-specific sub-modes & filters
  int gradesSubMode = 0; // 0: Matrix, 1: Detailed List + Certificate Planner
  int timetableSubMode = 0; // 0: Weekly Matrix, 1: Daily Feed
  int timetableDayOffset = 0;
  bool? overrideAWeek;
  int absenceFilter = 0;

  // Interactive Szellem Jegy (Ghost Grade) bar state
  bool ghostDrawerOpen = false;
  int ghostSubjectIndex = 0;
  int ghostGradeValue = 5;
  int ghostWeightIndex = 1; // 100%
  final List<TuiGhostGrade> ghostGrades = [];

  // Status & sync metadata
  bool isDemo = false;
  bool isMaintenance = false;
  int? maintenanceStatusCode;
  bool sessionExpired = false;
  bool isNetworkDown = false;
  bool isLoading = false;
  DateTime lastSync = DateTime.now();
  String? statusBannerMessage;
  String? weekTypeLabel;

  // Loaded Kréta models
  Student? student;
  List<Grade> grades = [];
  List<TimetableEntry> timetable = [];
  List<Map<String, dynamic>> averages = [];
  List<Map<String, dynamic>> groupAverages = [];
  List<Absence> absences = [];
  List<Exam> exams = [];
  List<Homework> homeworks = [];
  List<Message> messages = [];
  List<Note> notes = [];

  int get currentScroll => scrollOffsets[activeTab];
  set currentScroll(int value) {
    scrollOffsets[activeTab] = value < 0 ? 0 : value;
  }

  void switchTab(int index) {
    if (index < 0 || index >= tabTitles.length) return;
    activeTab = index;
  }

  void togglePane() {
    activePane = activePane == TuiPane.left ? TuiPane.right : TuiPane.left;
  }

  List<String> get availableSubjects {
    final set = <String>{};
    for (final g in grades) {
      if (g.subject.isNotEmpty) set.add(g.subject);
    }
    for (final a in averages) {
      final name = a['Tantargy']?['Nev']?.toString() ?? '';
      if (name.isNotEmpty) set.add(name);
    }
    for (final t in timetable) {
      if (t.subject.isNotEmpty) set.add(t.subject);
    }
    final list = set.toList()..sort();
    return list;
  }

  String? get selectedGhostSubject {
    final subjects = availableSubjects;
    if (subjects.isEmpty) return null;
    final idx = ghostSubjectIndex.clamp(0, subjects.length - 1);
    return subjects[idx];
  }

  double get selectedGhostWeight =>
      weightPresets[ghostWeightIndex.clamp(0, weightPresets.length - 1)];

  void addCurrentGhostGrade() {
    final subj = selectedGhostSubject;
    if (subj == null) return;
    ghostGrades.add(TuiGhostGrade(
      subject: subj,
      grade: ghostGradeValue.clamp(1, 5),
      weight: selectedGhostWeight,
    ));
    statusBannerMessage =
        'Szellem jegy hozzáadva: $subj -> $ghostGradeValue (${selectedGhostWeight.toInt()}%)';
  }

  void clearGhostGrades() {
    ghostGrades.clear();
    statusBannerMessage = 'Szellem jegyek törölve.';
  }

  /// Calculates weighted subject average for [subject], optionally including [ghostGrades].
  double subjectAverage(String subject, {bool includeGhost = true}) {
    var weightedSum = 0.0;
    var weightTotal = 0.0;

    for (final g in grades) {
      if (g.subject.toLowerCase() != subject.toLowerCase()) continue;
      if (g.isSummaryGrade) continue;
      final val = g.numericValue;
      if (val == null || val < 1 || val > 5) continue;
      final w = g.weight > 0 ? g.weight : 100.0;
      weightedSum += val * w;
      weightTotal += w;
    }

    if (includeGhost) {
      for (final gg in ghostGrades) {
        if (gg.subject.toLowerCase() == subject.toLowerCase()) {
          weightedSum += gg.grade * gg.weight;
          weightTotal += gg.weight;
        }
      }
    }

    if (weightTotal > 0) {
      return weightedSum / weightTotal;
    }

    // Fallback to reported Kréta average if no individual numeric grades exist
    for (final a in averages) {
      final name = a['Tantargy']?['Nev']?.toString() ?? '';
      if (name.toLowerCase() == subject.toLowerCase()) {
        final raw = (a['Atlag'] ?? a['Ertek'] ?? '0').toString();
        final parsed = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
        if (parsed > 0) return parsed;
      }
    }
    return 0.0;
  }

  /// Overall GPA across all graded subjects.
  double overallGpa({bool includeGhost = false}) {
    final subjects = availableSubjects;
    if (subjects.isEmpty) return 0.0;
    var sum = 0.0;
    var count = 0;
    for (final s in subjects) {
      final avg = subjectAverage(s, includeGhost: includeGhost);
      if (avg > 0) {
        sum += avg;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  int get unreadMessagesCount => messages.where((m) => !m.isRead).length;

  int get activeHomeworkCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    return homeworks
        .where((h) => h.deadline == null || h.deadline!.isAfter(cutoff))
        .length;
  }

  int get upcomingExamsCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    return exams
        .where((e) => e.date != null && e.date!.isAfter(cutoff))
        .length;
  }

  int get totalMissedHours =>
      absences.where((a) => (a.type ?? '').toLowerCase() != 'késés').length;

  int get unexcusedHours => absences
      .where((a) =>
          (a.type ?? '').toLowerCase() != 'késés' &&
          a.status.toLowerCase().contains('igazolatlan'))
      .length;

  int get pendingHours => absences
      .where((a) =>
          (a.type ?? '').toLowerCase() != 'késés' &&
          (a.status.toLowerCase().contains('igazolando') ||
              a.status.toLowerCase().contains('igazolandó')))
      .length;

  int get excusedHours => absences
      .where((a) =>
          (a.type ?? '').toLowerCase() != 'késés' &&
          a.status.toLowerCase() == 'igazolt')
      .length;

  int get delayCount => absences
      .where((a) =>
          (a.type ?? '').toLowerCase().contains('késés') ||
          a.status.toLowerCase().contains('késés'))
      .length;

  int get totalDelayMinutes {
    var mins = 0;
    for (final a in absences) {
      if ((a.type ?? '').toLowerCase().contains('késés') ||
          a.status.toLowerCase().contains('késés')) {
        mins += a.delayMinutes ?? 0;
      }
    }
    return mins;
  }
}
