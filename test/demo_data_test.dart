import 'package:test/test.dart';
import 'package:pala/api/demo_data.dart';
import 'package:pala/api/demo_client.dart';

void main() {
  group('DemoData Grades and Failing Subjects', () {
    test('contains 1s and 2s in demo grades', () {
      final grades = DemoData.getGrades();
      final ones = grades.where((g) => g.numericValue == 1).toList();
      final twos = grades.where((g) => g.numericValue == 2).toList();

      expect(ones.isNotEmpty, isTrue, reason: 'Must contain grade 1');
      expect(twos.isNotEmpty, isTrue, reason: 'Must contain grade 2');
    });

    test('Fizika and Kémia have failing averages (< 2.0)', () {
      final averages = DemoData.getAverages();
      expect(averages, isNotNull);

      final fizikaAvg = averages.where((a) => a['Tantargy']?['Nev'] == 'Fizika').firstOrNull;
      final kemiaAvg = averages.where((a) => a['Tantargy']?['Nev'] == 'Kémia').firstOrNull;

      expect(fizikaAvg, isNotNull);
      expect(fizikaAvg!['Atlag'], lessThan(2.0), reason: 'Fizika should be failing');

      expect(kemiaAvg, isNotNull);
      expect(kemiaAvg!['Atlag'], lessThan(2.0), reason: 'Kémia should be failing');
    });
  });

  group('DemoData Timetable and A/B Week', () {
    test('timetable has 0 classes on Wednesday', () {
      final monday = DateTime(2026, 9, 14); // Monday
      final friday = DateTime(2026, 9, 18); // Friday
      final timetable = DemoData.getTimetable(start: monday, end: friday);

      final wednesdayLessons = timetable.where((l) => l.startTime?.weekday == DateTime.wednesday).toList();
      expect(wednesdayLessons, isEmpty, reason: 'Wednesday must have no lessons (free day)');
    });

    test('timetable has 7-8 classes on non-Wednesday weekdays', () {
      final monday = DateTime(2026, 9, 14);
      final friday = DateTime(2026, 9, 18);
      final timetable = DemoData.getTimetable(start: monday, end: friday);

      final mondayLessons = timetable.where((l) => l.startTime?.weekday == DateTime.monday).toList();
      final tuesdayLessons = timetable.where((l) => l.startTime?.weekday == DateTime.tuesday).toList();
      final thursdayLessons = timetable.where((l) => l.startTime?.weekday == DateTime.thursday).toList();
      final fridayLessons = timetable.where((l) => l.startTime?.weekday == DateTime.friday).toList();

      expect(mondayLessons.length, equals(8));
      expect(tuesdayLessons.length, equals(7));
      expect(thursdayLessons.length, equals(8));
      expect(fridayLessons.length, equals(7));
    });

    test('A/B week toggle alternates subjects on Tuesday and Thursday', () {
      final monday = DateTime(2026, 9, 14);
      final friday = DateTime(2026, 9, 18);

      final timetableA = DemoData.getTimetable(start: monday, end: friday, overrideAWeek: true);
      final timetableB = DemoData.getTimetable(start: monday, end: friday, overrideAWeek: false);

      final tueA = timetableA.firstWhere((l) => l.startTime?.weekday == DateTime.tuesday && l.lessonNumber == 3);
      final tueB = timetableB.firstWhere((l) => l.startTime?.weekday == DateTime.tuesday && l.lessonNumber == 3);
      expect(tueA.subject, equals('Biológia'));
      expect(tueB.subject, equals('Földrajz'));

      final thuA = timetableA.firstWhere((l) => l.startTime?.weekday == DateTime.thursday && l.lessonNumber == 7);
      final thuB = timetableB.firstWhere((l) => l.startTime?.weekday == DateTime.thursday && l.lessonNumber == 7);
      expect(thuA.subject, equals('Matematika'));
      expect(thuB.subject, equals('Fizika'));
    });

    test('DemoKretaClient passes overrideAWeek correctly', () async {
      final client = DemoKretaClient();
      final monday = DateTime(2026, 9, 14);
      final friday = DateTime(2026, 9, 18);

      final a = await client.getTimetable(monday, friday, overrideAWeek: true);
      final b = await client.getTimetable(monday, friday, overrideAWeek: false);

      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.any((l) => l.startTime?.weekday == DateTime.wednesday), isFalse);
      expect(b!.any((l) => l.startTime?.weekday == DateTime.wednesday), isFalse);
    });
  });
}
