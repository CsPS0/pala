import 'package:flutter/material.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/rules/grade_rules.dart';

/// A subject's running weighted average over time (line, grades as dots)
/// with the class average as a dashed line, like the extension's chart.
class AverageTrendChart extends StatelessWidget {
  final List<Grade> grades;
  final double? classAverage;

  const AverageTrendChart({super.key, required this.grades, this.classAverage});

  @override
  Widget build(BuildContext context) {
    final counted = grades.where(GradeRules.countsForAverage).toList()
      ..sort((a, b) => (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)));
    if (counted.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final running = GradeRules.runningAverages(counted);
    final hasClass = classAverage != null && classAverage! > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Átlag alakulása', style: Theme.of(context).textTheme.labelMedium)),
            _legend(colorScheme.primary, 'Saját', dashed: false),
            if (hasClass) ...[const SizedBox(width: 12), _legend(colorScheme.outline, 'Osztály', dashed: true)],
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Saját átlag${hasClass ? ' és osztályátlag' : ''} az idő függvényében, '
              'jelenleg ${running.last.toStringAsFixed(2)}${hasClass ? ', osztályátlag ${classAverage!.toStringAsFixed(2)}' : ''}',
          child: SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                values: running,
                grades: [for (final g in counted) g.numericValue!.toDouble()],
                classAverage: hasClass ? classAverage : null,
                line: colorScheme.primary,
                grid: colorScheme.outlineVariant,
                classColor: colorScheme.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, {required bool dashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            border: dashed ? Border(top: BorderSide(color: color, width: 2)) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final List<double> grades;
  final double? classAverage;
  final Color line, grid, classColor;

  _TrendPainter({
    required this.values,
    required this.grades,
    required this.classAverage,
    required this.line,
    required this.grid,
    required this.classColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 6.0, padY = 6.0;
    final w = size.width - padX * 2, h = size.height - padY * 2;
    double y(double v) => padY + h * (1 - (v - 1) / 4);
    double x(int i) => values.length == 1 ? size.width / 2 : padX + w * i / (values.length - 1);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [1.0, 3.0, 5.0]) {
      canvas.drawLine(Offset(padX, y(v)), Offset(size.width - padX, y(v)), gridPaint);
    }

    final avg = classAverage;
    if (avg != null) {
      final dash = Paint()
        ..color = classColor
        ..strokeWidth = 1.5;
      for (var dx = padX; dx < size.width - padX; dx += 7) {
        canvas.drawLine(Offset(dx, y(avg)), Offset((dx + 4).clamp(0, size.width - padX), y(avg)), dash);
      }
    }

    if (values.length > 1) {
      final path = Path()..moveTo(x(0), y(values[0]));
      for (var i = 1; i < values.length; i++) {
        path.lineTo(x(i), y(values[i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final dot = Paint()..color = line;
    for (var i = 0; i < grades.length; i++) {
      canvas.drawCircle(Offset(x(i), y(grades[i])), 2.6, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.classAverage != classAverage || old.line != line;
}
