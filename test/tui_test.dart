import 'package:pala/api/demo_data.dart';
import 'package:pala/app/theme.dart';
import 'package:pala/app/tui/screen_buffer.dart';
import 'package:pala/app/tui/tui_state.dart';
import 'package:pala/app/tui/tui_views.dart';
import 'package:test/test.dart';

void main() {
  group('TuiScreenBuffer layout & rounded Unicode borders', () {
    test('measures visibleLength and strips ANSI sequences accurately', () {
      const colored = '\x1B[1;38;5;46mMatematika\x1B[0m';
      expect(TuiScreenBuffer.stripAnsi(colored), equals('Matematika'));
      expect(TuiScreenBuffer.visibleLength(colored), equals(10));
    });

    test('truncates and pads ANSI strings to exact visible width', () {
      const colored = '\x1B[1;38;5;208mTörténelem és állampolgári ismeretek\x1B[0m';
      final truncated = TuiScreenBuffer.truncateAnsi(colored, 12);
      expect(TuiScreenBuffer.visibleLength(truncated), equals(12));

      final padded = TuiScreenBuffer.padRightAnsi('\x1B[32m5\x1B[0m', 6);
      expect(TuiScreenBuffer.visibleLength(padded), equals(6));
    });

    test('draws rounded Unicode boxes with exact width and height', () {
      final box = TuiScreenBuffer.drawRoundedBox(
        width: 30,
        height: 5,
        title: 'Teszt Keret',
        rightBadge: '[1/4]',
        lines: [
          'Első sor',
          '__DIVIDER__',
          'Második sor',
        ],
      );

      expect(box.length, equals(5));
      for (final row in box) {
        expect(TuiScreenBuffer.visibleLength(row), equals(30));
      }

      final topClean = TuiScreenBuffer.stripAnsi(box.first);
      final midClean = TuiScreenBuffer.stripAnsi(box[2]);
      final botClean = TuiScreenBuffer.stripAnsi(box.last);

      expect(topClean.startsWith('╭'), isTrue);
      expect(topClean.endsWith('╮'), isTrue);
      expect(midClean.startsWith('├'), isTrue);
      expect(midClean.endsWith('┤'), isTrue);
      expect(botClean.startsWith('╰'), isTrue);
      expect(botClean.endsWith('╯'), isTrue);
    });
  });

  group('PalaTheme Color Psychology', () {
    test('maps grades 5..1 to distinct semantic ANSI 256 colors', () {
      expect(PalaTheme.gradeColor(5), equals(PalaTheme.grade5Fg)); // Bright Green
      expect(PalaTheme.gradeColor(4), equals(PalaTheme.grade4Fg)); // Light Green
      expect(PalaTheme.gradeColor(3), equals(PalaTheme.grade3Fg)); // Yellow
      expect(PalaTheme.gradeColor(2), equals(PalaTheme.grade2Fg)); // Orange
      expect(PalaTheme.gradeColor(1), equals(PalaTheme.grade1Fg)); // Red
    });

    test('maps absences to red (unexcused), yellow (pending), and grey (excused)', () {
      expect(PalaTheme.absenceColor('Igazolatlan'), equals(PalaTheme.absenceUnexcusedFg));
      expect(PalaTheme.absenceColor('Igazolandó'), equals(PalaTheme.absencePendingFg));
      expect(PalaTheme.absenceColor('Igazolt'), equals(PalaTheme.absenceExcusedFg));
      expect(PalaTheme.absenceColor('Igazolt', type: 'Késés'), equals(PalaTheme.absenceDelayFg));
    });
  });

  group('TuiWorkspaceState & TuiViews rendering', () {
    late TuiWorkspaceState state;

    setUp(() {
      state = TuiWorkspaceState()
        ..isDemo = true
        ..student = DemoData.getStudent()
        ..grades = DemoData.getGrades()
        ..averages = DemoData.getAverages()
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        ..groupAverages = DemoData.getGroupAverages()
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        ..absences = DemoData.getAbsences()
        ..exams = DemoData.getExams()
        ..homeworks = DemoData.getHomework()
        ..messages = DemoData.getMessages()
        ..timetable = DemoData.getTimetable(
          start: DateTime(2026, 9, 14),
          end: DateTime(2026, 9, 20),
        )
        ..weekTypeLabel = 'A hét';
    });

    test('renders all 4 tabs and Szellem Jegy bar within exact terminal bounds', () {
      for (var tab = 0; tab < 4; tab++) {
        state.switchTab(tab);
        final frame = TuiViews.buildScreen(state, width: 110, height: 32);
        expect(frame.length, equals(32));
        for (final line in frame) {
          expect(TuiScreenBuffer.visibleLength(line), lessThanOrEqualTo(110));
        }
      }

      // Open Szellem Jegy drawer and add a hypothetical grade
      state.ghostDrawerOpen = true;
      final baseGpa = state.overallGpa(includeGhost: false);
      state.ghostGradeValue = 5;
      state.addCurrentGhostGrade();
      final simGpa = state.overallGpa(includeGhost: true);

      expect(state.ghostGrades.length, equals(1));
      expect(simGpa, greaterThanOrEqualTo(baseGpa));

      final ghostFrame = TuiViews.buildScreen(state, width: 110, height: 32);
      final plainText = ghostFrame.map(TuiScreenBuffer.stripAnsi).join('\n');
      expect(plainText, contains('SZELLEM JEGY KALKULÁTOR'));
      expect(plainText, contains('PALA TUI'));
      expect(plainText, contains('Teszt Elek'));
    });
  });
}
