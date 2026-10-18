import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/grade.dart';
import '../../../core/theme/app_colors.dart';

/// Hierarchical Grade Summary Card (Organism) displaying subject average, class comparison, and trend.
class GradeSummaryCard extends StatefulWidget {
  final String subject;
  final double average;
  final double? classAverage;
  final List<Grade> grades;
  final VoidCallback? onGhostGradeTap;

  const GradeSummaryCard({
    super.key,
    required this.subject,
    required this.average,
    this.classAverage,
    required this.grades,
    this.onGhostGradeTap,
  });

  @override
  State<GradeSummaryCard> createState() => _GradeSummaryCardState();
}

class _GradeSummaryCardState extends State<GradeSummaryCard> {
  bool _isExpanded = false;

  IconData _getTrendIcon(double diff) {
    if (diff > 0.05) return Icons.trending_up;
    if (diff < -0.05) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getTrendColor(double diff, ColorScheme colorScheme) {
    if (diff > 0.05) return AppColors.success;
    if (diff < -0.05) return colorScheme.error;
    return colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate trend from last 3 grades vs earlier
    double trendDiff = 0.0;
    if (widget.grades.length >= 2) {
      final recent = widget.grades.take(3).toList();
      double recentSum = 0;
      double recentWeight = 0;
      for (final g in recent) {
        if (g.numericValue != null) {
          final w = g.weight / 100.0;
          recentSum += g.numericValue! * w;
          recentWeight += w;
        }
      }
      final recentAvg = recentWeight > 0 ? (recentSum / recentWeight) : widget.average;
      trendDiff = recentAvg - widget.average;
    }

    final trendIcon = _getTrendIcon(trendDiff);
    final trendColor = _getTrendColor(trendDiff, colorScheme);
    final avgColor = AppColors.getGradeColor(widget.average);

    return Semantics(
      container: true,
      label: '${widget.subject}, átlag: ${widget.average.toStringAsFixed(2)}'
          '${widget.classAverage != null ? ', osztályátlag: ${widget.classAverage!.toStringAsFixed(2)}' : ''}',
      child: Card.filled(
        color: colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Average Badge
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: avgColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: avgColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Text(
                        widget.average > 0 ? widget.average.toStringAsFixed(2) : '-',
                        style: TextStyle(
                          color: avgColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Subject info & Class average
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 2,
                            children: [
                              Text(
                                '${widget.grades.length} db érdemjegy',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                              ),
                              if (widget.classAverage != null && widget.classAverage! > 0)
                                Text(
                                  'Osztály: ${widget.classAverage!.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trend indicator & Expand toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: trendDiff > 0.05
                              ? 'Javuló tendencia'
                              : (trendDiff < -0.05 ? 'Romló tendencia' : 'Statisztikai stagnálás'),
                          child: Icon(trendIcon, color: trendColor, size: 24),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: colorScheme.outline,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),

                // Expanded Grade details list
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  ...widget.grades.map((grade) => _buildGradeItem(context, theme, colorScheme, grade)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeItem(BuildContext context, ThemeData theme, ColorScheme colorScheme, Grade grade) {
    final gradeColor = AppColors.getGradeColor(grade.numericValue);
    final dateStr = grade.date != null ? DateFormat('yyyy.MM.dd').format(grade.date!) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              grade.numericValue?.toString() ?? grade.textValue ?? '?',
              style: TextStyle(
                color: gradeColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.theme != null && grade.theme!.isNotEmpty ? grade.theme! : (grade.type ?? 'Értékelés'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${grade.weight.round()}% súly${grade.teacherName != null ? ' • ${grade.teacherName}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ),
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
        ],
      ),
    );
  }
}
