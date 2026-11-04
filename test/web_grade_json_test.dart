import 'package:pala/models/grade.dart';
import 'package:pala/web/pala_web_server.dart';
import 'package:test/test.dart';

void main() {
  test('the web UI gets the shown value and kind, so a percentage is never drawn as a grade', () {
    final percent = Grade.fromJson({
      'Tantargy': {'Nev': 'Matematika'},
      'ErtekFajta': {'Nev': 'Szazalekos'},
      'SzamErtek': 3,
      'SzovegesErtek': '3',
    });
    final json = webGradeJson(percent, (s) => s);
    expect(json['displayValue'], '3%');
    expect(json['valueKind'], 'percent');
    expect(json['countsForAverage'], isFalse);

    final grade = webGradeJson(Grade.fromJson({'SzamErtek': 4, 'ErtekFajta': {'Nev': 'Osztalyzat'}}), (s) => s);
    expect(grade['displayValue'], '4');
    expect(grade['valueKind'], 'grade');
  });
}
