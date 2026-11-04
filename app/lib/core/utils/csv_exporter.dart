import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/utils/csv.dart';
import 'package:path_provider/path_provider.dart';

/// Exports grades and subject performance data to CSV format.
class CsvExporter {
  CsvExporter._();

  /// Grades as CSV in the shared format (package:pala/utils/csv.dart).
  static String generateGradesCsv(List<Grade> grades) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return toCsv(
      ['Tantárgy', 'Jegy', 'Szöveges Érték', 'Súly (%)', 'Típus', 'Dátum', 'Téma', 'Tanár'],
      grades.map((g) => [
            g.subject,
            g.displayValue,
            g.textValue ?? '',
            '${g.weight.round()}%',
            g.type ?? '',
            g.date != null ? dateFormat.format(g.date!.toLocal()) : '',
            g.theme ?? '',
            g.teacherName ?? '',
          ]),
    );
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
