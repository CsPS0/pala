import 'package:flutter/material.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';

enum SearchCategory {
  grade,
  timetable,
  taskOrMessage,
  absence,
}

/// Dynamic search result tile (Molecule) displaying matched academic entities.
class SearchResultTile extends StatelessWidget {
  final SearchCategory category;
  final String title;
  final String subtitle;
  final String? extra;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SearchResultTile({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    this.extra,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color iconColor;

    switch (category) {
      case SearchCategory.grade:
        icon = Icons.grade_rounded;
        iconColor = colorScheme.primary;
        break;
      case SearchCategory.timetable:
        icon = Icons.calendar_today_rounded;
        iconColor = colorScheme.secondary;
        break;
      case SearchCategory.taskOrMessage:
        icon = Icons.assignment_rounded;
        iconColor = colorScheme.tertiary;
        break;
      case SearchCategory.absence:
        icon = Icons.person_off_rounded;
        iconColor = colorScheme.error;
        break;
    }

    return Semantics(
      button: onTap != null,
      label: '$title, $subtitle',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: AdaptiveBreakpoints.minTouchTargetAndroid),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 3),
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (extra != null && extra!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            extra!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
