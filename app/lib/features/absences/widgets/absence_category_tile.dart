import 'package:flutter/material.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';

enum AbsenceCategoryType {
  excused,
  unexcused,
  pending,
}

/// Categorized absence category tile (Molecule) displaying status counts and tones.
class AbsenceCategoryTile extends StatelessWidget {
  final AbsenceCategoryType category;
  final int count;
  final int totalCount;
  final bool isSelected;
  final VoidCallback? onTap;

  const AbsenceCategoryTile({
    super.key,
    required this.category,
    required this.count,
    required this.totalCount,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String label;
    IconData icon;
    Color toneColor;
    Color bgTone;

    switch (category) {
      case AbsenceCategoryType.excused:
        label = 'Igazolt';
        icon = Icons.check_circle_outline_rounded;
        toneColor = colorScheme.primary;
        bgTone = colorScheme.primaryContainer.withValues(alpha: 0.15);
        break;
      case AbsenceCategoryType.unexcused:
        label = 'Igazolatlan';
        icon = Icons.error_outline_rounded;
        toneColor = colorScheme.error;
        bgTone = colorScheme.errorContainer.withValues(alpha: 0.15);
        break;
      case AbsenceCategoryType.pending:
        label = 'Igazolandó';
        icon = Icons.pending_outlined;
        toneColor = colorScheme.tertiary;
        bgTone = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        break;
    }

    final percentage = totalCount > 0 ? (count / totalCount * 100).toStringAsFixed(0) : '0';

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: '$label hiányzás: $count óra, $percentage%',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: AdaptiveBreakpoints.minTouchTargetAndroid),
        child: Card(
          color: isSelected ? bgTone : colorScheme.surfaceContainerLow,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? toneColor : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: toneColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: toneColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$percentage% az összes mulasztásból',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$count óra',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: toneColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
