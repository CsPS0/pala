import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pala/models/grade.dart';
import 'package:path_provider/path_provider.dart';

/// Exports grades and subject performance data to CSV format.
class CsvExporter {
  CsvExporter._();

  static String _escapeCsv(String? value) {
    if (value == null) return '""';
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Generates CSV content from a list of [Grade] items with UTF-8 BOM for Excel compatibility.
  /// Semicolon-separated like the TUI export: Hungarian-locale Excel splits on ';', not ','.
  static String generateGradesCsv(List<Grade> grades) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');
    // Header
    buffer.writeln('Tantárgy;Jegy;Szöveges Érték;Súly (%);Típus;Dátum;Téma;Tanár');

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final g in grades) {
      final dateStr = g.date != null ? dateFormat.format(g.date!) : '';
      final row = [
        _escapeCsv(g.subject),
        _escapeCsv(g.numericValue?.toString() ?? ''),
        _escapeCsv(g.textValue ?? ''),
        _escapeCsv('${g.weight.round()}%'),
        _escapeCsv(g.type ?? ''),
        _escapeCsv(dateStr),
        _escapeCsv(g.theme ?? ''),
        _escapeCsv(g.teacherName ?? ''),
      ];
      buffer.writeln(row.join(';'));
    }

    return buffer.toString();
  }

  /// Writes generated CSV string to a local file and returns the [File] object.
  static Future<File> exportGradesToFile(List<Grade> grades) async {
    final csv = generateGradesCsv(grades);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/jegyek_$timestamp.csv');
    await file.writeAsString(csv);
    return file;
  }
}
