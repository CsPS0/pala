import 'package:test/test.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/models/absence.dart';

void main() {
  group('Grade', () {
    test('fromJson parses core fields and converts date to local time', () {
      final grade = Grade.fromJson({
        'Tantargy': {
          'Nev': 'Matematika',
          'Kategoria': {'Nev': 'Rendes'},
        },
        'SzamErtek': 5,
        'SzovegesErtek': null,
        'SulySzazalekErteke': 150,
        'KeszitesDatuma': '2026-01-15T10:00:00Z',
        'Tipus': {'Nev': 'Röpdolgozat'},
        'Tema': 'Törtek',
        'ErtekeloTanarNeve': 'Teszt Tanár',
      });

      expect(grade.subject, 'Matematika');
      expect(grade.subjectCategory, 'Rendes');
      expect(grade.numericValue, 5);
      expect(grade.weight, 150.0);
      expect(grade.date, isNotNull);
      expect(grade.date!.isUtc, isFalse);
      expect(grade.type, 'Röpdolgozat');
      expect(grade.isSummaryGrade, isFalse);
    });

    test('fromJson falls back to defaults when fields are missing', () {
      final grade = Grade.fromJson({});

      expect(grade.subject, 'Ismeretlen tantárgy');
      expect(grade.weight, 100.0);
      expect(grade.date, isNull);
    });

    test('fromJson tolerates a non-numeric weight string', () {
      final grade = Grade.fromJson({'SulySzazalekErteke': 'not-a-number'});
      expect(grade.weight, 100.0);
    });

    test('isSummaryGrade recognizes accented and unaccented markers', () {
      for (final type in [
        'Félévi',
        'Év végi',
        'Negyedévi',
        'Háromnegyedévi',
        'osztályozó vizsga',
        'felevevi', // unaccented variant used by some Kréta responses
      ]) {
        expect(Grade(subject: 'X', type: type).isSummaryGrade, isTrue,
            reason: '"$type" should be treated as a summary grade');
      }
    });

    test('isSummaryGrade is false for a regular grade type', () {
      expect(Grade(subject: 'X', type: 'Röpdolgozat').isSummaryGrade, isFalse);
      expect(Grade(subject: 'X', type: null).isSummaryGrade, isFalse);
    });
  });

  group('Absence', () {
    test('fromJson parses fields and defaults unknown status', () {
      final absence = Absence.fromJson({
        'Tantargy': {'Nev': 'Fizika'},
        'Datum': '2026-02-01T00:00:00Z',
        'Tipus': {'Nev': 'Hiányzás'},
        'KesesIdotartama': 15,
      });

      expect(absence.subject, 'Fizika');
      expect(absence.status, 'Ismeretlen');
      expect(absence.delayMinutes, 15);
      expect(absence.date, isNotNull);
    });

    test('fromJson handles a missing date without throwing', () {
      final absence = Absence.fromJson({'IgazolasAllapota': 'Igazolt'});
      expect(absence.date, isNull);
      expect(absence.status, 'Igazolt');
    });
  });
}
