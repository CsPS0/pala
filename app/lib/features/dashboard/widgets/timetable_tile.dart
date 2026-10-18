import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/timetable_entry.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/widgets/status_badge.dart';

/// Chronological timetable feed item (Molecule) surfacing substitutions and cancellations.
class TimetableTile extends StatelessWidget {
  final TimetableEntry lesson;
  final bool isNow;
  final bool isPast;
  final String Function(String) getDisplaySubject;
  final VoidCallback? onTap;

  const TimetableTile({
    super.key,
    required this.lesson,
    this.isNow = false,
    this.isPast = false,
    required this.getDisplaySubject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCancelled = lesson.isCancelled;
    final hasSubstitute = !isCancelled && (lesson.substituteTeacher != null && lesson.substituteTeacher!.isNotEmpty);

    Color borderColor;
    Color cardBg;

    if (isCancelled) {
      borderColor = colorScheme.errorContainer;
      cardBg = colorScheme.errorContainer.withValues(alpha: 0.12);
    } else if (hasSubstitute) {
      borderColor = colorScheme.tertiaryContainer;
      cardBg = colorScheme.tertiaryContainer.withValues(alpha: 0.12);
    } else if (isNow) {
      borderColor = colorScheme.primary;
      cardBg = colorScheme.primary.withValues(alpha: 0.08);
    } else {
      borderColor = colorScheme.outlineVariant;
      cardBg = colorScheme.surfaceContainerLow;
    }

    final startTimeStr = lesson.startTime != null ? DateFormat('HH:mm').format(lesson.startTime!) : '';
    final endTimeStr = lesson.endTime != null ? DateFormat('HH:mm').format(lesson.endTime!) : '';
    final subjectName = getDisplaySubject(lesson.subject);

    return Semantics(
      button: onTap != null,
      label: '$subjectName óra, ${lesson.lessonNumber}. óra, $startTimeStr - $endTimeStr'
          '${isCancelled ? ', elmarad' : ''}${hasSubstitute ? ', helyettesítés' : ''}',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: AdaptiveBreakpoints.minTouchTargetAndroid),
        child: Opacity(
          opacity: isPast && !isCancelled && !isNow ? 0.6 : 1.0,
          child: Card.outlined(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: isNow ? 2 : 1),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lesson Number Pill
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isNow ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${lesson.lessonNumber}',
                        style: TextStyle(
                          color: isNow ? colorScheme.onPrimary : colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Lesson Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subjectName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                    color: isCancelled
                                        ? colorScheme.error
                                        : (isNow ? colorScheme.primary : colorScheme.onSurface),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCancelled)
                                const StatusBadge.cancellation()
                              else if (hasSubstitute)
                                const StatusBadge.substitution(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (startTimeStr.isNotEmpty && endTimeStr.isNotEmpty) ...[
                                Icon(Icons.access_time_rounded, size: 13, color: colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(
                                  '$startTimeStr - $endTimeStr',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (lesson.room != null && lesson.room!.isNotEmpty) ...[
                                Icon(Icons.room_outlined, size: 13, color: colorScheme.outline),
                                const SizedBox(width: 2),
                                Text(
                                  lesson.room!,
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          if (hasSubstitute && lesson.substituteTeacher != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Helyettesítő tanár: ${lesson.substituteTeacher}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else if (lesson.teacher != null && lesson.teacher!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              lesson.teacher!,
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
