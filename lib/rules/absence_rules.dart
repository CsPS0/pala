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
}
