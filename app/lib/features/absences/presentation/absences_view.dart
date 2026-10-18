import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/absence.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/utils/accent_insensitive_search.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_container.dart';
import '../../../state/app_model.dart';
import '../widgets/absence_category_tile.dart';
import '../widgets/absence_progress_gauge.dart';

/// Attendance tracking and statutory 250-hour limit monitoring view ("Hiányzások").
class AbsencesView extends StatefulWidget {
  final AppModel appModel;

  const AbsencesView({super.key, required this.appModel});

  @override
  State<AbsencesView> createState() => _AbsencesViewState();
}

class _AbsencesViewState extends State<AbsencesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  AbsenceCategoryType? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(Absence a, AbsenceCategoryType? cat) => switch (cat) {
        null => true,
        AbsenceCategoryType.excused => AppModel.isJustified(a),
        AbsenceCategoryType.unexcused => AppModel.isUnjustified(a),
        AbsenceCategoryType.pending => AppModel.isPending(a),
      };


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isInitialLoading = widget.appModel.isLoading && widget.appModel.absences.isEmpty;
    if (isInitialLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            SkeletonContainer.card(height: 180),
            SizedBox(height: 16),
            SkeletonContainer.tile(),
            SkeletonContainer.tile(),
            SkeletonContainer.tile(),
          ],
        ),
      );
    }

    if (widget.appModel.errorMessage != null &&
        widget.appModel.absences.isEmpty &&
        !widget.appModel.isDemo) {
      return EmptyStateWidget.offline(
        onPrimaryAction: widget.appModel.refreshAll,
      );
    }

    final totalMissed = widget.appModel.totalMissedHours;
    final excused = widget.appModel.justifiedHours;
    final unexcused = widget.appModel.unjustifiedHours;
    final pending = widget.appModel.pendingHours;
    final query = _searchController.text.trim();

    // Filter absences
    final filteredAbsences = widget.appModel.absences.where((a) {
      final subjectName = widget.appModel.getDisplaySubject(a.subject);
      if (query.isNotEmpty && !AccentInsensitiveSearch.matches(subjectName, query)) {
        return false;
      }
      return _matchesCategory(a, _selectedCategory);
    }).toList()
      ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

    final absencesBySubject = widget.appModel.absencesBySubject;

    return Scaffold(
      // The shell's AppBar already shows the screen title.
      appBar: TabBar(
        controller: _tabController,
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.outline,
        tabs: const [
          Tab(text: 'Összegzés'),
          Tab(text: 'Tantárgyanként'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 250h Gauge, Categorized Tiles, and Chronological List
          LayoutBuilder(
            builder: (context, constraints) {
              final isExpanded = AdaptiveBreakpoints.isExpandedConstraints(constraints);

              final summaryWidgets = <Widget>[
                // 250-Hour Allowance Progress Gauge (Organism)
                AbsenceProgressGauge(
                  totalMissedHours: totalMissed,
                  excusedHours: excused,
                  unexcusedHours: unexcused,
                  pendingHours: pending,
                ),
                const SizedBox(height: 16),

                // Categorized Absence Breakdown Tiles
                Text(
                  'Kategóriák szerinti bontás',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                AbsenceCategoryTile(
                  category: AbsenceCategoryType.excused,
                  count: excused,
                  totalCount: totalMissed,
                  isSelected: _selectedCategory == AbsenceCategoryType.excused,
                  onTap: () {
                    setState(() {
                      _selectedCategory = _selectedCategory == AbsenceCategoryType.excused
                          ? null
                          : AbsenceCategoryType.excused;
                    });
                  },
                ),
                AbsenceCategoryTile(
                  category: AbsenceCategoryType.unexcused,
                  count: unexcused,
                  totalCount: totalMissed,
                  isSelected: _selectedCategory == AbsenceCategoryType.unexcused,
                  onTap: () {
                    setState(() {
                      _selectedCategory = _selectedCategory == AbsenceCategoryType.unexcused
                          ? null
                          : AbsenceCategoryType.unexcused;
                    });
                  },
                ),
                AbsenceCategoryTile(
                  category: AbsenceCategoryType.pending,
                  count: pending,
                  totalCount: totalMissed,
                  isSelected: _selectedCategory == AbsenceCategoryType.pending,
                  onTap: () {
                    setState(() {
                      _selectedCategory = _selectedCategory == AbsenceCategoryType.pending
                          ? null
                          : AbsenceCategoryType.pending;
                    });
                  },
                ),
              ];

              final listWidgets = <Widget>[
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Keresés tantárgy szerint...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _selectedCategory = null),
                          child: const Text('Szűrő törlése'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Chronological Absence List
                if (filteredAbsences.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Nincs megjeleníthető hiányzás',
                    description:
                        'A megadott szűrési feltételekkel nem található egyetlen mulasztott óra sem.',
                    primaryActionLabel: _selectedCategory != null || query.isNotEmpty
                        ? 'Szűrők visszaállítása'
                        : null,
                    onPrimaryAction: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = null);
                    },
                  )
                else
                  ...filteredAbsences
                      .map((absence) => _buildAbsenceItem(context, theme, colorScheme, absence)),
                const SizedBox(height: 24),
              ];

              if (isExpanded) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: summaryWidgets,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 6,
                      child: RefreshIndicator(
                        color: colorScheme.primary,
                        onRefresh: widget.appModel.refreshAll,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: listWidgets,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: widget.appModel.refreshAll,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    ...summaryWidgets,
                    const SizedBox(height: 20),
                    ...listWidgets,
                  ],
                ),
              );
            },
          ),

          // Tab 2: Subject-by-Subject Breakdown
          RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: widget.appModel.refreshAll,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Card(
                  color: colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A köznevelési törvény szerint ha egy tantárgyból a hiányzásod meghaladja a tanórák 30%-át, a nevelőtestület osztályozó vizsgára kötelezhet.',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (absencesBySubject.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.celebration_outlined,
                    title: 'Egyetlen hiányzásod sincs',
                    description: 'Gratulálunk! Még egyetlen tanítási óráról sem hiányoztál a tanév során.',
                  )
                else
                  ...absencesBySubject.entries.map((entry) {
                    final sub = entry.key;
                    final count = entry.value;

                    return Card(
                      color: colorScheme.surfaceContainerLow,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: count >= 20 ? colorScheme.error : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        title: Text(
                          sub,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '$count mulasztott óra',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceItem(BuildContext context, ThemeData theme, ColorScheme colorScheme, Absence absence) {
    final status = absence.status.toLowerCase();
    Color statusColor;
    if (status.contains('igazolatlan')) {
      statusColor = colorScheme.error;
    } else if (status.contains('igazolt')) {
      statusColor = colorScheme.primary;
    } else {
      statusColor = colorScheme.tertiary;
    }

    final dateStr = absence.date != null ? DateFormat('yyyy.MM.dd').format(absence.date!) : '';
    final delayText = (absence.delayMinutes != null && absence.delayMinutes! > 0)
        ? '${absence.delayMinutes} perc késés'
        : null;

    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appModel.getDisplaySubject(absence.subject),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Wraps so a long status plus the late minutes never overflow a narrow row.
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        absence.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (delayText != null) ...[
                        Text(
                          delayText,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ],
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
      ),
    );
  }
}
