import 'package:test/test.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/models/absence.dart';
import 'package:pala/models/note.dart';
import 'package:pala/models/class_average.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/exam.dart';

void main() {
  group('Exam', () {
    test('reads the topic from Temaja (the real Kréta field)', () {
      final e = Exam.fromJson({'Tantargy': {'Nev': 'Fizika'}, 'Temaja': 'Mechanika', 'Modja': {'Nev': 'irasbeli_dolgozat', 'Leiras': 'Írásbeli dolgozat'}});
      expect(e.theme, 'Mechanika');
    });
  });

  group('sortMessagesNewestFirst', () {
    test('puts the newest message first and undated ones last', () {
      Message m(int id, DateTime? d) => Message(id: id, senderName: 'T', subject: 'S', sentDate: d);
      final sorted = sortMessagesNewestFirst([
        m(1, DateTime(2026, 10, 1)),
        m(2, null),
        m(3, DateTime(2026, 11, 2)),
        m(4, DateTime(2026, 10, 15)),
      ]);
      expect(sorted.map((x) => x.id).toList(), [3, 4, 1, 2]);
    });
  });

  group('classAverageOf (OsztalyAtlagok item)', () {
    test('reads the real Kréta field OsztalyCsoportAtlag', () {
      expect(classAverageOf({'OsztalyCsoportAtlag': 3.42, 'TanuloAtlag': 4.1}), 3.42);
    });
    test('falls back to older names and parses comma decimals', () {
      expect(classAverageOf({'OsztalyAtlag': 4.0}), 4.0);
      expect(classAverageOf({'Atlag': '3,5'}), 3.5);
    });
    test('is null when missing or not positive', () {
      expect(classAverageOf({}), isNull);
      expect(classAverageOf({'OsztalyCsoportAtlag': 0}), isNull);
    });
  });

  group('Grade value kind (ErtekFajta)', () {
    test('a Szazalekos evaluation keeps its number out of numericValue', () {
      final g = Grade.fromJson({
        'Tantargy': {'Nev': 'Matematika'},
        'ErtekFajta': {'Nev': 'Szazalekos'},
        'SzamErtek': 4,
        'SzovegesErtek': '4%',
        'SulySzazalekErteke': null,
      });
      expect(g.valueKind, GradeValueKind.percent);
      expect(g.numericValue, isNull);
      expect(g.percentValue, 4);
      expect(g.displayValue, '4%');
    });

    test('a Szoveges evaluation is text even with a number', () {
      final g = Grade.fromJson({'ErtekFajta': {'Nev': 'Szoveges'}, 'SzamErtek': 2, 'SzovegesErtek': 'Nem írt'});
      expect(g.valueKind, GradeValueKind.text);
      expect(g.numericValue, isNull);
      expect(g.displayValue, 'Nem írt');
    });

    test('without ErtekFajta a 1-5 number is a grade and 85 a percentage', () {
      expect(Grade.fromJson({'SzamErtek': 3}).numericValue, 3);
      final p = Grade.fromJson({'SzamErtek': 85});
      expect(p.valueKind, GradeValueKind.percent);
      expect(p.percentValue, 85);
    });
  });

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
        // Unaccented type keys used by Kréta responses.
        'felevi_jegy_ertekeles',
        'evvegi_jegy_ertekeles',
        'osztalyozo_vizsga',
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

  group('Note', () {
    test('fromJson parses fields correctly and identifies praise/disciplinary', () {
      final praiseNote = Note.fromJson({
        'Uid': 'note-1',
        'Tipus': {'Leiras': 'Szaktanári dicséret'},
        'KeszitoTanarNeve': 'Kovács Péter',
        'Cim': 'Dicséret versenyért',
        'Tartalom': 'Gratulálok a versenyhez!',
        'KeszitesDatuma': '2026-03-01T09:00:00Z',
      });

      expect(praiseNote.id, 'note-1');
      expect(praiseNote.type, 'Szaktanári dicséret');
      expect(praiseNote.senderName, 'Kovács Péter');
      expect(praiseNote.title, 'Dicséret versenyért');
      expect(praiseNote.content, 'Gratulálok a versenyhez!');
      expect(praiseNote.date, isNotNull);
      expect(praiseNote.isPraise, isTrue);
      expect(praiseNote.isDisciplinary, isFalse);

      final warningNote = Note.fromJson({
        'Id': 105,
        'Tipus': {'Leiras': 'Osztályfőnöki megrovás'},
        'KeszitoTanarNeve': 'Kossuth Lajos',
        'Cim': 'Osztályfőnöki megrovás',
        'Tartalom': 'Hiányzások miatt megrovásban részesítelek.',
        'KeszitesDatuma': '2026-03-05T12:00:00Z',
      });

      expect(warningNote.id, '105');
      expect(warningNote.type, 'Osztályfőnöki megrovás');
      expect(warningNote.isPraise, isFalse);
      expect(warningNote.isDisciplinary, isTrue);
    });

    test('fromJson handles empty/missing fields gracefully', () {
      final note = Note.fromJson({});

      expect(note.id, '');
      expect(note.type, 'Feljegyzés');
      expect(note.senderName, 'Ismeretlen tanár');
      expect(note.title, 'Feljegyzés');
      expect(note.content, '');
      expect(note.date, isNull);
    });
  });
}

