import 'package:flutter/material.dart';
import 'package:pala/models/grade.dart';

import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/theme/app_colors.dart';

/// Certificate Planner ("Bizonyítvány tervező") projection dashboard.
class CertificatePlanner extends StatefulWidget {
  final Map<String, double> subjectAverages;
  final List<Grade> grades;
  final String Function(String) getDisplaySubject;

  const CertificatePlanner({
    super.key,
    required this.subjectAverages,
    required this.grades,
    required this.getDisplaySubject,
  });

  @override
  State<CertificatePlanner> createState() => _CertificatePlannerState();
}

class _CertificatePlannerState extends State<CertificatePlanner> {
  // Hungarian article + allative with vowel harmony ("öt" takes "az").
  static const _toGrade = {2: 'a 2-eshez', 3: 'a 3-ashoz', 4: 'a 4-eshez', 5: 'az 5-öshöz'};

  final Map<String, int> _targetGrades = {};

  int _roundToCertificateGrade(double avg) {
    if (avg <= 0) return 0;
    if (avg < 1.5) return 1;
    if (avg < 2.5) return 2;
    if (avg < 3.5) return 3;
    if (avg < 4.5) return 4;
    return 5;
  }

  double _thresholdForGrade(int grade) {
    switch (grade) {
      case 5:
        return 4.50;
      case 4:
        return 3.50;
      case 2:
        return 1.50;
      case 3:
      default:
        return 2.50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjects = widget.subjectAverages.keys.toList()..sort();

    if (subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nincsenek elérhető tantárgyi átlagok a bizonyítvány tervezéséhez.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculate current and target projected report card GPA
    int currentSum = 0;
    int currentCount = 0;
    int targetSum = 0;

    for (final s in subjects) {
      final avg = widget.subjectAverages[s] ?? 0.0;
      if (avg > 0) {
        final currentRounded = _roundToCertificateGrade(avg);
        final target = _targetGrades[s] ?? currentRounded;
        currentSum += currentRounded;
        targetSum += target;
        currentCount++;
      }
    }

    final currentCertificateGpa = currentCount > 0 ? (currentSum / currentCount) : 0.0;
    final targetCertificateGpa = currentCount > 0 ? (targetSum / currentCount) : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header Summary Card
        Card(
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jelenlegi bizonyítvány átlag',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentCertificateGpa.toStringAsFixed(2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.getGradeColor(currentCertificateGpa),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 44, color: colorScheme.outlineVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cél bizonyítvány átlag',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        targetCertificateGpa.toStringAsFixed(2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.getGradeColor(targetCertificateGpa),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Tantárgyi célok és szükséges jegyek',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Subject list cards
        ...subjects.map((sub) {
          final avg = widget.subjectAverages[sub] ?? 0.0;
          final currentRounded = _roundToCertificateGrade(avg);
          final target = _targetGrades[sub] ?? currentRounded;
          final targetThreshold = _thresholdForGrade(target);
          final diffToThreshold = targetThreshold - avg;

          // Compute weights of current grades for subject
          double subWeight = 0;
          double subSum = 0;
          for (final g in widget.grades) {
            if (widget.getDisplaySubject(g.subject) == sub && g.numericValue != null) {
              final w = g.weight / 100.0;
              subWeight += w;
              subSum += g.numericValue! * w;
            }
          }

          // Calculate how many 5s (100% weight = 1.0) needed to reach targetThreshold
          // (subSum + n * 5) / (subWeight + n) >= targetThreshold
          // subSum + 5n >= targetThreshold * subWeight + targetThreshold * n
          // n * (5 - targetThreshold) >= targetThreshold * subWeight - subSum
          int neededFives = 0;
          if (diffToThreshold > 0 && target > currentRounded) {
            final denom = 5.0 - targetThreshold;
            if (denom > 0) {
              final numerator = (targetThreshold * subWeight) - subSum;
              if (numerator > 0) {
                neededFives = (numerator / denom).ceil();
              }
            }
          }

          return Card(
            color: colorScheme.surfaceContainerLow,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sub,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getGradeColor(avg).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.getGradeColor(avg)),
                        ),
                        child: Text(
                          avg.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.getGradeColor(avg),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target Selector (2..5) with WCAG 2.1 AA touch targets
                  // Label on its own line so the four grade buttons share the full width
                  // instead of wrapping one onto a second row on narrow phones.
                  Text(
                    'Cél jegy:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...[2, 3, 4, 5].map((g) {
                        final isSelected = target == g;
                        final color = AppColors.getGradeColor(g);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: g == 2 ? 0 : 6),
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: '$sub cél jegy: $g',
                              child: ConstrainedBox(
                                constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                                child: InkWell(
                                  onTap: () => setState(() => _targetGrades[sub] = g),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? color : colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? color : colorScheme.outlineVariant,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$g',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? Colors.black : colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Analysis text
                  if (target <= currentRounded)
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'A cél jelenleg biztosított a bizonyítványban.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            neededFives > 0
                                ? '${_toGrade[target]![0].toUpperCase()}${_toGrade[target]!.substring(1)} (${targetThreshold.toStringAsFixed(2)}) legalább $neededFives db 100%-os ötös szükséges.'
                                : 'Még +${diffToThreshold.toStringAsFixed(2)} átlag szükséges ${_toGrade[target]}.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
