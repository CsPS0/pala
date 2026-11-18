import 'dart:convert';
import 'dart:io';

import 'package:pala/api/demo_data.dart';
import 'package:pala/models/models.dart';
import 'package:pala/rules/grade_rules.dart';
import 'package:pala/utils/pala_clock.dart';
import 'package:test/test.dart';

/// Demo mode data exists twice: lib/api/demo_data.dart (the reference) and
/// the DEMO_* constants in extension/shared/kreta_api.js. Both are reduced to
/// the same summary and compared with fixtures/demo/demo_summary.json; the
/// extension side is extension/test/demo_sync.test.mjs.
///
/// After changing the Dart demo on purpose, regenerate the fixture with
///   PALA_UPDATE_DEMO_FIXTURE=1 dart test test/demo_sync_test.dart
/// then change the extension copy until its node test passes too.
const fixturePath = 'fixtures/demo/demo_summary.json';

void main() {
  test('Dart demo data matches fixtures/demo/demo_summary.json', () {
    final summary = demoSummary(PalaClock.now());
    final encoded = '${const JsonEncoder.withIndent('  ').convert(summary)}\n';
    if (Platform.environment['PALA_UPDATE_DEMO_FIXTURE'] == '1') {
      File(fixturePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(encoded);
    }
    final fixture = jsonDecode(File(fixturePath).readAsStringSync());
    expect(summary, fixture,
        reason: 'lib/api/demo_data.dart changed. Regenerate $fixturePath (see the comment at the top of this test) '
            'and update the DEMO_* data in extension/shared/kreta_api.js to match.');
  });
}

String _two(int n) => n.toString().padLeft(2, '0');
String _hhmm(DateTime? d) => d == null ? '' : '${_two(d.hour)}:${_two(d.minute)}';
String _hoursFrom(DateTime now, DateTime? d) =>
    d == null ? '' : ((d.millisecondsSinceEpoch - now.millisecondsSinceEpoch) / 3600000).round().toString();

/// The fields every client shows, flattened to strings so the JS side can
/// build the identical JSON (see demoSummary in demo_sync.test.mjs).
Map<String, dynamic> demoSummary(DateTime now) {
  final grades = DemoData.getGrades();
  final subjectAverages = GradeRules.subjectAverages(grades);

  List<String> week(bool aWeek) {
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return DemoData.getTimetable(start: monday, overrideAWeek: aWeek)
        .map((l) => [
              l.startTime!.weekday,
              l.lessonNumber,
              l.subject,
              l.teacher ?? '',
              l.room ?? '',
              '${_hhmm(l.startTime)}-${_hhmm(l.endTime)}',
              l.theme ?? '',
              l.substituteTeacher ?? '',
              (l.status ?? '').toLowerCase().contains('elmarad') ? 'elmarad' : '',
            ].join('|'))
        .toList();
  }

  final messages = DemoData.getMessages().where((m) => m.id < 200).toList();

  return {
    'student': DemoData.studentName,
    'className': DemoData.className,
    'overallAverage': GradeRules.overallAverage(grades)!.toStringAsFixed(2),
    'subjectAverages': {
      for (final e in (subjectAverages.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        e.key: e.value.toStringAsFixed(2),
    },
    'groupAverages': {
      for (final a in DemoData.getGroupAverages())
        (a['Tantargy'] as Map)['Nev'] as String: (a['OsztalyCsoportAtlag'] as num).toStringAsFixed(2),
    },
    'grades': [
      for (final g in grades)
        [
          g.subject,
          g.textValue ?? '',
          GradeRules.countsForAverage(g) ? g.weight.round().toString() : '-',
          '${_two(g.date!.month)}-${_two(g.date!.day)}',
          g.type ?? '',
          g.theme ?? '',
          g.teacherName ?? '',
        ].join('|'),
    ]..sort(),
    'timetableA': week(true),
    'timetableB': week(false),
    'exams': [
      for (final e in DemoData.getExams()) [e.subject, e.mode, e.theme ?? '', _hoursFrom(now, e.date)].join('|'),
    ],
    'homework': [
      for (final h in DemoData.getHomework())
        [h.subject, h.text, _hoursFrom(now, h.assignedDate), _hoursFrom(now, h.deadline)].join('|'),
    ],
    'messages': [
      for (final m in messages)
        [
          m.id,
          m.senderName,
          m.subject,
          m.isRead ? 'olvasott' : 'olvasatlan',
          _hoursFrom(now, m.sentDate),
          m.attachments.map((a) => a.name).join(','),
          m.text,
        ].join('|'),
    ]..sort(),
    'notes': [
      for (final Note n in DemoData.getNotes())
        [n.id, n.type, n.senderName, n.title, _hoursFrom(now, n.date), n.content].join('|'),
    ]..sort(),
    'absences': [
      for (final a in DemoData.getAbsences())
        [a.subject, a.status, a.type ?? '', a.delayMinutes ?? 0, _hoursFrom(now, a.date)].join('|'),
    ],
    'teachers': [
      for (final t in DemoData.getTeachers()) '${t['nev']}|${t['tantargyak']}',
    ],
  };
}
