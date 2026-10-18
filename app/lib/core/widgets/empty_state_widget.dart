import 'package:flutter/material.dart';
import '../adaptive/adaptive_breakpoints.dart';

/// Contextual empty, offline, and error state indicator with recovery action triggers.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  const EmptyStateWidget.offline({
    super.key,
    this.icon = Icons.cloud_off_rounded,
    this.title = 'Nincs hálózati kapcsolat',
    this.description = 'Nem sikerült elérni a Kréta szervereit, és nincsenek helyi adatok. Próbáld újra később.',
    this.primaryActionLabel = 'Újrapróbálás',
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  const EmptyStateWidget.noResults({
    super.key,
    this.icon = Icons.search_off_rounded,
    this.title = 'Nincs találat',
    this.description = 'A megadott keresési feltételekkel nem található egyetlen elem sem.',
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (primaryActionLabel != null || secondaryActionLabel != null) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (primaryActionLabel != null && onPrimaryAction != null)
                    ConstrainedBox(
                      constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                      child: FilledButton.tonal(
                        onPressed: onPrimaryAction,
                        child: Text(primaryActionLabel!),
                      ),
                    ),
                  if (secondaryActionLabel != null && onSecondaryAction != null)
                    ConstrainedBox(
                      constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                      child: OutlinedButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryActionLabel!),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
