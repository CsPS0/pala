import '../models/models.dart';

class IcsExporter {
  static String generate(List<TimetableEntry> timetable, List<Exam> exams) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Pala//Pala TUI//HU');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Pala Órarend és Vizsgák');

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

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$dtstamp');
      buffer.writeln('DTSTART:${_formatDate(start)}');
      buffer.writeln('DTEND:${_formatDate(end)}');
      buffer.writeln('SUMMARY:${_escape(lesson.subject)}');
      if (room.isNotEmpty) buffer.writeln('LOCATION:${_escape(room)}');
      if (descriptionParts.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escape(descriptionParts.join('\n'))}');
      }
      buffer.writeln('STATUS:${lesson.isCancelled ? 'CANCELLED' : 'CONFIRMED'}');
      buffer.writeln('END:VEVENT');
    }

    for (var exam in exams) {
      final date = exam.date?.toUtc();
      if (date == null) continue;

      final subject = exam.subject;
      final type = exam.mode;
      final theme = exam.theme ?? '';
      final uid = 'exam-${exam.uid ?? date.millisecondsSinceEpoch}@pala';

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid');
      buffer.writeln('DTSTAMP:$dtstamp');
      buffer.writeln('DTSTART;VALUE=DATE:${_formatDateOnly(date)}');
      buffer.writeln('SUMMARY:${_escape('[$type] $subject')}');
      if (theme.isNotEmpty) buffer.writeln('DESCRIPTION:${_escape(theme)}');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
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

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateOnly(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }
}
