import 'package:flutter/material.dart';

enum StatusBadgeType {
  info,
  success,
  warning,
  substitution,
  cancellation,
}

/// Compact label indicator for substitutions, cancellations, and status tags.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
    this.icon,
  });

  const StatusBadge.substitution({
    super.key,
    this.label = 'HELYETTESÍTÉS',
    this.icon = Icons.swap_horiz_rounded,
  }) : type = StatusBadgeType.substitution;

  const StatusBadge.cancellation({
    super.key,
    this.label = 'ELMARAD',
    this.icon = Icons.cancel_outlined,
  }) : type = StatusBadgeType.cancellation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (type) {
      case StatusBadgeType.substitution:
        bg = colorScheme.tertiaryContainer;
        fg = colorScheme.onTertiaryContainer;
        break;
      case StatusBadgeType.cancellation:
        bg = colorScheme.errorContainer;
        fg = colorScheme.onErrorContainer;
        break;
      case StatusBadgeType.warning:
        bg = colorScheme.tertiaryContainer;
        fg = colorScheme.onTertiaryContainer;
        break;
      case StatusBadgeType.success:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        break;
      case StatusBadgeType.info:
        bg = colorScheme.surfaceContainerHigh;
        fg = colorScheme.onSurface;
        break;
    }

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
