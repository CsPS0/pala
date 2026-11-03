import 'dart:convert';

import '../models/models.dart';

class IcsExporter {
  static String generate(List<TimetableEntry> timetable, List<Exam> exams) {
    final buffer = StringBuffer();
    // RFC 5545: CRLF line ends, lines folded at 75 octets.
    void line(String text) => buffer.write('${_fold(text)}\r\n');
    line('BEGIN:VCALENDAR');
    line('VERSION:2.0');
    line('PRODID:-//Pala//Pala TUI//HU');
    line('CALSCALE:GREGORIAN');
    line('METHOD:PUBLISH');
    line('X-WR-CALNAME:Pala Órarend és Vizsgák');

    final now = DateTime.now().toUtc();
    final dtstamp = _formatDate(now);

    for (var lesson in timetable) {
      final start = lesson.startTime?.toUtc();
      final end = lesson.endTime?.toUtc();
      if (start == null || end == null) continue;

      final uid = 'lesson-${lesson.uid ?? start.millisecondsSinceEpoch}@pala';
      final room = lesson.room ?? '';

      final descriptionParts = <String>[];
      if (lesson.teacher != null && lesson.teacher!.isNotEmpty) {
        descriptionParts.add('Tanár: ${lesson.teacher}');
      }
      if (lesson.substituteTeacher != null && lesson.substituteTeacher!.isNotEmpty) {
        descriptionParts.add('Helyettesítő tanár: ${lesson.substituteTeacher}');
      }
      if (lesson.theme != null && lesson.theme!.isNotEmpty) {
        descriptionParts.add('Téma: ${lesson.theme}');
      }

      line('BEGIN:VEVENT');
      line('UID:$uid');
      line('DTSTAMP:$dtstamp');
      line('DTSTART:${_formatDate(start)}');
      line('DTEND:${_formatDate(end)}');
      line('SUMMARY:${_escape(lesson.subject)}');
      if (room.isNotEmpty) line('LOCATION:${_escape(room)}');
      if (descriptionParts.isNotEmpty) {
        line('DESCRIPTION:${_escape(descriptionParts.join('\n'))}');
      }
      line('STATUS:${lesson.isCancelled ? 'CANCELLED' : 'CONFIRMED'}');
      line('END:VEVENT');
    }

    for (var exam in exams) {
      // An all-day event: its date is the local calendar day, not the UTC one.
      final date = exam.date?.toLocal();
      if (date == null) continue;

      final subject = exam.subject;
      final type = exam.mode;
      final theme = exam.theme ?? '';
      final uid = 'exam-${exam.uid ?? date.millisecondsSinceEpoch}@pala';

      line('BEGIN:VEVENT');
      line('UID:$uid');
      line('DTSTAMP:$dtstamp');
      line('DTSTART;VALUE=DATE:${_formatDateOnly(date)}');
      line('SUMMARY:${_escape('[$type] $subject')}');
      if (theme.isNotEmpty) line('DESCRIPTION:${_escape(theme)}');
      line('END:VEVENT');
    }

    line('END:VCALENDAR');
    return buffer.toString();
  }

  /// RFC 5545 TEXT escaping: backslash first, then ; , and newlines.
  static String _escape(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  /// Splits a content line into 75-octet pieces (continuations start with a
  /// space), without cutting a multi-byte UTF-8 character in half.
  static String _fold(String text) {
    final out = StringBuffer();
    var lineBytes = 0;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final size = utf8.encode(ch).length;
      if (lineBytes + size > 75) {
        out.write('\r\n ');
        lineBytes = 1;
      }
      out.write(ch);
      lineBytes += size;
    }
    return out.toString();
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }
}
