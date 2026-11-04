import 'package:pala/models/models.dart';
import 'package:pala/rules/absence_rules.dart';
import 'package:pala/rules/grade_rules.dart';
import 'package:pala/rules/schedule_rules.dart';
import 'package:test/test.dart';

/// Same cases as the extension's tests in extension/test/kreta_api.test.mjs,
/// so the app and the extension sort, filter and group alike.
void main() {
  test('messageView filters by sender and sorts both ways; messageSenders lists each sender once', () {
    Message m(int id, String sender, DateTime d) => Message(id: id, senderName: sender, subject: 'S', sentDate: d);
    final list = [
      m(1, 'Kovács Anna', DateTime.utc(2026, 10, 1, 8)),
      m(2, 'Nagy Béla', DateTime.utc(2026, 11, 2, 8)),
      m(3, 'Kovács Anna', DateTime.utc(2026, 10, 20, 8)),
    ];
    expect(messageSenders(list), ['Kovács Anna', 'Nagy Béla']);
    expect(messageView(list, sender: 'Kovács Anna').map((x) => x.id), [3, 1]);
    expect(messageView(list, oldestFirst: true).map((x) => x.id), [1, 3, 2]);
  });

  test('isUpcoming keeps today and later, drops earlier days and missing dates', () {
    final now = DateTime(2026, 11, 4, 15);
    expect(isUpcoming(DateTime(2026, 11, 4, 8), now), isTrue);
    expect(isUpcoming(DateTime(2026, 11, 10), now), isTrue);
    expect(isUpcoming(DateTime(2026, 11, 3, 23), now), isFalse);
    expect(isUpcoming(null, now), isFalse);
  });

  test('runningAverages gives the weighted average after each grade', () {
    Grade g(int v, double w) => Grade(subject: 'M', numericValue: v, weight: w);
    final avgs = GradeRules.runningAverages([g(5, 100), g(2, 200), g(4, 100)]);
    expect(avgs.map((a) => (a * 100).round() / 100), [5, 3, 3.25]);
    expect(GradeRules.runningAverages([]), isEmpty);
  });

  test('absencesBySubject and absencesByMonth group lessons by the shared absence rule', () {
    Absence a(String subject, String date, String status, [int? late]) => Absence.fromJson({
          'Tantargy': {'Nev': subject},
          'Datum': date,
          'IgazolasAllapota': status,
          'Tipus': {'Nev': late != null ? 'keses' : 'hianyzas'},
          'KesesPercben': late,
        });
    final list = [
      a('Matematika', '2026-09-10T00:00:00', 'Igazolt'),
      a('Matematika', '2026-10-02T00:00:00', 'Igazolatlan'),
      a('Fizika', '2026-10-03T00:00:00', 'Igazolando'),
      a('Fizika', '2026-10-04T00:00:00', 'Igazolt', 5),
    ];
    final bySubject = AbsenceRules.bySubject(list);
    expect(bySubject.first.subject, 'Matematika');
    expect(bySubject.first.summary.missed, 2);
    expect(bySubject.first.summary.unexcused, 1);
    expect(bySubject[1].summary.pending, 1);
    expect(bySubject[1].summary.lateCount, 1);
    expect(AbsenceRules.byMonth(list).map((m) => '${m.month}:${m.missed}'), ['2026-09:1', '2026-10:2']);
  });
}
