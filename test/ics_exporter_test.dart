import 'package:test/test.dart';
import 'package:pala/models/exam.dart';
import 'package:pala/models/timetable_entry.dart';
import 'package:pala/utils/ics_exporter.dart';

void main() {
  group('IcsExporter', () {
    test('generates valid RFC 5545 iCalendar content', () {
      final lessons = [
        TimetableEntry(
          subject: 'Történelem',
          theme: 'Az első világháború',
          lessonNumber: 1,
          room: '102',
          teacher: 'Kovács János',
          startTime: DateTime.utc(2026, 10, 14, 8, 0),
          endTime: DateTime.utc(2026, 10, 14, 8, 45),
        ),
        TimetableEntry(
          subject: 'Fizika',
          lessonNumber: 2,
          room: 'Fizika ea.',
          status: 'Elmarad',
          startTime: DateTime.utc(2026, 10, 14, 9, 0),
          endTime: DateTime.utc(2026, 10, 14, 9, 45),
        ),
      ];
      final exams = [
        Exam(subject: 'Matematika', mode: 'Dolgozat', theme: r'Egyenletek; függvények, C:\ jegyzet', date: DateTime.utc(2026, 10, 20)),
      ];

      final ics = IcsExporter.generate(lessons, exams);

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('SUMMARY:Történelem'));
      expect(ics, contains('LOCATION:102'));
      expect(ics, contains('STATUS:CONFIRMED'));
      expect(ics, contains('SUMMARY:Fizika'));
      expect(ics, contains('STATUS:CANCELLED'));
      // Parts are joined by a real newline, which must come out as the ICS escape \n, not \\n.
      expect(ics, contains(r'DESCRIPTION:Tanár: Kovács János\nTéma: Az első világháború'));
      expect(ics, isNot(contains(r'\\n')));
      expect(ics, contains('DTSTART;VALUE=DATE:20261020'));
      expect(ics, contains('SUMMARY:[Dolgozat] Matematika'));
      expect(ics, contains(r'DESCRIPTION:Egyenletek\; függvények\, C:\\ jegyzet'));
      expect(ics, contains('END:VCALENDAR'));
    });
  });
}
