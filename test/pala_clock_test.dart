import 'package:pala/api/demo_data.dart';
import 'package:pala/utils/pala_clock.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => PalaClock.fix(null));

  test('a fixed clock is what the app reads, and clearing it returns to the real time', () {
    PalaClock.fix(DateTime(2026, 11, 9, 9, 10));
    expect(PalaClock.now(), DateTime(2026, 11, 9, 9, 10));
    PalaClock.fix(null);
    expect(PalaClock.now().difference(DateTime.now()).inSeconds.abs(), lessThan(2));
  });

  test('demo data follows the fixed clock: a Monday morning has lessons that day', () {
    final monday = DateTime(2026, 11, 9, 9, 10);
    PalaClock.fix(monday);
    final lessons = DemoData.getTimetable(start: DateTime(2026, 11, 9), end: DateTime(2026, 11, 15));
    expect(lessons.where((l) => l.startTime?.weekday == DateTime.monday), isNotEmpty);
    final latest = DemoData.getGrades().map((g) => g.date).whereType<DateTime>().where((d) => !d.isAfter(monday));
    expect(latest, isNotEmpty);
  });
}
