import 'package:flutter/material.dart';
import 'package:pala/models/grade.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/utils/accent_insensitive_search.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_container.dart';
import '../../../state/app_model.dart';
import '../widgets/certificate_planner.dart';
import '../widgets/ghost_grade_calculator.dart';
import '../widgets/grade_summary_card.dart';

/// Performance tracking, grade analysis, and planning tools view ("Jegyek és Átlagok").
class GradesView extends StatefulWidget {
  final AppModel appModel;

  const GradesView({super.key, required this.appModel});

  @override
  State<GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<GradesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GhostGradeController _ghostController = GhostGradeController();
  int? _selectedGradeFilter; // null = all, 1..5

  // Hungarian vowel harmony: 5-ös, 4-es, 3-as, 2-es, 1-es.
  static const _gradeChipLabels = {5: '5-ös', 4: '4-es', 3: '3-as', 2: '2-es', 1: '1-es'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ghostController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final file = await CsvExporter.exportGradesToFile(widget.appModel.grades);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Jegyek sikeresen exportálva: ${file.path.split(RegExp(r'[\\/]')).last}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            'Nem sikerült a jegyek CSV exportálása.',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isInitialLoading = widget.appModel.isLoading && widget.appModel.grades.isEmpty;
    if (isInitialLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            SkeletonContainer.tile(),
            SizedBox(height: 12),
            SkeletonContainer.card(height: 100),
            SkeletonContainer.card(height: 100),
            SkeletonContainer.card(height: 100),
          ],
        ),
      );
    }

    if (widget.appModel.errorMessage != null &&
        widget.appModel.grades.isEmpty &&
        !widget.appModel.isDemo) {
      return EmptyStateWidget.offline(
        onPrimaryAction: widget.appModel.refreshAll,
      );
    }

    final query = _searchController.text.trim();
    final subjectAverages = widget.appModel.subjectAverages;
    final groupAverages = widget.appModel.groupAveragesMap;

    // Group grades by subject
    final Map<String, List<Grade>> gradesBySubject = {};
    for (final g in widget.appModel.grades) {
      final subjectName = widget.appModel.getDisplaySubject(g.subject);
      // Filter by query
      if (query.isNotEmpty && !AccentInsensitiveSearch.matches(subjectName, query)) {
        continue;
      }
      // Filter by selected numeric grade
      if (_selectedGradeFilter != null && g.numericValue != _selectedGradeFilter) {
        continue;
      }
      gradesBySubject.putIfAbsent(subjectName, () => []).add(g);
    }

    final sortedSubjects = gradesBySubject.keys.toList()..sort();

    return Scaffold(
      // The shell's AppBar already shows the screen title; this bar only carries the tabs and tools.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.outline,
          tabs: const [
            Tab(text: 'Tantárgyak'),
            Tab(text: 'Tervező'),
          ],
        ),
        actions: [
          // Ghost Grade Calculator button
          IconButton.filledTonal(
            tooltip: 'Szellem jegy kalkulátor',
            icon: const Icon(Icons.calculate_outlined, size: 20),
            onPressed: () => GhostGradeCalculator.show(
              context,
              realGrades: widget.appModel.grades,
              subjectAverages: subjectAverages,
              getDisplaySubject: widget.appModel.getDisplaySubject,
              controller: _ghostController,
            ),
          ),
          const SizedBox(width: 6),
          // CSV Export button
          IconButton.filledTonal(
            tooltip: 'CSV táblázat exportálása',
            icon: const Icon(Icons.file_download_outlined, size: 20),
            onPressed: () => _exportCsv(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Subject Cards & Filters (Master-Detail on >= 600dp)
          LayoutBuilder(
            builder: (context, constraints) {
              final isExpanded = AdaptiveBreakpoints.isExpandedConstraints(constraints);

              final subjectFeed = RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: widget.appModel.refreshAll,
                child: ListView(
                  key: const PageStorageKey<String>('grades_subject_list'),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Search bar
                    TextField(
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
                    const SizedBox(height: 10),

                    // Grade Filter Chips (All, 5, 4, 3, 2, 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ConstrainedBox(
                              constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                              child: FilterChip(
                                label: const Text('Mind'),
                                selected: _selectedGradeFilter == null,
                                onSelected: (_) => setState(() => _selectedGradeFilter = null),
                              ),
                            ),
                          ),
                          ...[5, 4, 3, 2, 1].map((val) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ConstrainedBox(
                                constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                                child: FilterChip(
                                  label: Text(_gradeChipLabels[val]!),
                                  selected: _selectedGradeFilter == val,
                                  onSelected: (selected) {
                                    setState(() => _selectedGradeFilter = selected ? val : null);
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Empty state or Subject cards
                    if (sortedSubjects.isEmpty)
                      EmptyStateWidget.noResults(
                        primaryActionLabel: 'Szűrők törlése',
                        onPrimaryAction: () {
                          _searchController.clear();
                          setState(() => _selectedGradeFilter = null);
                        },
                      )
                    else
                      ...sortedSubjects.map((sub) {
                        final grades = gradesBySubject[sub] ?? [];
                        final avg = subjectAverages[sub] ?? 0.0;
                        return GradeSummaryCard(
                          subject: sub,
                          average: avg,
                          classAverage: groupAverages[sub],
                          grades: grades,
                          onGhostGradeTap: () {
                            _ghostController.setSelectedSubject(sub);
                            if (!isExpanded) {
                              GhostGradeCalculator.show(
                                context,
                                realGrades: widget.appModel.grades,
                                subjectAverages: subjectAverages,
                                getDisplaySubject: widget.appModel.getDisplaySubject,
                                controller: _ghostController,
                              );
                            }
                          },
                        );
                      }),
                    const SizedBox(height: 24),
                  ],
                ),
              );

              if (isExpanded) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: subjectFeed),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GhostGradeCalculator(
                          realGrades: widget.appModel.grades,
                          subjectAverages: subjectAverages,
                          getDisplaySubject: widget.appModel.getDisplaySubject,
                          controller: _ghostController,
                          isInlinePanel: true,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return subjectFeed;
            },
          ),

          // Tab 2: Certificate Planner
          CertificatePlanner(
            subjectAverages: subjectAverages,
            grades: widget.appModel.grades,
            getDisplaySubject: widget.appModel.getDisplaySubject,
          ),
        ],
      ),
    );
  }
}
