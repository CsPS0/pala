import 'package:flutter_test/flutter_test.dart';
import 'package:pala/models/grade.dart';
import 'package:pala_app/core/utils/csv_exporter.dart';

void main() {
  group('CsvExporter tests', () {
    test('generates valid UTF-8 BOM CSV content with headers and escaped values', () {
      final grades = [
        Grade(
          subject: 'Matematika',
          numericValue: 5,
          textValue: 'Jeles',
          weight: 100.0,
          type: 'Írásbeli témazáró dolgozat',
          theme: 'Másodfokú egyenletek',
          teacherName: 'Nagy Anna',
          date: DateTime(2026, 10, 10, 10, 30),
        ),
        Grade(
          subject: 'Magyar nyelv és irodalom',
          numericValue: 4,
          textValue: 'Jó',
          weight: 200.0,
          type: 'Évfolyamdolgozat',
          theme: 'Ady Endre költészete',
          teacherName: 'Kovács Péter',
          date: DateTime(2026, 10, 12, 11, 15),
        ),
      ];

      final csv = CsvExporter.generateGradesCsv(grades);

      // Verify UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);
      // Verify Header
      expect(csv, contains('Tantárgy;Jegy;Szöveges Érték;Súly (%);Típus;Dátum;Téma;Tanár'));
      // Verify Rows
      expect(csv, contains('"Matematika";"5";"Jeles";"100%"'));
      expect(csv, contains('"Magyar nyelv és irodalom";"4";"Jó";"200%"'));
    });
  });
}
