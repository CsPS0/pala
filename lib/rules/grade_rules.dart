import '../models/grade.dart';

/// The averaging rule every Pala client follows. The extension mirrors it in
/// `extension/shared/kreta_api.js`; both are tested against
/// `fixtures/rules/averages.json`. Written down in docs/DEV.md
/// ("Számítási szabályok").
class GradeRules {
  GradeRules._();

  /// A grade counts toward averages when it is a 1-5 grade (not a percentage
  /// or text evaluation, even one with a 1-5 number), not a midyear or
  /// year-end result, and its weight is above 0 (a missing weight is 100%).
  static bool countsForAverage(Grade g) {
    final v = g.numericValue;
    return g.valueKind == GradeValueKind.grade && v != null && v >= 1 && v <= 5 && !g.isSummaryGrade && g.weight > 0;
  }

  /// Weighted average per subject. Subjects without a counted grade are left out.
  static Map<String, double> subjectAverages(Iterable<Grade> grades, {String Function(Grade g)? subjectOf}) {
    final sums = <String, double>{};
    final weights = <String, double>{};
    for (final g in grades) {
      if (!countsForAverage(g)) continue;
      final subject = subjectOf?.call(g) ?? g.subject;
      sums[subject] = (sums[subject] ?? 0) + g.numericValue! * g.weight;
      weights[subject] = (weights[subject] ?? 0) + g.weight;
    }
    return {for (final s in sums.keys) s: sums[s]! / weights[s]!};
  }

  /// Overall average: the mean of the subject averages, as on a certificate.
  /// Null when there is no counted grade.
  static double? overallAverage(Iterable<Grade> grades, {String Function(Grade g)? subjectOf}) {
    final values = subjectAverages(grades, subjectOf: subjectOf).values;
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
