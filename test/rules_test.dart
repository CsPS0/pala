import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:pala/models/models.dart';
import 'package:pala/rules/absence_rules.dart';
import 'package:pala/rules/grade_rules.dart';

/// Runs the shared rule vectors in fixtures/rules/. The extension runs the
/// same files in extension/test/rules.test.mjs.
Map<String, dynamic> _load(String name) =>
    jsonDecode(File('fixtures/rules/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('GradeRules (fixtures/rules/averages.json)', () {
    for (final c in (_load('averages.json')['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'], () {
        final grades = (c['grades'] as List).map((g) => Grade.fromJson(g as Map<String, dynamic>)).toList();
        final expected = (c['subjectAverages'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));

        final actual = GradeRules.subjectAverages(grades);
        expect(actual.keys.toSet(), expected.keys.toSet());
        for (final s in expected.keys) {
          expect(actual[s], closeTo(expected[s]!, 1e-9), reason: s);
        }

        final overall = GradeRules.overallAverage(grades);
        if (c['overall'] == null) {
          expect(overall, isNull);
        } else {
          expect(overall, closeTo((c['overall'] as num).toDouble(), 1e-9));
        }
      });
    }
  });

  group('AbsenceRules (fixtures/rules/absences.json)', () {
    for (final c in (_load('absences.json')['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'], () {
        final absences = (c['absences'] as List).map((a) => Absence.fromJson(a as Map<String, dynamic>)).toList();
        final s = AbsenceRules.summarize(absences);
        final e = c['summary'] as Map<String, dynamic>;
        expect(
          {
            'missed': s.missed,
            'excused': s.excused,
            'pending': s.pending,
            'unexcused': s.unexcused,
            'lateCount': s.lateCount,
            'lateMinutes': s.lateMinutes,
          },
          e,
        );
      });
    }
  });
}
