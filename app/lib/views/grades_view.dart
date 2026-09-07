import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
  String? _trendSubject; // null = all subjects

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
                      Text(
                        'Szellem Jegy Szimulátor',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nézd meg, hogyan változna a tantárgyi és az összesített átlagod egy új jegy esetén!',
                    style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Subject dropdown
                  Text('Tantárgy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
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
                        items: subAvgs.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13)))).toList(),
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
                            Text('Szimulált Jegy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
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
                                  items: [5, 4, 3, 2, 1].map((n) => DropdownMenuItem(value: n, child: Text('$n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
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
                            Text('Súlyozás (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
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
                                  items: [50, 100, 200].map((w) => DropdownMenuItem(value: w, child: Text('$w%', style: TextStyle(fontSize: 13)))).toList(),
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
                            Text('Jelenlegi tantárgyi átlag:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(curSubAvg.toStringAsFixed(2), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Új tantárgyi átlag:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(newSubAvg.toStringAsFixed(2), style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Új összesített GPA:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                            Text(newTotalGpa.toStringAsFixed(2), style: TextStyle(color: PalaTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Rendben'),
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
              icon: Icon(Icons.calculate_outlined, size: 18),
              label: Text('Szellem Jegy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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

                VerticalDivider(width: 1, color: PalaTheme.border),

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
            icon: Icon(Icons.calculate_outlined, size: 18),
            label: Text('Szellem Jegy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
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
                        label: Text('Összes'),
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

                const SizedBox(height: 14),

                // Grade Trend Chart Section
                _buildGradeTrendCard(primary),

                const SizedBox(height: 16),

                // Grades Count / Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredGrades.length} találat',
                      style: TextStyle(color: PalaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
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
                    child: Text('Nincsenek a feltételnek megfelelő jegyek.', style: TextStyle(color: PalaTheme.textMuted)),
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
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
                                        style: TextStyle(fontSize: 10, color: PalaTheme.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  g.theme != null && g.theme!.isNotEmpty ? g.theme! : (g.type ?? ''),
                                  style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${g.date != null ? DateFormat('yyyy.MM.dd').format(g.date!) : "-"}${g.teacherName != null ? " • ${g.teacherName}" : ""}',
                                  style: TextStyle(color: PalaTheme.textMuted, fontSize: 10),
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

  Widget _buildGradeTrendCard(Color primary) {
    final subAvgs = widget.appModel.subjectAverages;
    final subjects = subAvgs.keys.toList()..sort();

    // Filter points by chosen subject
    final validPoints = <_TrendPoint>[];
    for (final g in widget.appModel.grades) {
      if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final sub = widget.appModel.getDisplaySubject(g.subject);
        if (_trendSubject == null || _trendSubject == sub) {
          validPoints.add(_TrendPoint(
            date: g.date ?? DateTime.now(),
            value: g.numericValue!.toDouble(),
            weight: g.weight,
            subject: sub,
            theme: g.theme,
          ));
        }
      }
    }

    // Sort chronologically ascending
    validPoints.sort((a, b) => a.date.compareTo(b.date));

    // Calculate trend direction
    String trendStatus = 'Stabil';
    Color trendStatusColor = PalaTheme.textMuted;
    IconData trendIcon = Icons.trending_flat;
    double? trendDiff;

    if (validPoints.length >= 3) {
      final splitIndex = (validPoints.length / 2).floor();
      final firstHalf = validPoints.sublist(0, splitIndex);
      final secondHalf = validPoints.sublist(splitIndex);

      final firstAvg = firstHalf.fold(0.0, (sum, p) => sum + p.value) / firstHalf.length;
      final secondAvg = secondHalf.fold(0.0, (sum, p) => sum + p.value) / secondHalf.length;
      trendDiff = secondAvg - firstAvg;

      if (trendDiff >= 0.1) {
        trendStatus = 'Javuló (+${trendDiff.toStringAsFixed(2)})';
        trendStatusColor = PalaTheme.success;
        trendIcon = Icons.trending_up;
      } else if (trendDiff <= -0.1) {
        trendStatus = 'Romló (${trendDiff.toStringAsFixed(2)})';
        trendStatusColor = PalaTheme.danger;
        trendIcon = Icons.trending_down;
      } else {
        trendStatus = 'Stabil (±0.00)';
        trendStatusColor = PalaTheme.textMuted;
        trendIcon = Icons.trending_flat;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Trend Badge, and Subject Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(trendIcon, color: trendStatusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tanulmányi Trend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (validPoints.length >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: trendStatusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: trendStatusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    trendStatus,
                    style: TextStyle(
                      color: trendStatusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Subject selector dropdown
          Row(
            children: [
              Text(
                'Nézet:',
                style: TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: PalaTheme.sidebar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PalaTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _trendSubject,
                      isExpanded: true,
                      dropdownColor: PalaTheme.card,
                      style: TextStyle(fontSize: 12, color: Colors.white),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Összes tantárgy (GPA alakulása)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ...subjects.map((s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s),
                        )),
                      ],
                      onChanged: (val) => setState(() => _trendSubject = val),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CustomPainter Chart Area
          if (validPoints.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'Nincs elég rögzített jegy a trend megjelenítéséhez.',
                style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: _GradeTrendChartPainter(
                  points: validPoints,
                  primary: primary,
                  cardColor: PalaTheme.card,
                  borderColor: PalaTheme.border,
                  textMutedColor: PalaTheme.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final DateTime date;
  final double value;
  final double weight;
  final String subject;
  final String? theme;

  _TrendPoint({
    required this.date,
    required this.value,
    required this.weight,
    required this.subject,
    this.theme,
  });
}

class _GradeTrendChartPainter extends CustomPainter {
  final List<_TrendPoint> points;
  final Color primary;
  final Color cardColor;
  final Color borderColor;
  final Color textMutedColor;

  _GradeTrendChartPainter({
    required this.points,
    required this.primary,
    required this.cardColor,
    required this.borderColor,
    required this.textMutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 28.0;
    const rightPad = 14.0;
    const topPad = 16.0;
    const bottomPad = 22.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;

    if (plotW <= 0 || plotH <= 0) return;

    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: textMutedColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    // 1. Draw 5 Horizontal Grid Lines (Grades 5, 4, 3, 2, 1)
    for (int g = 1; g <= 5; g++) {
      final y = topPad + plotH * (1.0 - (g - 1.0) / 4.0);

      // Grid line
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      // Y-axis label (5.0, 4.0, ...)
      final tp = TextPainter(
        text: TextSpan(text: '$g.0', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    if (points.length == 1) {
      // Single point
      final p = points.first;
      final x = leftPad + plotW / 2;
      final y = topPad + plotH * (1.0 - (p.value - 1.0) / 4.0);

      // Guide line
      final guidePaint = Paint()
        ..color = primary.withValues(alpha: 0.3)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), guidePaint);

      // Point circle
      final dotPaint = Paint()..color = _getPointColor(p.value.toInt());
      canvas.drawCircle(Offset(x, y), 6, dotPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Point text value
      final valTp = TextPainter(
        text: TextSpan(text: '${p.value.toInt()}', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      valTp.paint(canvas, Offset(x - valTp.width / 2, y - valTp.height - 4));
      return;
    }

    // 2. Compute Coordinates
    final coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = leftPad + (i / (points.length - 1)) * plotW;
      final y = topPad + plotH * (1.0 - (p.value - 1.0) / 4.0);
      coords.add(Offset(x, y));
    }

    // 3. Draw Gradient Fill
    final fillPath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 1; i < coords.length; i++) {
      fillPath.lineTo(coords[i].dx, coords[i].dy);
    }
    fillPath.lineTo(coords.last.dx, topPad + plotH);
    fillPath.lineTo(coords.first.dx, topPad + plotH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withValues(alpha: 0.32),
          primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, plotW, plotH))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Polyline
    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 1; i < coords.length; i++) {
      linePath.lineTo(coords[i].dx, coords[i].dy);
    }
    final linePaint = Paint()
      ..color = primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 5. Draw Dots and Value Labels
    for (int i = 0; i < coords.length; i++) {
      final c = coords[i];
      final p = points[i];
      final ptColor = _getPointColor(p.value.toInt());

      // Outer glow/stroke
      canvas.drawCircle(c, 4.5, Paint()..color = cardColor);
      canvas.drawCircle(c, 4.0, Paint()..color = ptColor);
      canvas.drawCircle(c, 4.0, Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);

      // Draw value text if not too crowded
      if (points.length <= 25 || i == 0 || i == coords.length - 1 || i % ((points.length / 10).ceil()) == 0) {
        final valTp = TextPainter(
          text: TextSpan(
            text: '${p.value.toInt()}',
            style: TextStyle(color: ptColor, fontSize: 10, fontWeight: FontWeight.w800),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valTp.paint(canvas, Offset(c.dx - valTp.width / 2, c.dy - valTp.height - 4));
      }
    }

    // 6. X-axis Date Labels (Start, Mid, End)
    if (points.isNotEmpty) {
      final startFmt = DateFormat('MM.dd').format(points.first.date);
      final startTp = TextPainter(
        text: TextSpan(text: startFmt, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      startTp.paint(canvas, Offset(leftPad, size.height - bottomPad + 4));

      if (points.length > 2) {
        final midIdx = points.length ~/ 2;
        final midFmt = DateFormat('MM.dd').format(points[midIdx].date);
        final midTp = TextPainter(
          text: TextSpan(text: midFmt, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        midTp.paint(canvas, Offset(leftPad + plotW / 2 - midTp.width / 2, size.height - bottomPad + 4));
      }

      final endFmt = DateFormat('MM.dd').format(points.last.date);
      final endTp = TextPainter(
        text: TextSpan(text: endFmt, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      endTp.paint(canvas, Offset(size.width - rightPad - endTp.width, size.height - bottomPad + 4));
    }
  }

  Color _getPointColor(int val) {
    switch (val) {
      case 5: return PalaTheme.success;
      case 4: return const Color(0xFF0A84FF);
      case 3: return PalaTheme.warning;
      case 2: return const Color(0xFFFF8800);
      case 1: return PalaTheme.danger;
      default: return primary;
    }
  }

  @override
  bool shouldRepaint(covariant _GradeTrendChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.primary != primary;
  }
}


