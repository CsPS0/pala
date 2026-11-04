import '../models/absence.dart';

/// Absence status after the Kréta IgazolasAllapota value.
enum AbsenceStatus { excused, pending, unexcused }

/// How close missed lessons are to the 250-hour limit, for warning colours.
enum AbsenceLevel { ok, warning, danger, over }

/// Counts shown by every client's absence view.
class AbsenceSummary {
  /// Missed lessons (each absence entry is one lesson); this is what counts
  /// toward the 250-hour limit. Lateness is not included.
  final int missed;
  final int excused;
  final int pending;
  final int unexcused;
  final int lateCount;
  final int lateMinutes;

  const AbsenceSummary({
    required this.missed,
    required this.excused,
    required this.pending,
    required this.unexcused,
    required this.lateCount,
    required this.lateMinutes,
  });
}

/// The absence rule every Pala client follows. The extension mirrors it in
/// `extension/shared/kreta_api.js`; both are tested against
/// `fixtures/rules/absences.json`. Written down in docs/DEV.md
/// ("Számítási szabályok").
class AbsenceRules {
  AbsenceRules._();

  static String _normalize(String s) {
    const from = 'áéíóöőúüű';
    const to = 'aeiooouuu';
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString();
  }

  /// A lateness entry has late minutes, or its type says "késés".
  static bool isLateness(Absence a) =>
      (a.delayMinutes ?? 0) > 0 || _normalize(a.type ?? '').contains('keses');

  /// Only "Igazolt" is excused and only "Igazolatlan" is unexcused; anything
  /// else (e.g. "Igazolando") is still open.
  static AbsenceStatus status(Absence a) {
    final s = _normalize(a.status);
    if (s.contains('igazolatlan')) return AbsenceStatus.unexcused;
    if (s.contains('igazolt')) return AbsenceStatus.excused;
    return AbsenceStatus.pending;
  }

  /// Warning from 150 hours, danger from 200, over the limit from 250. Every
  /// client colours its absence bar and messages by this.
  static AbsenceLevel levelOf(int hours) {
    if (hours >= 250) return AbsenceLevel.over;
    if (hours >= 200) return AbsenceLevel.danger;
    if (hours >= 150) return AbsenceLevel.warning;
    return AbsenceLevel.ok;
  }

  static AbsenceSummary summarize(Iterable<Absence> absences) {
    var missed = 0, excused = 0, pending = 0, unexcused = 0, lateCount = 0, lateMinutes = 0;
    for (final a in absences) {
      if (isLateness(a)) {
        lateCount++;
        lateMinutes += a.delayMinutes ?? 0;
        continue;
      }
      missed++;
      switch (status(a)) {
        case AbsenceStatus.excused:
          excused++;
        case AbsenceStatus.pending:
          pending++;
        case AbsenceStatus.unexcused:
          unexcused++;
      }
    }
    return AbsenceSummary(
      missed: missed,
      excused: excused,
      pending: pending,
      unexcused: unexcused,
      lateCount: lateCount,
      lateMinutes: lateMinutes,
    );
  }

  /// [summarize] per subject, most missed lessons first. Mirrors
  /// `KretaApi.absencesBySubject`.
  static List<({String subject, AbsenceSummary summary})> bySubject(Iterable<Absence> absences) {
    final groups = <String, List<Absence>>{};
    for (final a in absences) {
      groups.putIfAbsent(a.subject, () => []).add(a);
    }
    final rows = [for (final e in groups.entries) (subject: e.key, summary: summarize(e.value))];
    rows.sort((x, y) {
      final byMissed = y.summary.missed.compareTo(x.summary.missed);
      if (byMissed != 0) return byMissed;
      final byLate = y.summary.lateCount.compareTo(x.summary.lateCount);
      return byLate != 0 ? byLate : x.subject.compareTo(y.subject);
    });
    return rows;
  }

  /// Missed lessons (lateness apart) per month ("YYYY-MM"), oldest first.
  /// Mirrors `KretaApi.absencesByMonth`.
  static List<({String month, int missed})> byMonth(Iterable<Absence> absences) {
    final months = <String, int>{};
    for (final a in absences) {
      final d = a.date;
      if (d == null || isLateness(a)) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      months[key] = (months[key] ?? 0) + 1;
    }
    final keys = months.keys.toList()..sort();
    return [for (final k in keys) (month: k, missed: months[k]!)];
  }
}
