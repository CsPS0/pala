import 'package:flutter/material.dart';

/// Absence Progress Gauge (Organism) tracking cumulative missed hours against the 250-hour legal limit.
class AbsenceProgressGauge extends StatelessWidget {
  final int totalMissedHours;
  final int excusedHours;
  final int unexcusedHours;
  final int pendingHours;

  const AbsenceProgressGauge({
    super.key,
    required this.totalMissedHours,
    required this.excusedHours,
    required this.unexcusedHours,
    required this.pendingHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = totalMissedHours;
    final progress = (total / 250.0).clamp(0.0, 1.0);
    final remainingHours = (250 - total).clamp(0, 250);

    // Dynamic threshold styling:
    // Green (primary) < 150h, Amber/Orange (tertiary) 150-200h, Red (error) >= 200h
    final isCritical = total >= 200;
    final isWarning = total >= 150 && total < 200;

    final Color gaugeColor = isCritical
        ? colorScheme.error
        : (isWarning ? colorScheme.tertiary : colorScheme.primary);

    final String statusLabel = isCritical
        ? 'KRITIKUS KÖZELÍTÉS (200+ ÓRA)'
        : (isWarning ? 'FIGYELMEZTETÉS (150+ ÓRA)' : 'BIZTONSÁGOS ZÓNA');

    return Card(
      color: colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gaugeColor.withValues(alpha: isCritical ? 0.8 : 0.4), width: isCritical ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gaugeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: gaugeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: gaugeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  '$total / 250 óra',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Még $remainingHours óra maradt',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A jogszabály szerint 250 igazolt vagy igazolatlan mulasztott óra elérése esetén a tanév végi osztályozó vizsga elrendelhető.',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );

  }
}
