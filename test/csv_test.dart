import 'package:test/test.dart';
import 'package:pala/utils/csv.dart';

void main() {
  group('toCsv', () {
    test('starts with a BOM, uses semicolons, quotes every value, ends lines with CRLF', () {
      final csv = toCsv(['Tantárgy', 'Téma'], [
        ['Matematika', 'Egyenletek; "nehéz" feladatok'],
        ['Fizika', null],
      ]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Tantárgy;Téma\r\n'));
      expect(csv, contains('"Matematika";"Egyenletek; ""nehéz"" feladatok"\r\n'));
      expect(csv, contains('"Fizika";""\r\n'));
    });
  });

  group('csvDate', () {
    test('uses the local calendar day', () {
      expect(csvDate(DateTime(2026, 10, 20, 0, 30)), '2026-10-20');
      expect(csvDate(null), '');
    });
  });
}
