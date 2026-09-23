import 'package:pala/api/client.dart';
import 'package:pala/api/demo_data.dart';
import 'package:test/test.dart';

Map<String, dynamic> week(String start, String end, String leiras) => {
      'KezdoNapDatuma': start,
      'VegNapDatuma': end,
      'HetSorszama': 1,
      'Tipus': {'Uid': '1', 'Nev': leiras.replaceAll(' ', '_'), 'Leiras': leiras},
    };

void main() {
  final monday = DateTime(2026, 9, 21);

  group('KretaClient.weekTypeLabel', () {
    test('returns the school\'s name for the week covering the day', () {
      final data = [
        week('2026-09-14T00:00:00', '2026-09-20T00:00:00', 'A hét'),
        week('2026-09-21T00:00:00', '2026-09-27T00:00:00', 'B hét'),
      ];
      expect(KretaClient.weekTypeLabel(data, monday), 'B hét');
    });

    test('keeps custom names such as a C week', () {
      final data = [week('2026-09-21T00:00:00', '2026-09-27T00:00:00', 'C hét')];
      expect(KretaClient.weekTypeLabel(data, monday), 'C hét');
    });

    test('hides the default "Minden héten" (no rotation)', () {
      final data = [week('2026-09-21T00:00:00', '2026-09-27T00:00:00', 'Minden héten')];
      expect(KretaClient.weekTypeLabel(data, monday), isNull);
    });

    test('returns null when no week matches or the shape is unexpected', () {
      expect(KretaClient.weekTypeLabel([week('2026-09-07T00:00:00', '2026-09-13T00:00:00', 'A hét')], monday), isNull);
      expect(KretaClient.weekTypeLabel({'error': true}, monday), isNull);
      expect(KretaClient.weekTypeLabel(null, monday), isNull);
    });
  });

  test('demo week type matches the demo timetable rotation', () {
    expect(DemoData.weekType(monday, true), 'A hét');
    expect(DemoData.weekType(monday, false), 'B hét');
    expect(DemoData.weekType(monday) == 'A hét', DemoData.isDemoAWeek(monday));
  });
}
