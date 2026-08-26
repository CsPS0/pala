import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/grade.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'stats_view.dart';

class GradesView extends StatefulWidget {
  final AppModel appModel;

  const GradesView({super.key, required this.appModel});

  @override
  State<GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<GradesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  int? _selectedGradeFilter; // null = all, 1..5

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

  Color _getGradeColor(int? val) {
    switch (val) {
      case 5: return PalaTheme.success;
      case 4: return const Color(0xFFFF8800);
      case 3: return PalaTheme.warning;
      case 2: return const Color(0xFFFF9500);
      case 1: return PalaTheme.danger;
      default: return PalaTheme.textMuted;
    }
  }

  void _openGhostSimulator() {
    final subAvgs = widget.appModel.subjectAverages;
    if (subAvgs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nincsenek tantárgyak a szimulációhoz!')),
      );
      return;
    }

    String selectedSubject = subAvgs.keys.first;
    int simulatedGrade = 5;
    int simulatedWeight = 100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final primary = theme.primaryColor;

            // Recalculate simulation
            double subSum = 0, subWeight = 0;
            double totalSum = 0, totalWeight = 0;

            for (final g in widget.appModel.grades) {
              if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
                final w = g.weight / 100.0;
                totalSum += g.numericValue! * w;
                totalWeight += w;

                final s = widget.appModel.getDisplaySubject(g.subject);
                if (s == selectedSubject) {
                  subSum += g.numericValue! * w;
                  subWeight += w;
                }
              }
            }

            final curSubAvg = subWeight > 0 ? (subSum / subWeight) : 0.0;
            final simW = simulatedWeight / 100.0;
            final newSubAvg = (subWeight + simW) > 0 ? ((subSum + simulatedGrade * simW) / (subWeight + simW)) : simulatedGrade.toDouble();
            final newTotalGpa = (totalWeight + simW) > 0 ? ((totalSum + simulatedGrade * simW) / (totalWeight + simW)) : simulatedGrade.toDouble();

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Szellem Jegy Szimulátor',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nézd meg, hogyan változna a tantárgyi és az összesített átlagod egy új jegy esetén!',
                    style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Subject dropdown
                  const Text('Tantárgy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSubject,
                        isExpanded: true,
                        dropdownColor: PalaTheme.card,
                        items: subAvgs.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedSubject = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Szimulált Jegy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: PalaTheme.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: PalaTheme.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: simulatedGrade,
                                  isExpanded: true,
                                  dropdownColor: PalaTheme.card,
                                  items: [5, 4, 3, 2, 1].map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => simulatedGrade = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Súlyozás (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: PalaTheme.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: PalaTheme.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: simulatedWeight,
                                  isExpanded: true,
                                  dropdownColor: PalaTheme.card,
                                  items: [50, 100, 200].map((w) => DropdownMenuItem(value: w, child: Text('$w%', style: const TextStyle(fontSize: 13)))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => simulatedWeight = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Results Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jelenlegi tantárgyi átlag:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(curSubAvg.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Új tantárgyi átlag:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(newSubAvg.toStringAsFixed(2), style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Új összesített GPA:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(newTotalGpa.toStringAsFixed(2), style: const TextStyle(color: PalaTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Rendben'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final query = _searchController.text.toLowerCase().trim();

    final filteredGrades = widget.appModel.grades.where((g) {
      if (_selectedGradeFilter != null && g.numericValue != _selectedGradeFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final sub = widget.appModel.getDisplaySubject(g.subject).toLowerCase();
        final themeStr = g.theme?.toLowerCase() ?? '';
        final teach = g.teacherName?.toLowerCase() ?? '';
        if (!sub.contains(query) && !themeStr.contains(query) && !teach.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openGhostSimulator,
              backgroundColor: primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Szellem Jegy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            body: Row(
              children: [
                // Left Column: Grades List
                Expanded(
                  flex: 6,
                  child: RefreshIndicator(
                    onRefresh: widget.appModel.refreshAll,
                    color: primary,
                    child: _buildGradesListView(filteredGrades, query, primary),
                  ),
                ),

                const VerticalDivider(width: 1, color: PalaTheme.border),

                // Right Column: Target Average & Stats
                Expanded(
                  flex: 5,
                  child: StatsView(appModel: widget.appModel),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openGhostSimulator,
            backgroundColor: primary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('Szellem Jegy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              color: PalaTheme.sidebar,
              child: TabBar(
                controller: _tabController,
                indicatorColor: primary,
                labelColor: primary,
                unselectedLabelColor: PalaTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Jegyek Listája'),
                  Tab(text: 'Statisztika & Célátlag'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Grade List Tab
              RefreshIndicator(
                onRefresh: widget.appModel.refreshAll,
                color: primary,
                child: _buildGradesListView(filteredGrades, query, primary),
              ),

              // 2. Embedded StatsView Tab
              StatsView(appModel: widget.appModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradesListView(List<Grade> filteredGrades, String query, Color primary) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Keresés tantárgy vagy téma alapján...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Összes'),
                        selected: _selectedGradeFilter == null,
                        onSelected: (_) => setState(() => _selectedGradeFilter = null),
                      ),
                      const SizedBox(width: 6),
                      ...[5, 4, 3, 2, 1].map((val) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('$val-ös'),
                          selected: _selectedGradeFilter == val,
                          selectedColor: _getGradeColor(val).withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _selectedGradeFilter = _selectedGradeFilter == val ? null : val),
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Grades Count / Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredGrades.length} találat',
                      style: const TextStyle(color: PalaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Összesített GPA: ${widget.appModel.overallGpa > 0 ? widget.appModel.overallGpa.toStringAsFixed(2) : "--"}',
                      style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Grades list
                if (filteredGrades.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text('Nincsenek a feltételnek megfelelő jegyek.', style: TextStyle(color: PalaTheme.textMuted)),
                  )
                else
                  ...filteredGrades.map((g) {
                    final gradeColor = _getGradeColor(g.numericValue?.toInt());
                    final valStr = g.numericValue?.toString() ?? g.textValue ?? '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PalaTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PalaTheme.border),
                      ),
                      child: Row(
                        children: [
                          // Big Grade Badge
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: gradeColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: gradeColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              valStr,
                              style: TextStyle(
                                color: gradeColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Grade details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.appModel.getDisplaySubject(g.subject),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${g.weight.toInt()}%',
                                        style: const TextStyle(fontSize: 10, color: PalaTheme.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  g.theme != null && g.theme!.isNotEmpty ? g.theme! : (g.type ?? ''),
                                  style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${g.date != null ? DateFormat('yyyy.MM.dd').format(g.date!) : "-"}${g.teacherName != null ? " • ${g.teacherName}" : ""}',
                                  style: const TextStyle(color: PalaTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 60), // FAB spacing
              ],
            );
  }
}

