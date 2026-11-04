import 'package:flutter/material.dart';

/// My average next to the class average for every subject and overall
/// (Kréta's OsztalyCsoportAtlag), like the extension's Osztályzatok card.
class ClassComparisonCard extends StatelessWidget {
  final Map<String, double> myAverages;
  final Map<String, double> classAverages;
  final double? myOverall;

  const ClassComparisonCard({super.key, required this.myAverages, required this.classAverages, this.myOverall});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjects = myAverages.keys.toList()..sort((a, b) => myAverages[b]!.compareTo(myAverages[a]!));
    if (subjects.isEmpty) return const SizedBox.shrink();
    final both = subjects.where(classAverages.containsKey).toList();
    final classOverall = both.isEmpty ? null : both.map((s) => classAverages[s]!).reduce((a, b) => a + b) / both.length;
    final delta = (myOverall != null && classOverall != null) ? myOverall! - classOverall : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Átlagom és az osztályátlag', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              classOverall == null
                  ? 'Az iskolád nem teszi közzé az osztályátlagokat a Krétában.'
                  : 'Összesítve: ${myOverall?.toStringAsFixed(2) ?? '-'} vs. ${classOverall.toStringAsFixed(2)}'
                      '${delta != null ? ' (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)})' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final s in subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          _bar(context, myAverages[s]!, colorScheme.primary, 'Saját átlag'),
                          if (classAverages[s] != null) ...[
                            const SizedBox(height: 3),
                            _bar(context, classAverages[s]!, colorScheme.outline, 'Osztályátlag'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, double value, Color color, String label) {
    final fraction = ((value - 1) / 4).clamp(0.0, 1.0);
    return Semantics(
      label: '$label: ${value.toStringAsFixed(2)}',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: color,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(value.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
