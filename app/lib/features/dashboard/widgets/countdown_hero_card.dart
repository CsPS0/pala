import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/timetable_entry.dart';

/// Class Countdown Hero Card (Organism) displaying real-time class progress or break countdown.
class CountdownHeroCard extends StatelessWidget {
  final TimetableEntry? currentLesson;
  final TimetableEntry? nextLesson;
  final List<TimetableEntry> todayLessons;
  final DateTime now;
  final String Function(String) getDisplaySubject;

  const CountdownHeroCard({
    super.key,
    required this.currentLesson,
    required this.nextLesson,
    required this.todayLessons,
    required this.now,
    required this.getDisplaySubject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: 'Aktuális óra és visszaszámláló',
      child: Card.filled(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildContent(context, theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (currentLesson != null && currentLesson!.startTime != null && currentLesson!.endTime != null) {
      final start = currentLesson!.startTime!;
      final end = currentLesson!.endTime!;
      final totalSeconds = end.difference(start).inSeconds;
      final elapsedSeconds = now.difference(start).inSeconds;
      final progress = totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
      final remainingMinutes = end.difference(now).inMinutes + 1;
      final subjectName = getDisplaySubject(currentLesson!.subject);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FOLYAMATBAN LÉVŐ ÓRA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (currentLesson!.room != null && currentLesson!.room!.isNotEmpty) ...[
                Icon(Icons.room_outlined, size: 16, color: colorScheme.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    currentLesson!.room!,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subjectName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (currentLesson!.theme != null && currentLesson!.theme!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              currentLesson!.theme!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Hátra van még: $remainingMinutes perc',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      );
    } else if (nextLesson != null && nextLesson!.startTime != null) {
      final start = nextLesson!.startTime!;
      final minutesUntil = start.difference(now).inMinutes;
      final subjectName = getDisplaySubject(nextLesson!.subject);

      // Compute break progress relative to previous lesson end time (or 15-min window)
      DateTime breakStart = start.subtract(const Duration(minutes: 15));
      for (final l in todayLessons) {
        if (l.endTime != null && l.endTime!.isBefore(start) && l.endTime!.isAfter(breakStart)) {
          breakStart = l.endTime!;
        }
      }
      final totalBreakSeconds = start.difference(breakStart).inSeconds;
      final elapsedBreakSeconds = now.difference(breakStart).inSeconds;
      final breakProgress = totalBreakSeconds > 0
          ? (elapsedBreakSeconds / totalBreakSeconds).clamp(0.0, 1.0)
          : 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SZÜNET - KÖVETKEZŐ ÓRA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (nextLesson!.room != null && nextLesson!.room!.isNotEmpty) ...[
                Icon(Icons.room_outlined, size: 16, color: colorScheme.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    nextLesson!.room!,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subjectName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            minutesUntil <= 0
                ? 'Kezdődik most (${DateFormat('HH:mm').format(start)})'
                : 'Kezdődik $minutesUntil perc múlva (${DateFormat('HH:mm').format(start)})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: breakProgress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
            ),
          ),
        ],
      );
    } else if (todayLessons.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tanítási nap befejezve',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A mai óráid véget értek. Szép estét és jó pihenést!',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ma nincsenek óráid',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mára nincs beütemezett tanítási óra a naptáradban.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      );
    }
  }
}
